package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mishi-app/backend/internal/config"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/service"
	"github.com/mishi-app/backend/pkg/middleware"
	"github.com/stretchr/testify/require"
)

type apiEnvelope struct {
	Code      int             `json:"code"`
	Message   string          `json:"message"`
	Data      json.RawMessage `json:"data"`
	Timestamp int64           `json:"timestamp"`
}

type testMailer struct {
	lastEmail string
	lastToken string
}

func (m *testMailer) SendPasswordReset(_ context.Context, toEmail, resetToken string, _ time.Time) error {
	m.lastEmail = toEmail
	m.lastToken = resetToken
	return nil
}

func TestIntegrationAuthLoginAndRefresh(t *testing.T) {
	db := requireIntegrationDB(t)
	email, password, cleanup := insertIntegrationUser(t, db)
	defer cleanup()
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})

	router := gin.New()
	v1 := router.Group("/v1")
	{
		auth := v1.Group("/auth")
		auth.POST("/register", Register(db, jwtSvc))
		auth.POST("/login", Login(db, jwtSvc))
		auth.POST("/refresh", RefreshToken(db, jwtSvc))
		auth.POST("/logout", middleware.AuthRequired(jwtSvc), Logout)
	}

	registerBody := map[string]any{
		"email":    fmt.Sprintf("it-new-%d@example.com", time.Now().UnixNano()),
		"password": "pw-register",
		"username": "it-new-user",
	}
	w := performJSONRequest(t, router, http.MethodPost, "/v1/auth/register", registerBody)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	loginBody := map[string]any{
		"email":    email,
		"password": password,
	}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/login", loginBody)
	require.Equal(t, http.StatusOK, w.Code)

	var loginResp apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &loginResp))
	require.Equal(t, 0, loginResp.Code)

	var loginData map[string]any
	require.NoError(t, json.Unmarshal(loginResp.Data, &loginData))
	accessToken, ok := loginData["access_token"].(string)
	require.True(t, ok)
	require.NotEmpty(t, accessToken)
	refreshToken, ok := loginData["refresh_token"].(string)
	require.True(t, ok)
	require.NotEmpty(t, refreshToken)

	refreshBody := map[string]any{"refresh_token": refreshToken}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/refresh", refreshBody)
	require.Equal(t, http.StatusOK, w.Code)

	var refreshResp apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &refreshResp))
	require.Equal(t, 0, refreshResp.Code)

	w = performAuthorizedJSONRequest(t, router, http.MethodPost, "/v1/auth/logout", accessToken, map[string]any{})
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)
}

func TestIntegrationSMSAuthCreatesThenLogsInExistingUser(t *testing.T) {
	db := requireIntegrationDB(t)
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})
	phone := "139" + strconv.FormatInt(time.Now().UnixNano()%100000000, 10)
	if len(phone) < 11 {
		phone = phone + strings.Repeat("0", 11-len(phone))
	}
	defer func() {
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM users WHERE phone = $1`, phone)
	}()

	router := gin.New()
	v1 := router.Group("/v1")
	{
		auth := v1.Group("/auth")
		auth.POST("/sms/send-code", SendSMSCode(nil))
		auth.POST("/sms/login", SMSLogin(db, jwtSvc, nil))
	}

	sendBody := map[string]any{"phone": phone}
	w := performJSONRequest(t, router, http.MethodPost, "/v1/auth/sms/send-code", sendBody)
	require.Equal(t, http.StatusOK, w.Code)

	var sendResp apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &sendResp))
	require.Equal(t, 0, sendResp.Code, "body=%s", w.Body.String())
	var sendData map[string]any
	require.NoError(t, json.Unmarshal(sendResp.Data, &sendData))
	require.Equal(t, true, sendData["dev_mode"])
	require.Equal(t, "123456", sendData["code"])

	loginBody := map[string]any{"phone": phone, "code": "123456"}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/sms/login", loginBody)
	require.Equal(t, http.StatusOK, w.Code)
	firstToken := extractAccessToken(t, w)
	require.NotEmpty(t, firstToken)

	var firstUserID int64
	require.NoError(t, db.Pool.QueryRow(context.Background(), `SELECT id FROM users WHERE phone = $1`, phone).Scan(&firstUserID))
	require.NotZero(t, firstUserID)

	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/sms/send-code", sendBody)
	require.Equal(t, http.StatusOK, w.Code)
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/sms/login", loginBody)
	require.Equal(t, http.StatusOK, w.Code)
	secondToken := extractAccessToken(t, w)
	require.NotEmpty(t, secondToken)

	var secondUserID int64
	require.NoError(t, db.Pool.QueryRow(context.Background(), `SELECT id FROM users WHERE phone = $1`, phone).Scan(&secondUserID))
	require.Equal(t, firstUserID, secondUserID)
}

func TestIntegrationForgotAndResetPassword(t *testing.T) {
	db := requireIntegrationDB(t)
	email, oldPassword, cleanup := insertIntegrationUser(t, db)
	defer cleanup()
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})

	mailer := &testMailer{}

	router := gin.New()
	v1 := router.Group("/v1")
	{
		auth := v1.Group("/auth")
		auth.POST("/login", Login(db, jwtSvc))
		auth.POST("/forgot-password", ForgotPassword(db, mailer, nil))
		auth.POST("/reset-password", ResetPassword(db, nil))
	}

	forgotBody := map[string]any{
		"email": email,
	}
	w := performJSONRequest(t, router, http.MethodPost, "/v1/auth/forgot-password", forgotBody)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)
	require.Equal(t, email, mailer.lastEmail)
	require.NotEmpty(t, mailer.lastToken)

	newPassword := "new-" + strconv.FormatInt(time.Now().UnixNano(), 10)
	resetBody := map[string]any{
		"token":        mailer.lastToken,
		"new_password": newPassword,
	}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/reset-password", resetBody)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	loginBodyOld := map[string]any{
		"email":    email,
		"password": oldPassword,
	}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/login", loginBodyOld)
	require.Equal(t, http.StatusOK, w.Code)
	assertEnvelopeCode(t, w, 40101)

	loginBodyNew := map[string]any{
		"email":    email,
		"password": newPassword,
	}
	w = performJSONRequest(t, router, http.MethodPost, "/v1/auth/login", loginBodyNew)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)
}

func TestIntegrationGeoPoemsAndCheckinsFlow(t *testing.T) {
	db := requireIntegrationDB(t)
	fixture, cleanup := insertIntegrationFixture(t, db)
	defer cleanup()
	jwtSvc := service.NewJWTService(config.JWTConfig{
		Secret: "test-secret",
		Issuer: "test",
	})

	router := gin.New()
	v1 := router.Group("/v1")
	{
		auth := v1.Group("/auth")
		auth.POST("/login", Login(db, jwtSvc))

		geo := v1.Group("/geo")
		geo.GET("/nearby", GeoNearby(db))
		poems := v1.Group("/poems")
		poems.GET("/recommend", RecommendPoems(db))
		poems.GET("/search", SearchPoems(db))
		poems.GET("/:id", GetPoem(db))
		checkins := v1.Group("/checkins")
		checkins.Use(middleware.AuthRequired(jwtSvc))
		checkins.POST("/", CreateCheckin(db))
		checkins.GET("/history", GetCheckinHistory(db))
	}

	loginBody := map[string]any{
		"email":    fixture.email,
		"password": fixture.password,
	}
	w := performJSONRequest(t, router, http.MethodPost, "/v1/auth/login", loginBody)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)
	accessToken := extractAccessToken(t, w)

	geoURL := fmt.Sprintf("/v1/geo/nearby?lat=31.2304&lon=121.4737&radius=500&limit=10")
	w = performRequest(router, http.MethodGet, geoURL, nil)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	recommendURL := fmt.Sprintf("/v1/poems/recommend?lat=31.2304&lon=121.4737&radius=500&limit=10")
	w = performRequest(router, http.MethodGet, recommendURL, nil)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	searchURL := "/v1/poems/search?q=集成测试&limit=10&offset=0"
	w = performRequest(router, http.MethodGet, searchURL, nil)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	detailURL := fmt.Sprintf("/v1/poems/%d", fixture.poemID)
	w = performRequest(router, http.MethodGet, detailURL, nil)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	checkinBody := map[string]any{
		"poi_id":  fixture.poiID,
		"poem_id": fixture.poemID,
		"lat":     31.2304,
		"lon":     121.4737,
		"device_info": map[string]any{
			"device_id":    "integration-device",
			"device_model": "test",
		},
	}
	checkinURL := "/v1/checkins/"
	w = performAuthorizedJSONRequest(t, router, http.MethodPost, checkinURL, accessToken, checkinBody)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)

	historyURL := "/v1/checkins/history?limit=10&offset=0"
	w = performAuthorizedRequest(router, http.MethodGet, historyURL, accessToken, nil)
	require.Equal(t, http.StatusOK, w.Code)
	assertSuccessCode(t, w)
}

func requireIntegrationDB(t *testing.T) *database.DB {
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://mishi:mishi_password@localhost:5432/mishi?sslmode=disable"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Skipf("skip integration test: create pool failed: %v", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		t.Skipf("skip integration test: db unreachable: %v", err)
	}
	t.Cleanup(pool.Close)
	return &database.DB{Pool: pool}
}

type integrationFixture struct {
	userID   int64
	poemID   int64
	poiID    int64
	email    string
	password string
}

func insertIntegrationUser(t *testing.T, db *database.DB) (string, string, func()) {
	t.Helper()
	suffix := strconv.FormatInt(time.Now().UnixNano(), 10)
	email := "it-auth-" + suffix + "@example.com"
	password := "pw-" + suffix

	var userID int64
	err := db.Pool.QueryRow(
		context.Background(),
		`INSERT INTO users (email, nickname, user_type, status, password_hash) VALUES ($1, $2, 'test', 1, $3) RETURNING id`,
		email,
		"it-auth-"+suffix,
		password,
	).Scan(&userID)
	require.NoError(t, err)

	cleanup := func() {
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM users WHERE id = $1`, userID)
	}
	return email, password, cleanup
}

func insertIntegrationFixture(t *testing.T, db *database.DB) (integrationFixture, func()) {
	t.Helper()
	suffix := strconv.FormatInt(time.Now().UnixNano(), 10)
	email := "it-flow-" + suffix + "@example.com"
	password := "pw-" + suffix

	var userID int64
	err := db.Pool.QueryRow(
		context.Background(),
		`INSERT INTO users (email, nickname, user_type, status, password_hash) VALUES ($1, $2, 'test', 1, $3) RETURNING id`,
		email,
		"it-flow-"+suffix,
		password,
	).Scan(&userID)
	require.NoError(t, err)

	var poemID int64
	err = db.Pool.QueryRow(
		context.Background(),
		`INSERT INTO poems (title, author, dynasty, content, content_text, tags, best_seasons, solar_terms, time_period_tags, status)
VALUES ($1, '测试作者', '当代', $2::jsonb, '测试内容', '["测试"]'::jsonb, '["春"]'::jsonb, '["立春"]'::jsonb, '[]'::jsonb, 'published')
RETURNING id`,
		"集成测试诗词-"+suffix,
		`[{"text":"测试句一"},{"text":"测试句二"}]`,
	).Scan(&poemID)
	require.NoError(t, err)

	var poiID int64
	err = db.Pool.QueryRow(
		context.Background(),
		`INSERT INTO pois (name, ancient_name, modern_name, location, radius, city_code, category, description, status)
VALUES ($1, $1, $1, ST_SetSRID(ST_MakePoint(121.4737, 31.2304), 4326), 100, '310000', '景点', '集成测试POI', 1)
RETURNING id`,
		"集成测试点位-"+suffix,
	).Scan(&poiID)
	require.NoError(t, err)

	_, err = db.Pool.Exec(
		context.Background(),
		`INSERT INTO poi_poems (poi_id, poem_id, distance, relevance_score, created_by) VALUES ($1, $2, 10, 0.9, 'manual')`,
		poiID, poemID,
	)
	require.NoError(t, err)

	cleanup := func() {
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM checkins WHERE user_id = $1`, userID)
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM poi_poems WHERE poem_id = $1`, poemID)
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM pois WHERE id = $1`, poiID)
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM poems WHERE id = $1`, poemID)
		_, _ = db.Pool.Exec(context.Background(), `DELETE FROM users WHERE id = $1`, userID)
	}
	return integrationFixture{userID: userID, poemID: poemID, poiID: poiID, email: email, password: password}, cleanup
}

func performJSONRequest(t *testing.T, router *gin.Engine, method, path string, body any) *httptest.ResponseRecorder {
	t.Helper()
	raw, err := json.Marshal(body)
	require.NoError(t, err)
	return performRequest(router, method, path, raw)
}

func performRequest(router *gin.Engine, method, path string, body []byte) *httptest.ResponseRecorder {
	var payload *bytes.Reader
	if body == nil {
		payload = bytes.NewReader(nil)
	} else {
		payload = bytes.NewReader(body)
	}
	req := httptest.NewRequest(method, path, payload)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func performAuthorizedRequest(router *gin.Engine, method, path, accessToken string, body []byte) *httptest.ResponseRecorder {
	var payload *bytes.Reader
	if body == nil {
		payload = bytes.NewReader(nil)
	} else {
		payload = bytes.NewReader(body)
	}
	req := httptest.NewRequest(method, path, payload)
	req.Header.Set("Authorization", "Bearer "+accessToken)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func performAuthorizedJSONRequest(t *testing.T, router *gin.Engine, method, path, accessToken string, body any) *httptest.ResponseRecorder {
	t.Helper()
	raw, err := json.Marshal(body)
	require.NoError(t, err)
	return performAuthorizedRequest(router, method, path, accessToken, raw)
}

func assertSuccessCode(t *testing.T, w *httptest.ResponseRecorder) {
	t.Helper()
	var envelope apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &envelope))
	require.Equal(t, 0, envelope.Code, "body=%s", w.Body.String())
}

func assertEnvelopeCode(t *testing.T, w *httptest.ResponseRecorder, expected int) {
	t.Helper()
	var envelope apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &envelope))
	require.Equal(t, expected, envelope.Code, "body=%s", w.Body.String())
}

func extractAccessToken(t *testing.T, w *httptest.ResponseRecorder) string {
	t.Helper()
	var envelope apiEnvelope
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &envelope))
	require.Equal(t, 0, envelope.Code)
	var data map[string]any
	require.NoError(t, json.Unmarshal(envelope.Data, &data))
	token, _ := data["access_token"].(string)
	require.NotEmpty(t, token)
	return token
}
