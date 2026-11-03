package handler

import (
	"context"
	"net/http"
	"reflect"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type dbHealthChecker interface {
	HealthCheck(ctx context.Context) error
}

type redisHealthChecker interface {
	HealthCheck(ctx context.Context) error
}

// HealthCheck 健康检查端点
func HealthCheck(db dbHealthChecker, redis redisHealthChecker) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		ctx := c.Request.Context()

		// 检查数据库连接
		var dbStatus string
		var dbError error
		var redisStatus string
		var redisError error

		// 检查数据库
		if !isNilChecker(db) {
			dbError = db.HealthCheck(ctx)
			if dbError != nil {
				dbStatus = "unhealthy"
				log.Error().Err(dbError).Msg("Database health check failed")
			} else {
				dbStatus = "healthy"
			}
		} else {
			dbStatus = "not_initialized"
		}

		// 检查Redis
		if !isNilChecker(redis) {
			redisError = redis.HealthCheck(ctx)
			if redisError != nil {
				redisStatus = "unhealthy"
				log.Error().Err(redisError).Msg("Redis health check failed")
			} else {
				redisStatus = "healthy"
			}
		} else {
			redisStatus = "not_initialized"
		}

		// 构建响应
		statusCode := http.StatusOK
		overallStatus := "healthy"

		if dbError != nil || redisError != nil {
			statusCode = http.StatusServiceUnavailable
			overallStatus = "unhealthy"
		}

		response := gin.H{
			"code":    0,
			"message": "success",
			"data": gin.H{
				"status":    overallStatus,
				"timestamp": time.Now().Unix(),
				"services": gin.H{
					"database": gin.H{
						"status": dbStatus,
						"error":  dbErrorMsg(dbError),
					},
					"redis": gin.H{
						"status": redisStatus,
						"error":  dbErrorMsg(redisError),
					},
				},
				"uptime": time.Since(start).String(),
			},
			"timestamp": time.Now().Unix(),
		}

		c.JSON(statusCode, response)
	}
}

// dbErrorMsg 提取数据库错误信息
func dbErrorMsg(err error) string {
	if err != nil {
		return err.Error()
	}
	return ""
}

func isNilChecker(v interface{}) bool {
	if v == nil {
		return true
	}
	rv := reflect.ValueOf(v)
	switch rv.Kind() {
	case reflect.Ptr, reflect.Map, reflect.Slice, reflect.Interface, reflect.Func:
		return rv.IsNil()
	default:
		return false
	}
}

// Ping 简单ping端点
func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":      0,
		"message":   "pong",
		"data":      nil,
		"timestamp": time.Now().Unix(),
	})
}
