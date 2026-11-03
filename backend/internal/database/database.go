package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mishi-app/backend/internal/config"
	"github.com/rs/zerolog/log"
)

// DB 封装数据库连接池和相关操作
type DB struct {
	Pool *pgxpool.Pool
}

// New 创建新的数据库连接池
func New(cfg config.DatabaseConfig) (*DB, error) {
	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		cfg.User,
		cfg.Password,
		cfg.Host,
		cfg.Port,
		cfg.DBName,
		cfg.SSLMode,
	)

	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	poolConfig.MaxConns = int32(cfg.MaxConns)
	poolConfig.MinConns = 2
	poolConfig.MaxConnLifetime = time.Hour
	poolConfig.MaxConnIdleTime = time.Minute * 30
	poolConfig.HealthCheckPeriod = time.Minute

	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Info().Str("host", cfg.Host).Int("port", cfg.Port).Str("database", cfg.DBName).Msg("Database connected")

	return &DB{Pool: pool}, nil
}

// Close 关闭数据库连接池
func (db *DB) Close() {
	if db.Pool != nil {
		db.Pool.Close()
		log.Info().Msg("Database connection closed")
	}
}

// HealthCheck 检查数据库连接状态
func (db *DB) HealthCheck(ctx context.Context) error {
	if db.Pool == nil {
		return fmt.Errorf("database pool is nil")
	}

	if err := db.Pool.Ping(ctx); err != nil {
		return fmt.Errorf("database ping failed: %w", err)
	}

	return nil
}

// Stats 返回数据库连接池统计信息
func (db *DB) Stats() string {
	if db.Pool == nil {
		return "database pool is nil"
	}

	stats := db.Pool.Stat()
	return fmt.Sprintf(
		"TotalConns: %d, IdleConns: %d, MaxConns: %d",
		stats.TotalConns(),
		stats.IdleConns(),
		stats.MaxConns(),
	)
}