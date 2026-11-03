package handler

import (
	"database/sql"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/model"
	"github.com/mishi-app/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

// GetProfile 获取用户资料
func GetProfile(db *database.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, err := strconv.ParseInt(c.Param("id"), 10, 64)
		if err != nil || userID <= 0 {
			response.BadRequest(c, "参数错误: id 非法")
			return
		}
		authUserID, ok := getAuthUserID(c)
		if !ok {
			response.Unauthorized(c)
			return
		}
		if userID != authUserID {
			response.Forbidden(c)
			return
		}

		if db == nil || db.Pool == nil {
			response.ServiceUnavailable(c)
			return
		}

		const q = `
SELECT id, nickname, avatar_url, user_type, checkin_count, poem_view_count, audio_play_count, status
FROM users
WHERE id = $1 AND status = 1
LIMIT 1`

		var (
			profile model.UserProfile
			avatar  sql.NullString
		)
		err = db.Pool.QueryRow(c.Request.Context(), q, userID).Scan(
			&profile.ID,
			&profile.Nickname,
			&avatar,
			&profile.UserType,
			&profile.CheckinCount,
			&profile.PoemViewCount,
			&profile.AudioPlayCount,
			&profile.Status,
		)
		if avatar.Valid {
			profile.AvatarURL = avatar.String
		}
		if err != nil {
			log.Warn().Err(err).Int64("user_id", userID).Msg("profile not found")
			response.NotFound(c)
			return
		}

		response.Success(c, gin.H{
			"user": profile,
		})
	}
}
