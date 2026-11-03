package model

import (
	"time"
)

// User 用户模型
type User struct {
	ID        int64  `json:"id"`
	Phone     string `json:"phone,omitempty"`
	Email     string `json:"email,omitempty"`
	Nickname  string `json:"nickname"`
	AvatarURL string `json:"avatar_url,omitempty"`

	// 用户类型
	UserType string `json:"user_type"`

	// 统计信息
	CheckinCount   int64 `json:"checkin_count"`
	PoemViewCount  int64 `json:"poem_view_count"`
	AudioPlayCount int64 `json:"audio_play_count"`

	// 状态
	Status int `json:"status"`

	// 安全信息（不对外暴露）
	PasswordHash string `json:"-"`
	Salt         string `json:"-"`

	// 登录信息
	LastLoginAt *time.Time `json:"last_login_at,omitempty"`
	LastLoginIP string     `json:"last_login_ip,omitempty"`

	// 时间戳
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserResponse 用户响应
type UserResponse struct {
	User *User `json:"user"`
}

// UserProfile 用户资料（公开信息）
type UserProfile struct {
	ID        int64  `json:"id"`
	Nickname  string `json:"nickname"`
	AvatarURL string `json:"avatar_url,omitempty"`
	UserType  string `json:"user_type"`

	// 统计信息
	CheckinCount   int64 `json:"checkin_count"`
	PoemViewCount  int64 `json:"poem_view_count"`
	AudioPlayCount int64 `json:"audio_play_count"`

	// 状态
	Status int `json:"status"`
}

// LoginRequest 登录请求
type LoginRequest struct {
	Phone    string `json:"phone" binding:"required_without=Email"`
	Email    string `json:"email" binding:"required_without=Phone"`
	Password string `json:"password" binding:"required"`
	DeviceID string `json:"device_id"`
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Username string `json:"username" binding:"required,min=2,max=100"`
}

// SendSMSCodeRequest 发送短信验证码请求
type SendSMSCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// SMSLoginRequest 手机号验证码登录/注册请求
type SMSLoginRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required,len=6"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	User         *UserProfile `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token,omitempty"`
	ExpiresIn    int64        `json:"expires_in"`
	TokenType    string       `json:"token_type"`
}

// RefreshTokenRequest 刷新令牌请求
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshTokenResponse 刷新令牌响应
type RefreshTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token,omitempty"`
	ExpiresIn    int64  `json:"expires_in"`
	TokenType    string `json:"token_type"`
}

// ForgotPasswordRequest 忘记密码请求
type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

// ResetPasswordRequest 重置密码请求
type ResetPasswordRequest struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}
