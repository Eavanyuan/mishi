package handler

import (
	"encoding/json"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

// GetPoem 获取诗词详情
func GetPoem(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		poemID, err := strconv.ParseInt(c.Param("id"), 10, 64)
		if err != nil || poemID <= 0 {
			response.BadRequest(c, "参数错误: poem_id 非法")
			return
		}

		const q = `
SELECT id, title, author, dynasty, content, tags, best_seasons, solar_terms, time_period_tags,
       interpretation_basic, interpretation_textbook, interpretation_textbook_source,
       interpretation_academic, interpretation_academic_source, has_audio, audio_duration, has_video,
       view_count, like_count, checkin_count
FROM poems
WHERE id = $1 AND status = 'published'
LIMIT 1`

		var (
			id             int64
			title          string
			author         string
			dynasty        string
			contentRaw     []byte
			tagsRaw        []byte
			seasonsRaw     []byte
			solarTermsRaw  []byte
			timeTagsRaw    []byte
			basic          *string
			textbook       *string
			textbookSource *string
			academic       *string
			academicSource *string
			hasAudio       bool
			audioDuration  *int
			hasVideo       bool
			viewCount      int64
			likeCount      int64
			checkinCount   int64
		)

		err = db.Pool.QueryRow(c.Request.Context(), q, poemID).Scan(
			&id, &title, &author, &dynasty, &contentRaw, &tagsRaw, &seasonsRaw, &solarTermsRaw, &timeTagsRaw,
			&basic, &textbook, &textbookSource, &academic, &academicSource, &hasAudio, &audioDuration, &hasVideo,
			&viewCount, &likeCount, &checkinCount,
		)
		if err != nil {
			response.NotFound(c)
			return
		}

		const relatedQ = `
SELECT poi.id, poi.name, pp.relevance_score
FROM poi_poems pp
JOIN pois poi ON poi.id = pp.poi_id
WHERE pp.poem_id = $1 AND poi.status = 1
ORDER BY pp.relevance_score DESC
LIMIT 5`

		relatedRows, err := db.Pool.Query(c.Request.Context(), relatedQ, poemID)
		if err != nil {
			log.Error().Err(err).Msg("query related pois failed")
			response.InternalServerError(c)
			return
		}
		defer relatedRows.Close()

		relatedPOIs := make([]gin.H, 0)
		for relatedRows.Next() {
			var (
				poiID int64
				name  string
				score float64
			)
			if scanErr := relatedRows.Scan(&poiID, &name, &score); scanErr != nil {
				log.Error().Err(scanErr).Msg("scan related pois failed")
				response.InternalServerError(c)
				return
			}
			relatedPOIs = append(relatedPOIs, gin.H{
				"poi_id":          poiID,
				"name":            name,
				"relevance_score": score,
			})
		}

		content := toStringSlice(contentRaw)
		previewLine := ""
		if len(content) > 0 {
			previewLine = content[0]
		}

		response.Success(c, gin.H{
			"poem_id":          id,
			"title":            title,
			"author":           author,
			"dynasty":          dynasty,
			"content":          content,
			"preview_line":     previewLine,
			"tags":             toStringSlice(tagsRaw),
			"best_seasons":     toStringSlice(seasonsRaw),
			"solar_terms":      toStringSlice(solarTermsRaw),
			"time_period_tags": toStringSlice(timeTagsRaw),
			"interpretations": gin.H{
				"textbook": gin.H{
					"source":  stringValue(textbookSource),
					"content": stringValue(textbook),
				},
				"academic": gin.H{
					"source":  stringValue(academicSource),
					"content": stringValue(academic),
				},
				"basic": gin.H{
					"source":  "system",
					"content": stringValue(basic),
				},
			},
			"related_pois": relatedPOIs,
			"media": gin.H{
				"has_audio": hasAudio,
				"audio_duration": func() int {
					if audioDuration == nil {
						return 0
					}
					return *audioDuration
				}(),
				"has_video": hasVideo,
			},
			"stats": gin.H{
				"view_count":    viewCount,
				"like_count":    likeCount,
				"checkin_count": checkinCount,
			},
		})
	}
}

// RecommendPoems 推荐诗词
func RecommendPoems(db *database.DB) gin.HandlerFunc {
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
		season := c.Query("season")
		if season == "" {
			season = currentSeason(time.Now())
		}

		const q = `
SELECT p.id, p.title, p.author, p.dynasty, p.content,
       pp.poi_id, poi.name,
       ROUND(ST_DistanceSphere(poi.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)))::int AS distance,
       pp.relevance_score,
       p.solar_terms
FROM poi_poems pp
JOIN poems p ON p.id = pp.poem_id
JOIN pois poi ON poi.id = pp.poi_id
WHERE p.status = 'published'
  AND poi.status = 1
  AND ST_DWithin(poi.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
  AND ($6 = '' OR p.best_seasons ? $6)
ORDER BY distance ASC, pp.relevance_score DESC
LIMIT $4 OFFSET $5`

		rows, err := db.Pool.Query(c.Request.Context(), q, lat, lon, radius, limit, offset, season)
		if err != nil {
			log.Error().Err(err).Msg("recommend query failed")
			response.InternalServerError(c)
			return
		}
		defer rows.Close()

		poems := make([]gin.H, 0, limit)
		for rows.Next() {
			var (
				poemID     int64
				title      string
				author     string
				dynasty    string
				contentRaw []byte
				poiID      int64
				poiName    string
				distance   int
				relevance  float64
				solarRaw   []byte
			)
			if scanErr := rows.Scan(&poemID, &title, &author, &dynasty, &contentRaw, &poiID, &poiName, &distance, &relevance, &solarRaw); scanErr != nil {
				log.Error().Err(scanErr).Msg("recommend scan failed")
				response.InternalServerError(c)
				return
			}

			content := toStringSlice(contentRaw)
			solarTerms := toStringSlice(solarRaw)
			solarTerm := ""
			if len(solarTerms) > 0 {
				solarTerm = solarTerms[0]
			}
			previewLine := ""
			if len(content) > 0 {
				previewLine = content[0]
			}

			distanceScore := 1 - (float64(distance) / float64(radius))
			if distanceScore < 0 {
				distanceScore = 0
			}
			score := distanceScore*0.4 + relevance*0.4 + 0.2
			if score > 1 {
				score = 1
			}

			poems = append(poems, gin.H{
				"poem_id":      poemID,
				"title":        title,
				"author":       author,
				"dynasty":      dynasty,
				"content":      content,
				"preview_line": previewLine,
				"distance":     distance,
				"season_tag":   season,
				"solar_term":   solarTerm,
				"score":        score,
				"score_breakdown": gin.H{
					"distance":    distanceScore * 0.4,
					"popularity":  relevance * 0.4,
					"season":      0.2,
					"time_period": 0.0,
				},
				"related_poi": gin.H{
					"poi_id":   poiID,
					"name":     poiName,
					"distance": distance,
				},
			})
		}
		if err = rows.Err(); err != nil {
			log.Error().Err(err).Msg("recommend rows err")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"poems":              poems,
			"current_season":     season,
			"current_solar_term": "",
			"current_hour":       time.Now().Hour(),
		})
	}
}

// SearchPoems 按关键词搜索诗词
func SearchPoems(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		keyword := c.Query("q")
		limit, offset := parsePagination(c, 20, 100)

		const listQ = `
SELECT id, title, author, dynasty, content
FROM poems
WHERE status = 'published'
  AND (
    $1 = '' OR
    title ILIKE '%' || $1 || '%' OR
    author ILIKE '%' || $1 || '%' OR
    content_text ILIKE '%' || $1 || '%'
  )
ORDER BY id DESC
LIMIT $2 OFFSET $3`

		rows, err := db.Pool.Query(c.Request.Context(), listQ, keyword, limit, offset)
		if err != nil {
			log.Error().Err(err).Msg("search poems query failed")
			response.InternalServerError(c)
			return
		}
		defer rows.Close()

		poems := make([]gin.H, 0, limit)
		for rows.Next() {
			var (
				poemID     int64
				title      string
				author     string
				dynasty    string
				contentRaw []byte
			)
			if scanErr := rows.Scan(&poemID, &title, &author, &dynasty, &contentRaw); scanErr != nil {
				log.Error().Err(scanErr).Msg("search poems scan failed")
				response.InternalServerError(c)
				return
			}

			content := toStringSlice(contentRaw)
			previewLine := ""
			if len(content) > 0 {
				previewLine = content[0]
			}

			poems = append(poems, gin.H{
				"poem_id":      poemID,
				"title":        title,
				"author":       author,
				"dynasty":      dynasty,
				"content":      content,
				"preview_line": previewLine,
			})
		}
		if err = rows.Err(); err != nil {
			log.Error().Err(err).Msg("search poems rows err")
			response.InternalServerError(c)
			return
		}

		const countQ = `
SELECT COUNT(*)
FROM poems
WHERE status = 'published'
  AND (
    $1 = '' OR
    title ILIKE '%' || $1 || '%' OR
    author ILIKE '%' || $1 || '%' OR
    content_text ILIKE '%' || $1 || '%'
  )`
		var total int64
		if countErr := db.Pool.QueryRow(c.Request.Context(), countQ, keyword).Scan(&total); countErr != nil {
			log.Error().Err(countErr).Msg("search poems count failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"poems":    poems,
			"total":    total,
			"limit":    limit,
			"offset":   offset,
			"has_more": int64(offset+limit) < total,
			"keyword":  keyword,
			"returned": len(poems),
		})
	}
}

func currentSeason(t time.Time) string {
	switch t.Month() {
	case time.March, time.April, time.May:
		return "春"
	case time.June, time.July, time.August:
		return "夏"
	case time.September, time.October, time.November:
		return "秋"
	default:
		return "冬"
	}
}

func decodeStringArray(raw []byte) []string {
	if len(raw) == 0 {
		return nil
	}
	var values []string
	if err := json.Unmarshal(raw, &values); err != nil {
		return nil
	}
	return values
}
