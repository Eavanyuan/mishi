package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/pkg/middleware"
)

func getAuthUserID(c *gin.Context) (int64, bool) {
	raw, ok := c.Get(middleware.AuthUserIDKey)
	if !ok {
		return 0, false
	}
	userID, ok := raw.(int64)
	if !ok || userID <= 0 {
		return 0, false
	}
	return userID, true
}
