package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/internal/service"
	"github.com/mishi-app/backend/pkg/response"
)

const AuthUserIDKey = "auth_user_id"

func AuthRequired(jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		if jwtSvc == nil {
			response.InternalServerError(c)
			c.Abort()
			return
		}

		header := c.GetHeader("Authorization")
		token, err := service.ParseBearerToken(header)
		if err != nil {
			response.Unauthorized(c)
			c.Abort()
			return
		}

		userID, err := jwtSvc.ParseToken(strings.TrimSpace(token), service.TokenTypeAccess)
		if err != nil {
			response.Unauthorized(c)
			c.Abort()
			return
		}

		c.Set(AuthUserIDKey, userID)
		c.Next()
	}
}
