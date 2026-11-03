package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestParseLatLon_SupportsLatLon(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ctx, _ := gin.CreateTestContext(httptest.NewRecorder())
	req := httptest.NewRequest(http.MethodGet, "/v1/geo/nearby?lat=39.9&lon=116.4", nil)
	ctx.Request = req

	lat, lon, err := parseLatLon(ctx)
	require.NoError(t, err)
	assert.InEpsilon(t, 39.9, lat, 0.0001)
	assert.InEpsilon(t, 116.4, lon, 0.0001)
}

func TestParseLatLon_SupportsLatitudeLongitude(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ctx, _ := gin.CreateTestContext(httptest.NewRecorder())
	req := httptest.NewRequest(http.MethodGet, "/v1/geo/nearby?latitude=31.2&longitude=121.5", nil)
	ctx.Request = req

	lat, lon, err := parseLatLon(ctx)
	require.NoError(t, err)
	assert.InEpsilon(t, 31.2, lat, 0.0001)
	assert.InEpsilon(t, 121.5, lon, 0.0001)
}

func TestParseLatLon_Missing(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ctx, _ := gin.CreateTestContext(httptest.NewRecorder())
	req := httptest.NewRequest(http.MethodGet, "/v1/geo/nearby", nil)
	ctx.Request = req

	_, _, err := parseLatLon(ctx)
	require.Error(t, err)
}

func TestParsePagination_DefaultAndBounds(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ctx, _ := gin.CreateTestContext(httptest.NewRecorder())
	ctx.Request = httptest.NewRequest(http.MethodGet, "/v1/checkins/history?limit=1000&offset=-3", nil)

	limit, offset := parsePagination(ctx, 20, 100)
	assert.Equal(t, 100, limit)
	assert.Equal(t, 0, offset)
}
