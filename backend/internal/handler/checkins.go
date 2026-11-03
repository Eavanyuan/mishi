package handler

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

type createCheckinRequest struct {
	POIID       int64                  `json:"poi_id" binding:"required"`
	PoemID      int64                  `json:"poem_id" binding:"required"`
	Lat         *float64               `json:"lat"`
	Lon         *float64               `json:"lon"`
	Latitude    *float64               `json:"latitude"`
	Longitude   *float64               `json:"longitude"`
	GPSAccuracy *float64               `json:"gps_accuracy"`
	DeviceInfo  map[string]interface{} `json:"device_info"`
}

// CreateCheckin 提交打卡
func CreateCheckin(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req createCheckinRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误")
			return
		}

		lat, lon, err := resolveBodyLatLon(req)
		if err != nil {
			response.BadRequest(c, "参数错误: lat/lon 必填")
			return
		}

		if req.GPSAccuracy != nil && *req.GPSAccuracy > 50 {
			response.Error(c, 40302, "定位精度不足")
			return
		}

		const poiQ = `
SELECT name, ROUND(ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($2, $1), 4326)))::int
FROM pois
WHERE id = $3 AND status = 1`

		var (
			poiName  string
			distance int
		)
		if err = db.Pool.QueryRow(c.Request.Context(), poiQ, lat, lon, req.POIID).Scan(&poiName, &distance); err != nil {
			response.NotFound(c)
			return
		}

		if distance > 100 {
			response.Error(c, 40301, "距离过远")
			return
		}

		userID, ok := getAuthUserID(c)
		if !ok {
			response.Unauthorized(c)
			return
		}

		const poemQ = `SELECT title FROM poems WHERE id = $1 LIMIT 1`
		poemTitle := ""
		_ = db.Pool.QueryRow(c.Request.Context(), poemQ, req.PoemID).Scan(&poemTitle)

		const insertQ = `
INSERT INTO checkins (user_id, poi_id, poem_id, location, gps_accuracy, distance, device_info, ip_address, checkin_time)
VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($5, $4), 4326), $6, $7, $8, $9, NOW())
RETURNING id, checkin_time, card_url`

		var (
			checkinID   int64
			checkinTime time.Time
			cardURL     *string
		)

		deviceInfo := req.DeviceInfo
		if deviceInfo == nil {
			deviceInfo = map[string]interface{}{}
		}
		deviceInfoJSON, _ := json.Marshal(deviceInfo)

		tx, txErr := db.Pool.Begin(c.Request.Context())
		if txErr != nil {
			log.Error().Err(txErr).Msg("begin create checkin tx failed")
			response.InternalServerError(c)
			return
		}
		defer func() {
			_ = tx.Rollback(c.Request.Context())
		}()

		err = tx.QueryRow(
			c.Request.Context(),
			insertQ,
			userID,
			req.POIID,
			req.PoemID,
			lat,
			lon,
			req.GPSAccuracy,
			distance,
			deviceInfoJSON,
			c.ClientIP(),
		).Scan(&checkinID, &checkinTime, &cardURL)
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" {
				response.Error(c, 40303, "重复打卡")
				return
			}
			log.Error().Err(err).Msg("create checkin failed")
			response.InternalServerError(c)
			return
		}

		if _, err = tx.Exec(
			c.Request.Context(),
			`UPDATE users SET checkin_count = checkin_count + 1, updated_at = NOW() WHERE id = $1`,
			userID,
		); err != nil {
			log.Error().Err(err).Int64("user_id", userID).Msg("update user checkin_count failed")
			response.InternalServerError(c)
			return
		}

		if err = tx.Commit(c.Request.Context()); err != nil {
			log.Error().Err(err).Msg("commit create checkin tx failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"checkin_id":     checkinID,
			"poi_name":       poiName,
			"poem_title":     poemTitle,
			"checkin_time":   checkinTime.Format(time.RFC3339),
			"badge_unlocked": nil,
			"card_url":       stringValue(cardURL),
		})
	}
}

// GetCheckinHistory 查询打卡历史
func GetCheckinHistory(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, ok := getAuthUserID(c)
		if !ok {
			response.Unauthorized(c)
			return
		}
		limit, offset := parsePagination(c, 20, 100)

		const listQ = `
SELECT c.id, poi.name, p.title, c.checkin_time, ST_Y(c.location) AS lat, ST_X(c.location) AS lon, c.card_url
FROM checkins c
JOIN pois poi ON poi.id = c.poi_id
JOIN poems p ON p.id = c.poem_id
WHERE c.user_id = $1
ORDER BY c.checkin_time DESC
LIMIT $2 OFFSET $3`

		rows, err := db.Pool.Query(c.Request.Context(), listQ, userID, limit, offset)
		if err != nil {
			log.Error().Err(err).Msg("query checkin history failed")
			response.InternalServerError(c)
			return
		}
		defer rows.Close()

		checkins := make([]gin.H, 0, limit)
		for rows.Next() {
			var (
				checkinID   int64
				poiName     string
				poemTitle   string
				checkinTime time.Time
				lat, lon    float64
				cardURL     *string
			)
			if scanErr := rows.Scan(&checkinID, &poiName, &poemTitle, &checkinTime, &lat, &lon, &cardURL); scanErr != nil {
				log.Error().Err(scanErr).Msg("scan checkin history failed")
				response.InternalServerError(c)
				return
			}
			checkins = append(checkins, gin.H{
				"checkin_id":   checkinID,
				"poi_name":     poiName,
				"poem_title":   poemTitle,
				"checkin_time": checkinTime.Format(time.RFC3339),
				"location": gin.H{
					"lat": lat,
					"lon": lon,
				},
				"card_url": stringValue(cardURL),
			})
		}

		const statsQ = `
SELECT COUNT(*), COUNT(DISTINCT c.poi_id), COUNT(DISTINCT poi.city_code)
FROM checkins c
JOIN pois poi ON poi.id = c.poi_id
WHERE c.user_id = $1`
		var totalCheckins, totalPOIs, totalCities int64
		if err = db.Pool.QueryRow(c.Request.Context(), statsQ, userID).Scan(&totalCheckins, &totalPOIs, &totalCities); err != nil {
			log.Error().Err(err).Msg("query checkin stats failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"checkins": checkins,
			"total":    totalCheckins,
			"stats": gin.H{
				"total_checkins": totalCheckins,
				"total_pois":     totalPOIs,
				"total_cities":   totalCities,
			},
		})
	}
}

func resolveBodyLatLon(req createCheckinRequest) (float64, float64, error) {
	lat := req.Lat
	if lat == nil {
		lat = req.Latitude
	}
	lon := req.Lon
	if lon == nil {
		lon = req.Longitude
	}
	if lat == nil || lon == nil {
		return 0, 0, errors.New("missing lat lon")
	}
	return *lat, *lon, nil
}
