package handler

import (
	"testing"

	"github.com/mishi-app/backend/internal/config"
	"github.com/mishi-app/backend/internal/service"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIssueAndParseRefreshToken(t *testing.T) {
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})
	refreshToken, _, err := jwtSvc.IssueRefreshToken(42)
	require.NoError(t, err)
	require.NotEmpty(t, refreshToken)

	uid, err := jwtSvc.ParseToken(refreshToken, service.TokenTypeRefresh)
	require.NoError(t, err)
	assert.Equal(t, int64(42), uid)
}

func TestParseRefreshToken_Invalid(t *testing.T) {
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})
	_, err := jwtSvc.ParseToken("bad-token", service.TokenTypeRefresh)
	require.Error(t, err)
}
