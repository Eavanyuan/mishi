package handler

import (
	"fmt"
	"strconv"

	"github.com/gin-gonic/gin"
)

func parseLatLon(c *gin.Context) (float64, float64, error) {
	latRaw := c.Query("lat")
	if latRaw == "" {
		latRaw = c.Query("latitude")
	}
	lonRaw := c.Query("lon")
	if lonRaw == "" {
		lonRaw = c.Query("longitude")
	}

	if latRaw == "" || lonRaw == "" {
		return 0, 0, fmt.Errorf("missing lat/lon")
	}

	lat, err := strconv.ParseFloat(latRaw, 64)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid lat: %w", err)
	}
	lon, err := strconv.ParseFloat(lonRaw, 64)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid lon: %w", err)
	}

	return lat, lon, nil
}

func parsePagination(c *gin.Context, defaultLimit, maxLimit int) (int, int) {
	limit := defaultLimit
	if raw := c.Query("limit"); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 {
			if v > maxLimit {
				limit = maxLimit
			} else {
				limit = v
			}
		}
	}

	offset := 0
	if raw := c.Query("offset"); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}

	return limit, offset
}
