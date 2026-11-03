package middleware

import (
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

// Recovery 恢复中间件，捕获panic
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// 记录错误日志
				log.Error().
					Str("panic", "recovered").
					Interface("error", err).
					Str("stack", string(debug.Stack())).
					Str("path", c.Request.URL.Path).
					Str("method", c.Request.Method).
					Str("ip", c.ClientIP()).
					Msg("Panic recovered")

				// 返回500错误
				c.JSON(http.StatusInternalServerError, gin.H{
					"code":      50001,
					"message":   "Internal server error",
					"error_detail": gin.H{
						"type": "panic",
						"message": "服务器内部错误，请稍后重试",
					},
					"timestamp": c.GetInt64("timestamp"),
				})

				c.Abort()
			}
		}()

		c.Next()
	}
}