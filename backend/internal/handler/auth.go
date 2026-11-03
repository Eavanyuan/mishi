package handler

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/mishi-app/backend/internal/cache"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/model"
	"github.com/mishi-app/backend/internal/service"
	"github.com/mishi-app/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

const (
	smsDevCode          = "123456"
	smsCodeTTL          = 5 * time.Minute
	smsCooldownTTL      = time.Minute
	smsMaxVerifyFailure = 5
)

var cnPhonePattern = regexp.MustCompile(`^1[3-9]\d{9}$`)

// Register 用户注册
func Register(db *database.DB, jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.RegisterRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: email/password/username 不合法")
			return
		}

		const insertQ = `
INSERT INTO users (email, nickname, user_type, status, password_hash)
VALUES ($1, $2, 'normal', 1, $3)
RETURNING id, email, nickname, avatar_url, user_type, checkin_count, poem_view_count, audio_play_count, status`

		var (
			user   model.User
			avatar sql.NullString
		)
		err := db.Pool.QueryRow(c.Request.Context(), insertQ, req.Email, req.Username, req.Password).Scan(
			&user.ID,
			&user.Email,
			&user.Nickname,
			&avatar,
			&user.UserType,
			&user.CheckinCount,
			&user.PoemViewCount,
			&user.AudioPlayCount,
			&user.Status,
		)
		if avatar.Valid {
			user.AvatarURL = avatar.String
		}
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" {
				response.Conflict(c, "邮箱已被注册")
				return
			}
			log.Error().Err(err).Msg("register user failed")
			response.InternalServerError(c)
			return
		}

		accessToken, expiresIn, err := jwtSvc.IssueAccessToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue register access token failed")
			response.InternalServerError(c)
			return
		}
		refreshToken, _, err := jwtSvc.IssueRefreshToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue register tokens failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, model.LoginResponse{
			User: &model.UserProfile{
				ID:             user.ID,
				Nickname:       user.Nickname,
				AvatarURL:      user.AvatarURL,
				UserType:       user.UserType,
				CheckinCount:   user.CheckinCount,
				PoemViewCount:  user.PoemViewCount,
				AudioPlayCount: user.AudioPlayCount,
				Status:         user.Status,
			},
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    expiresIn,
			TokenType:    "Bearer",
		})
	}
}

// Login 用户登录
func Login(db *database.DB, jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: phone/email/password 必填")
			return
		}

		const query = `
SELECT id, phone, email, nickname, avatar_url, user_type, checkin_count, poem_view_count, audio_play_count, status, password_hash
FROM users
WHERE status = 1
  AND (($1 <> '' AND phone = $1) OR ($2 <> '' AND email = $2))
LIMIT 1`

		var (
			user         model.User
			passwordHash *string
			phone        sql.NullString
			avatar       sql.NullString
		)

		err := db.Pool.QueryRow(c.Request.Context(), query, req.Phone, req.Email).Scan(
			&user.ID,
			&phone,
			&user.Email,
			&user.Nickname,
			&avatar,
			&user.UserType,
			&user.CheckinCount,
			&user.PoemViewCount,
			&user.AudioPlayCount,
			&user.Status,
			&passwordHash,
		)
		if err != nil {
			response.Unauthorized(c)
			return
		}
		if phone.Valid {
			user.Phone = phone.String
		}
		if avatar.Valid {
			user.AvatarURL = avatar.String
		}

		if passwordHash != nil && *passwordHash != "" && *passwordHash != req.Password {
			response.Unauthorized(c)
			return
		}

		accessToken, expiresIn, err := jwtSvc.IssueAccessToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue access token failed")
			response.InternalServerError(c)
			return
		}
		refreshToken, _, err := jwtSvc.IssueRefreshToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue tokens failed")
			response.InternalServerError(c)
			return
		}

		_, _ = db.Pool.Exec(
			c.Request.Context(),
			`UPDATE users SET last_login_at = NOW(), last_login_ip = $2 WHERE id = $1`,
			user.ID, c.ClientIP(),
		)

		response.Success(c, model.LoginResponse{
			User: &model.UserProfile{
				ID:             user.ID,
				Nickname:       user.Nickname,
				AvatarURL:      user.AvatarURL,
				UserType:       user.UserType,
				CheckinCount:   user.CheckinCount,
				PoemViewCount:  user.PoemViewCount,
				AudioPlayCount: user.AudioPlayCount,
				Status:         user.Status,
			},
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    expiresIn,
			TokenType:    "Bearer",
		})
	}
}

// SendSMSCode 发送手机号验证码。生产环境依赖 Redis；本地测试未配置 Redis 时显式返回 dev code。
func SendSMSCode(redisCache *cache.Cache) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.SendSMSCodeRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: phone 必填")
			return
		}
		phone, ok := normalizeCNPhone(req.Phone)
		if !ok {
			response.BadRequest(c, "请输入有效手机号")
			return
		}

		if redisCache == nil {
			response.Success(c, gin.H{
				"sent":       true,
				"dev_mode":   true,
				"code":       smsDevCode,
				"expires_in": int64(smsCodeTTL.Seconds()),
			})
			return
		}

		ctx := c.Request.Context()
		cooldownKey := smsCooldownKey(phone)
		if exists, err := redisCache.Exists(ctx, cooldownKey); err != nil {
			log.Error().Err(err).Msg("sms cooldown check failed")
			response.InternalServerError(c)
			return
		} else if exists {
			response.TooManyRequests(c)
			return
		}

		code, err := generateSMSCode()
		if err != nil {
			log.Error().Err(err).Msg("generate sms code failed")
			response.InternalServerError(c)
			return
		}
		devMode := isSMSDevMode()
		if !devMode {
			response.Error(c, 50001, "短信服务未配置")
			return
		}

		if err := redisCache.Set(ctx, smsCodeKey(phone), code, smsCodeTTL); err != nil {
			log.Error().Err(err).Msg("store sms code failed")
			response.InternalServerError(c)
			return
		}
		if err := redisCache.Set(ctx, cooldownKey, "1", smsCooldownTTL); err != nil {
			log.Error().Err(err).Msg("store sms cooldown failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"sent":       true,
			"dev_mode":   true,
			"code":       code,
			"expires_in": int64(smsCodeTTL.Seconds()),
		})
	}
}

// SMSLogin 使用手机号验证码登录；手机号不存在时自动注册。
func SMSLogin(db *database.DB, jwtSvc *service.JWTService, redisCache *cache.Cache) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.SMSLoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: phone/code 必填")
			return
		}
		phone, ok := normalizeCNPhone(req.Phone)
		if !ok {
			response.BadRequest(c, "请输入有效手机号")
			return
		}
		if !verifySMSCode(c, redisCache, phone, req.Code) {
			return
		}

		user, err := findOrCreateUserByPhone(c.Request.Context(), db, phone)
		if err != nil {
			log.Error().Err(err).Msg("sms login find or create user failed")
			response.InternalServerError(c)
			return
		}

		accessToken, expiresIn, err := jwtSvc.IssueAccessToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue sms login access token failed")
			response.InternalServerError(c)
			return
		}
		refreshToken, _, err := jwtSvc.IssueRefreshToken(user.ID)
		if err != nil {
			log.Error().Err(err).Msg("issue sms login tokens failed")
			response.InternalServerError(c)
			return
		}

		_, _ = db.Pool.Exec(
			c.Request.Context(),
			`UPDATE users SET last_login_at = NOW(), last_login_ip = $2 WHERE id = $1`,
			user.ID, c.ClientIP(),
		)

		response.Success(c, model.LoginResponse{
			User: &model.UserProfile{
				ID:             user.ID,
				Nickname:       user.Nickname,
				AvatarURL:      user.AvatarURL,
				UserType:       user.UserType,
				CheckinCount:   user.CheckinCount,
				PoemViewCount:  user.PoemViewCount,
				AudioPlayCount: user.AudioPlayCount,
				Status:         user.Status,
			},
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    expiresIn,
			TokenType:    "Bearer",
		})
	}
}

// Logout 用户登出
func Logout(c *gin.Context) {
	response.SuccessWithMessage(c, "logout success", gin.H{
		"logged_out": true,
	})
}

// RefreshToken 刷新访问令牌
func RefreshToken(db *database.DB, jwtSvc *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.RefreshTokenRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: refresh_token 必填")
			return
		}

		userID, err := jwtSvc.ParseToken(req.RefreshToken, service.TokenTypeRefresh)
		if err != nil {
			response.Unauthorized(c)
			return
		}

		var exists bool
		err = db.Pool.QueryRow(c.Request.Context(), `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND status = 1)`, userID).Scan(&exists)
		if err != nil || !exists {
			response.Unauthorized(c)
			return
		}

		accessToken, expiresIn, err := jwtSvc.IssueAccessToken(userID)
		if err != nil {
			log.Error().Err(err).Msg("refresh issue access token failed")
			response.InternalServerError(c)
			return
		}
		refreshToken, _, err := jwtSvc.IssueRefreshToken(userID)
		if err != nil {
			log.Error().Err(err).Msg("refresh issue token failed")
			response.InternalServerError(c)
			return
		}

		response.Success(c, model.RefreshTokenResponse{
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    expiresIn,
			TokenType:    "Bearer",
		})
	}
}

// ForgotPassword 忘记密码，发送重置邮件
func ForgotPassword(db *database.DB, mailer service.MailSender, redisCache *cache.Cache) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.ForgotPasswordRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: email 不合法")
			return
		}
		email := strings.ToLower(strings.TrimSpace(req.Email))

		if blocked, limitErr := hitRateLimit(c, redisCache, "auth:forgot:ip:"+c.ClientIP(), 10, 15*time.Minute); limitErr != nil {
			log.Error().Err(limitErr).Msg("forgot-password ip rate-limit check failed")
			response.InternalServerError(c)
			return
		} else if blocked {
			response.TooManyRequests(c)
			return
		}
		if blocked, limitErr := hitRateLimit(c, redisCache, "auth:forgot:email:"+email, 3, 15*time.Minute); limitErr != nil {
			log.Error().Err(limitErr).Msg("forgot-password email rate-limit check failed")
			response.InternalServerError(c)
			return
		} else if blocked {
			response.TooManyRequests(c)
			return
		}

		if mailer == nil {
			response.Error(c, 50001, "邮件服务未配置")
			return
		}

		const genericMessage = "如果邮箱已注册，重置链接已发送，请检查邮件"

		var userID int64
		err := db.Pool.QueryRow(
			c.Request.Context(),
			`SELECT id FROM users WHERE email = $1 AND status = 1 LIMIT 1`,
			email,
		).Scan(&userID)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				response.SuccessWithMessage(c, genericMessage, gin.H{"sent": true})
				return
			}
			log.Error().Err(err).Msg("query user for forgot password failed")
			response.InternalServerError(c)
			return
		}

		resetToken, err := randomTokenSegment(24)
		if err != nil {
			log.Error().Err(err).Msg("generate reset token failed")
			response.InternalServerError(c)
			return
		}
		tokenHash := hashToken(resetToken)
		expiresAt := time.Now().Add(30 * time.Minute)

		tx, err := db.Pool.Begin(c.Request.Context())
		if err != nil {
			log.Error().Err(err).Msg("begin forgot password tx failed")
			response.InternalServerError(c)
			return
		}
		defer func() {
			_ = tx.Rollback(context.Background())
		}()

		_, err = tx.Exec(
			c.Request.Context(),
			`UPDATE password_reset_tokens SET used_at = NOW() WHERE user_id = $1 AND used_at IS NULL`,
			userID,
		)
		if err != nil {
			log.Error().Err(err).Msg("invalidate old reset tokens failed")
			response.InternalServerError(c)
			return
		}

		_, err = tx.Exec(
			c.Request.Context(),
			`INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
			userID,
			tokenHash,
			expiresAt,
		)
		if err != nil {
			log.Error().Err(err).Msg("insert reset token failed")
			response.InternalServerError(c)
			return
		}

		if err = tx.Commit(c.Request.Context()); err != nil {
			log.Error().Err(err).Msg("commit forgot password tx failed")
			response.InternalServerError(c)
			return
		}

		if err = mailer.SendPasswordReset(c.Request.Context(), email, resetToken, expiresAt); err != nil {
			log.Error().Err(err).Msg("send reset password email failed")
			response.Error(c, 50001, "邮件发送失败，请稍后重试")
			return
		}

		response.SuccessWithMessage(c, genericMessage, gin.H{"sent": true})
	}
}

// ResetPassword 使用重置令牌重置密码
func ResetPassword(db *database.DB, redisCache *cache.Cache) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.ResetPasswordRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: token/new_password 不合法")
			return
		}

		tokenHash := hashToken(req.Token)
		if blocked, limitErr := hitRateLimit(c, redisCache, "auth:reset:ip:"+c.ClientIP(), 20, 15*time.Minute); limitErr != nil {
			log.Error().Err(limitErr).Msg("reset-password ip rate-limit check failed")
			response.InternalServerError(c)
			return
		} else if blocked {
			response.TooManyRequests(c)
			return
		}
		if blocked, limitErr := hitRateLimit(c, redisCache, "auth:reset:token:"+tokenHash, 8, time.Hour); limitErr != nil {
			log.Error().Err(limitErr).Msg("reset-password token rate-limit check failed")
			response.InternalServerError(c)
			return
		} else if blocked {
			response.TooManyRequests(c)
			return
		}

		tx, err := db.Pool.Begin(c.Request.Context())
		if err != nil {
			log.Error().Err(err).Msg("begin reset password tx failed")
			response.InternalServerError(c)
			return
		}
		defer func() {
			_ = tx.Rollback(context.Background())
		}()

		var (
			tokenID   int64
			userID    int64
			expiresAt time.Time
			usedAt    *time.Time
		)

		err = tx.QueryRow(
			c.Request.Context(),
			`SELECT id, user_id, expires_at, used_at FROM password_reset_tokens WHERE token_hash = $1 ORDER BY id DESC LIMIT 1`,
			tokenHash,
		).Scan(&tokenID, &userID, &expiresAt, &usedAt)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				response.BadRequest(c, "重置令牌无效")
				return
			}
			log.Error().Err(err).Msg("query reset token failed")
			response.InternalServerError(c)
			return
		}

		if usedAt != nil || time.Now().After(expiresAt) {
			response.BadRequest(c, "重置令牌已失效")
			return
		}

		cmdTag, err := tx.Exec(
			c.Request.Context(),
			`UPDATE users SET password_hash = $2, updated_at = NOW() WHERE id = $1 AND status = 1`,
			userID,
			req.NewPassword,
		)
		if err != nil {
			log.Error().Err(err).Msg("update user password failed")
			response.InternalServerError(c)
			return
		}
		if cmdTag.RowsAffected() == 0 {
			response.BadRequest(c, "用户不存在或不可用")
			return
		}

		_, err = tx.Exec(
			c.Request.Context(),
			`UPDATE password_reset_tokens SET used_at = NOW() WHERE id = $1`,
			tokenID,
		)
		if err != nil {
			log.Error().Err(err).Msg("mark reset token used failed")
			response.InternalServerError(c)
			return
		}

		_, err = tx.Exec(
			c.Request.Context(),
			`UPDATE password_reset_tokens SET used_at = NOW() WHERE user_id = $1 AND used_at IS NULL`,
			userID,
		)
		if err != nil {
			log.Error().Err(err).Msg("invalidate sibling reset tokens failed")
			response.InternalServerError(c)
			return
		}

		if err = tx.Commit(c.Request.Context()); err != nil {
			log.Error().Err(err).Msg("commit reset password tx failed")
			response.InternalServerError(c)
			return
		}

		response.SuccessWithMessage(c, "密码重置成功", gin.H{
			"reset": true,
		})
	}
}

func randomTokenSegment(rawLen int) (string, error) {
	buf := make([]byte, rawLen)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(token)))
	return hex.EncodeToString(sum[:])
}

func normalizeCNPhone(raw string) (string, bool) {
	phone := strings.TrimSpace(raw)
	phone = strings.TrimPrefix(phone, "+86")
	phone = strings.TrimPrefix(phone, "86")
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")
	return phone, cnPhonePattern.MatchString(phone)
}

func smsCodeKey(phone string) string {
	return "auth:sms:code:" + phone
}

func smsCooldownKey(phone string) string {
	return "auth:sms:cooldown:" + phone
}

func smsFailureKey(phone string) string {
	return "auth:sms:fail:" + phone
}

func generateSMSCode() (string, error) {
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func isSMSDevMode() bool {
	return gin.Mode() != gin.ReleaseMode || strings.EqualFold(os.Getenv("MISHI_SMS_DEV_MODE"), "true")
}

func verifySMSCode(c *gin.Context, redisCache *cache.Cache, phone, code string) bool {
	code = strings.TrimSpace(code)
	if redisCache == nil {
		if code != smsDevCode {
			response.BadRequest(c, "验证码错误或已过期")
			return false
		}
		return true
	}

	ctx := c.Request.Context()
	failures, err := redisCache.Incr(ctx, smsFailureKey(phone))
	if err != nil {
		log.Error().Err(err).Msg("sms failure count failed")
		response.InternalServerError(c)
		return false
	}
	if failures == 1 {
		_ = redisCache.Client.Expire(ctx, smsFailureKey(phone), smsCodeTTL).Err()
	}
	if failures > smsMaxVerifyFailure {
		response.TooManyRequests(c)
		return false
	}

	expected, err := redisCache.Get(ctx, smsCodeKey(phone))
	if err != nil || expected == "" || expected != code {
		response.BadRequest(c, "验证码错误或已过期")
		return false
	}

	_ = redisCache.Delete(ctx, smsCodeKey(phone))
	_ = redisCache.Delete(ctx, smsFailureKey(phone))
	return true
}

func findOrCreateUserByPhone(ctx context.Context, db *database.DB, phone string) (*model.User, error) {
	user, err := findUserByPhone(ctx, db, phone)
	if err == nil {
		return user, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}

	nickname := "诗友" + phone[len(phone)-4:]
	const insertQ = `
INSERT INTO users (phone, nickname, user_type, status)
VALUES ($1, $2, 'normal', 1)
RETURNING id, phone, nickname, avatar_url, user_type, checkin_count, poem_view_count, audio_play_count, status`

	created := &model.User{}
	var avatar sql.NullString
	err = db.Pool.QueryRow(ctx, insertQ, phone, nickname).Scan(
		&created.ID,
		&created.Phone,
		&created.Nickname,
		&avatar,
		&created.UserType,
		&created.CheckinCount,
		&created.PoemViewCount,
		&created.AudioPlayCount,
		&created.Status,
	)
	if err == nil {
		if avatar.Valid {
			created.AvatarURL = avatar.String
		}
		return created, nil
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return findUserByPhone(ctx, db, phone)
	}
	return nil, err
}

func findUserByPhone(ctx context.Context, db *database.DB, phone string) (*model.User, error) {
	const query = `
SELECT id, phone, nickname, avatar_url, user_type, checkin_count, poem_view_count, audio_play_count, status
FROM users
WHERE phone = $1 AND status = 1
LIMIT 1`

	user := &model.User{}
	var avatar sql.NullString
	err := db.Pool.QueryRow(ctx, query, phone).Scan(
		&user.ID,
		&user.Phone,
		&user.Nickname,
		&avatar,
		&user.UserType,
		&user.CheckinCount,
		&user.PoemViewCount,
		&user.AudioPlayCount,
		&user.Status,
	)
	if avatar.Valid {
		user.AvatarURL = avatar.String
	}
	return user, err
}

func hitRateLimit(c *gin.Context, redisCache *cache.Cache, key string, limit int64, window time.Duration) (bool, error) {
	if redisCache == nil || redisCache.Client == nil {
		return false, nil
	}

	count, err := redisCache.Client.Incr(c.Request.Context(), key).Result()
	if err != nil {
		return false, err
	}
	if count == 1 {
		if err = redisCache.Client.Expire(c.Request.Context(), key, window).Err(); err != nil {
			return false, err
		}
	}
	return count > limit, nil
}
