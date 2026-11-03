package util

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"math/big"
	"time"
)

// GenerateRandomString 生成指定长度的随机字符串
func GenerateRandomString(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// GenerateUUID 生成UUID（简版）
func GenerateUUID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])
}

// GenerateJobID 生成任务ID
func GenerateJobID() string {
	timestamp := time.Now().UnixNano() / int64(time.Millisecond)
	random, _ := GenerateRandomString(6)
	return fmt.Sprintf("job_%d_%s", timestamp, random)
}

// GenerateOrderNo 生成订单号/编号
func GenerateOrderNo(prefix string) string {
	timestamp := time.Now().Format("20060102150405")
	random, _ := GenerateRandomString(4)
	return fmt.Sprintf("%s%s%s", prefix, timestamp, random)
}

// GenerateRandomInt 生成指定范围内的随机整数
func GenerateRandomInt(min, max int64) (int64, error) {
	if min >= max {
		return min, nil
	}

	n, err := rand.Int(rand.Reader, big.NewInt(max-min+1))
	if err != nil {
		return 0, err
	}

	return n.Int64() + min, nil
}

// ContainsString 检查字符串是否在切片中
func ContainsString(slice []string, str string) bool {
	for _, s := range slice {
		if s == str {
			return true
		}
	}
	return false
}

// RemoveString 从切片中移除字符串
func RemoveString(slice []string, str string) []string {
	result := []string{}
	for _, s := range slice {
		if s != str {
			result = append(result, s)
		}
	}
	return result
}

// TruncateString 截断字符串，添加省略号
func TruncateString(s string, maxLength int) string {
	if len(s) <= maxLength {
		return s
	}
	return s[:maxLength] + "..."
}

// FormatDuration 格式化持续时间
func FormatDuration(d time.Duration) string {
	if d < time.Second {
		return fmt.Sprintf("%dms", d.Milliseconds())
	}
	
	hours := int(d.Hours())
	minutes := int(d.Minutes()) % 60
	seconds := int(d.Seconds()) % 60
	
	if hours > 0 {
		return fmt.Sprintf("%dh%dm%ds", hours, minutes, seconds)
	} else if minutes > 0 {
		return fmt.Sprintf("%dm%ds", minutes, seconds)
	}
	return fmt.Sprintf("%ds", seconds)
}