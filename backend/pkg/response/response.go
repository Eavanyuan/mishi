package response

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Response 标准响应结构
type Response struct {
	Code      int         `json:"code"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data"`
	Timestamp int64       `json:"timestamp"`
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:      0,
		Message:   "success",
		Data:      data,
		Timestamp: time.Now().Unix(),
	})
}

// SuccessWithMessage 带消息的成功响应
func SuccessWithMessage(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:      0,
		Message:   message,
		Data:      data,
		Timestamp: time.Now().Unix(),
	})
}

// Error 错误响应
func Error(c *gin.Context, code int, message string) {
	c.JSON(http.StatusOK, Response{
		Code:      code,
		Message:   message,
		Data:      nil,
		Timestamp: time.Now().Unix(),
	})
}

// ErrorWithDetail 带详细信息的错误响应
func ErrorWithDetail(c *gin.Context, code int, message string, detail interface{}) {
	c.JSON(http.StatusOK, gin.H{
		"code":      code,
		"message":   message,
		"error_detail": detail,
		"timestamp": time.Now().Unix(),
	})
}

// BadRequest 参数错误
func BadRequest(c *gin.Context, message string) {
	Error(c, 40001, message)
}

// Unauthorized 未授权
func Unauthorized(c *gin.Context) {
	Error(c, 40101, "未授权")
}

// Forbidden 禁止访问
func Forbidden(c *gin.Context) {
	Error(c, 40301, "禁止访问")
}

// NotFound 资源不存在
func NotFound(c *gin.Context) {
	Error(c, 40401, "资源不存在")
}

// Conflict 冲突
func Conflict(c *gin.Context, message string) {
	Error(c, 40901, message)
}

// TooManyRequests 请求过于频繁
func TooManyRequests(c *gin.Context) {
	Error(c, 42901, "请求过于频繁，请稍后再试")
}

// InternalServerError 服务器内部错误
func InternalServerError(c *gin.Context) {
	Error(c, 50001, "服务器内部错误")
}

// ServiceUnavailable 服务不可用
func ServiceUnavailable(c *gin.Context) {
	Error(c, 50301, "服务不可用")
}