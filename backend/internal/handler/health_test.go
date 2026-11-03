package handler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// MockDB 模拟数据库
type MockDB struct{}

func (m *MockDB) HealthCheck(ctx context.Context) error {
	return nil
}

func TestHealthCheck(t *testing.T) {
	// 设置Gin测试模式
	gin.SetMode(gin.TestMode)

	// 创建测试路由
	router := gin.New()
	mockDB := &MockDB{}
	router.GET("/health", HealthCheck(mockDB, nil))

	// 创建测试请求
	req, err := http.NewRequest("GET", "/health", nil)
	assert.NoError(t, err)

	// 执行请求
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// 验证响应
	assert.Equal(t, http.StatusOK, w.Code)

	// 注意：由于timestamp和uptime字段是动态的，我们只检查基本结构
	assert.Contains(t, w.Body.String(), `"code":0`)
	assert.Contains(t, w.Body.String(), `"message":"success"`)
	assert.Contains(t, w.Body.String(), `"status":"healthy"`)
	assert.Contains(t, w.Body.String(), `"redis":{"error":"","status":"not_initialized"}`)
}

func TestPing(t *testing.T) {
	// 设置Gin测试模式
	gin.SetMode(gin.TestMode)

	// 创建测试路由
	router := gin.New()
	router.GET("/ping", Ping)

	// 创建测试请求
	req, err := http.NewRequest("GET", "/ping", nil)
	assert.NoError(t, err)

	// 执行请求
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// 验证响应
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"code":0`)
	assert.Contains(t, w.Body.String(), `"message":"pong"`)
}
