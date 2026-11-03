package handler

import (
	"encoding/json"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

// GeoNearby 查询附近POI
func GeoNearby(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		lat, lon, err := parseLatLon(c)
		if err != nil {
			response.BadRequest(c, "参数错误: lat/lon 必填且格式正确")
			return
		}
		limit, offset := parsePagination(c, 10, 100)

		radius := 5000
		if raw := c.Query("radius"); raw != "" {
			if v, parseErr := strconv.Atoi(raw); parseErr == nil && v > 0 {
				radius = v
			}
		}

		const q = `
SELECT id, name, ancient_name, modern_name, ST_Y(location) AS lat, ST_X(location) AS lon,
       category, description, poems_count,
       ROUND(ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($2, $1), 4326)))::int AS distance
FROM pois
WHERE status = 1
  AND ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
ORDER BY distance ASC, id ASC
LIMIT $4 OFFSET $5`

		rows, err := db.Pool.Query(c.Request.Context(), q, lat, lon, radius, limit, offset)
		if err != nil {
			log.Error().Err(err).Msg("geo nearby query failed")
			response.InternalServerError(c)
			return
		}
		defer rows.Close()

		pois := make([]gin.H, 0, limit)
		for rows.Next() {
			var (
				id, poemsCount int64
				name, category string
				ancientName    *string
				modernName     *string
				description    *string
				poiLat, poiLon float64
				distance       int
			)
			if scanErr := rows.Scan(&id, &name, &ancientName, &modernName, &poiLat, &poiLon, &category, &description, &poemsCount, &distance); scanErr != nil {
				log.Error().Err(scanErr).Msg("geo nearby scan failed")
				response.InternalServerError(c)
				return
			}
			pois = append(pois, gin.H{
				"poi_id":       id,
				"name":         name,
				"ancient_name": stringValue(ancientName),
				"modern_name":  stringValue(modernName),
				"location": gin.H{
					"lat": poiLat,
					"lon": poiLon,
				},
				"distance":    distance,
				"category":    category,
				"description": stringValue(description),
				"poems_count": poemsCount,
			})
		}
		if err = rows.Err(); err != nil {
			log.Error().Err(err).Msg("geo nearby rows err")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"pois":  pois,
			"total": len(pois),
		})
	}
}

func stringValue(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

func toStringSlice(raw []byte) []string {
	if len(raw) == 0 {
		return nil
	}

	// Format A: ["line1","line2"]
	var plain []string
	if err := json.Unmarshal(raw, &plain); err == nil && len(plain) > 0 {
		return plain
	}

	// Format B: [{"text":"line1"},{"text":"line2"}]
	var objects []map[string]any
	if err := json.Unmarshal(raw, &objects); err == nil && len(objects) > 0 {
		out := make([]string, 0, len(objects))
		for _, item := range objects {
			if text, ok := item["text"].(string); ok && text != "" {
				out = append(out, text)
			}
		}
		if len(out) > 0 {
			return out
		}
	}

	// Format C: {"text":"..."} (defensive fallback)
	var single map[string]any
	if err := json.Unmarshal(raw, &single); err == nil {
		if text, ok := single["text"].(string); ok && text != "" {
			return []string{text}
		}
	}

	return nil
}
