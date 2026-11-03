package service

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/mishi-app/backend/internal/config"
)

type TokenType string

const (
	TokenTypeAccess  TokenType = "access"
	TokenTypeRefresh TokenType = "refresh"
)

type JWTService struct {
	secret           []byte
	issuer           string
	accessTTLMinutes int
	refreshTTLDays   int
}

type tokenClaims struct {
	UserID int64     `json:"uid"`
	Type   TokenType `json:"typ"`
	Exp    int64     `json:"exp"`
	Iat    int64     `json:"iat"`
	Iss    string    `json:"iss"`
}

func NewJWTService(cfg config.JWTConfig) *JWTService {
	secret := strings.TrimSpace(cfg.Secret)
	if secret == "" {
		secret = generateEphemeralSecret()
	}
	issuer := strings.TrimSpace(cfg.Issuer)
	if issuer == "" {
		issuer = "mishi-backend"
	}

	accessTTL := cfg.AccessTTLMinutes
	if accessTTL <= 0 {
		accessTTL = 60
	}
	refreshTTL := cfg.RefreshTTLDays
	if refreshTTL <= 0 {
		refreshTTL = 30
	}

	return &JWTService{
		secret:           []byte(secret),
		issuer:           issuer,
		accessTTLMinutes: accessTTL,
		refreshTTLDays:   refreshTTL,
	}
}

func (s *JWTService) IssueAccessToken(userID int64) (string, int64, error) {
	expireAt := time.Now().Add(time.Duration(s.accessTTLMinutes) * time.Minute)
	token, err := s.signClaims(tokenClaims{
		UserID: userID,
		Type:   TokenTypeAccess,
		Exp:    expireAt.Unix(),
		Iat:    time.Now().Unix(),
		Iss:    s.issuer,
	})
	if err != nil {
		return "", 0, err
	}
	return token, int64(time.Duration(s.accessTTLMinutes) * time.Minute / time.Second), nil
}

func (s *JWTService) IssueRefreshToken(userID int64) (string, int64, error) {
	expireAt := time.Now().Add(time.Duration(s.refreshTTLDays) * 24 * time.Hour)
	token, err := s.signClaims(tokenClaims{
		UserID: userID,
		Type:   TokenTypeRefresh,
		Exp:    expireAt.Unix(),
		Iat:    time.Now().Unix(),
		Iss:    s.issuer,
	})
	if err != nil {
		return "", 0, err
	}
	return token, int64(time.Duration(s.refreshTTLDays) * 24 * time.Hour / time.Second), nil
}

func (s *JWTService) ParseToken(token string, expectedType TokenType) (int64, error) {
	parts := strings.Split(strings.TrimSpace(token), ".")
	if len(parts) != 3 {
		return 0, fmt.Errorf("invalid token format")
	}

	unsigned := parts[0] + "." + parts[1]
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return 0, fmt.Errorf("invalid token signature encoding")
	}
	expectedSig := s.hmacSHA256(unsigned)
	if !hmac.Equal(signature, expectedSig) {
		return 0, fmt.Errorf("invalid token signature")
	}

	payloadRaw, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return 0, fmt.Errorf("invalid token payload")
	}

	var claims tokenClaims
	if err = json.Unmarshal(payloadRaw, &claims); err != nil {
		return 0, fmt.Errorf("invalid token payload json")
	}

	if claims.Iss != s.issuer {
		return 0, fmt.Errorf("invalid token issuer")
	}
	if claims.Type != expectedType {
		return 0, fmt.Errorf("invalid token type")
	}
	if claims.UserID <= 0 {
		return 0, fmt.Errorf("invalid token uid")
	}
	if time.Now().Unix() > claims.Exp {
		return 0, fmt.Errorf("token expired")
	}
	return claims.UserID, nil
}

func (s *JWTService) signClaims(claims tokenClaims) (string, error) {
	header := map[string]string{
		"alg": "HS256",
		"typ": "JWT",
	}
	headerRaw, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	payloadRaw, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	headerEnc := base64.RawURLEncoding.EncodeToString(headerRaw)
	payloadEnc := base64.RawURLEncoding.EncodeToString(payloadRaw)
	unsigned := headerEnc + "." + payloadEnc
	signature := base64.RawURLEncoding.EncodeToString(s.hmacSHA256(unsigned))
	return unsigned + "." + signature, nil
}

func (s *JWTService) hmacSHA256(input string) []byte {
	mac := hmac.New(sha256.New, s.secret)
	_, _ = mac.Write([]byte(input))
	return mac.Sum(nil)
}

func ParseBearerToken(header string) (string, error) {
	parts := strings.Split(strings.TrimSpace(header), " ")
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", fmt.Errorf("invalid authorization header")
	}
	if strings.TrimSpace(parts[1]) == "" {
		return "", fmt.Errorf("empty bearer token")
	}
	return parts[1], nil
}

func FormatTokenTTL(ttlSec int64) string {
	return strconv.FormatInt(ttlSec, 10)
}

func generateEphemeralSecret() string {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "dev-only-ephemeral-secret"
	}
	return base64.RawURLEncoding.EncodeToString(buf)
}
