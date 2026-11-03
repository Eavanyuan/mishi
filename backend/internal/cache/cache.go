package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/mishi-app/backend/internal/config"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
)

// Cache 封装Redis客户端
type Cache struct {
	Client *redis.Client
}

// New 创建新的Redis客户端
func New(cfg config.RedisConfig) (*Cache, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Host, cfg.Port),
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		client.Close()
		return nil, fmt.Errorf("failed to connect to redis: %w", err)
	}

	log.Info().Str("host", cfg.Host).Int("port", cfg.Port).Int("db", cfg.DB).Msg("Redis connected")

	return &Cache{Client: client}, nil
}

// Close 关闭Redis连接
func (c *Cache) Close() error {
	if c.Client != nil {
		if err := c.Client.Close(); err != nil {
			log.Error().Err(err).Msg("Failed to close redis connection")
			return err
		}
		log.Info().Msg("Redis connection closed")
	}
	return nil
}

// HealthCheck 检查Redis连接状态
func (c *Cache) HealthCheck(ctx context.Context) error {
	if c.Client == nil {
		return fmt.Errorf("redis client is nil")
	}

	if err := c.Client.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("redis ping failed: %w", err)
	}

	return nil
}

// Get 获取缓存值
func (c *Cache) Get(ctx context.Context, key string) (string, error) {
	return c.Client.Get(ctx, key).Result()
}

// Set 设置缓存值
func (c *Cache) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return c.Client.Set(ctx, key, value, expiration).Err()
}

// Delete 删除缓存值
func (c *Cache) Delete(ctx context.Context, key string) error {
	return c.Client.Del(ctx, key).Err()
}

// Exists 检查键是否存在
func (c *Cache) Exists(ctx context.Context, key string) (bool, error) {
	result, err := c.Client.Exists(ctx, key).Result()
	if err != nil {
		return false, err
	}
	return result > 0, nil
}

// Incr 原子递增
func (c *Cache) Incr(ctx context.Context, key string) (int64, error) {
	return c.Client.Incr(ctx, key).Result()
}

// Decr 原子递减
func (c *Cache) Decr(ctx context.Context, key string) (int64, error) {
	return c.Client.Decr(ctx, key).Result()
}