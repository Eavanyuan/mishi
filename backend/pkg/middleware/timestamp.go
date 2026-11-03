package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
)

// Timestamp 时间戳中间件
func Timestamp() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 设置请求开始时间
		c.Set("request_start_time", time.Now())
		
		// 设置当前时间戳
		c.Set("timestamp", time.Now().Unix())
		
		c.Next()
	}
}