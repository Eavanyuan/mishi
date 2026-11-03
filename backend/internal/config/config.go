package config

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	Redis    RedisConfig    `mapstructure:"redis"`
	Email    EmailConfig    `mapstructure:"email"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	AI       AIConfig       `mapstructure:"ai"`
	Log      LogConfig      `mapstructure:"log"`
}

type ServerConfig struct {
	Address      string `mapstructure:"address"`
	Mode         string `mapstructure:"mode"`
	ReadTimeout  int    `mapstructure:"read_timeout"`
	WriteTimeout int    `mapstructure:"write_timeout"`
}

type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	DBName   string `mapstructure:"dbname"`
	SSLMode  string `mapstructure:"sslmode"`
	MaxConns int    `mapstructure:"max_conns"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type LogConfig struct {
	Level  string `mapstructure:"level"`
	Format string `mapstructure:"format"`
}

type EmailConfig struct {
	Host        string `mapstructure:"host"`
	Port        int    `mapstructure:"port"`
	Username    string `mapstructure:"username"`
	Password    string `mapstructure:"password"`
	FromAddress string `mapstructure:"from_address"`
	FromName    string `mapstructure:"from_name"`
	ResetURL    string `mapstructure:"reset_url"`
}

type JWTConfig struct {
	Secret           string `mapstructure:"secret"`
	AccessTTLMinutes int    `mapstructure:"access_ttl_minutes"`
	RefreshTTLDays   int    `mapstructure:"refresh_ttl_days"`
	Issuer           string `mapstructure:"issuer"`
}

type AIConfig struct {
	Provider       string `mapstructure:"provider"`
	TimeoutSeconds int    `mapstructure:"timeout_seconds"`
	MaxRetries     int    `mapstructure:"max_retries"`

	OpenAI    AIProviderConfig `mapstructure:"openai"`
	DeepSeek  AIProviderConfig `mapstructure:"deepseek"`
	SeedDance AIProviderConfig `mapstructure:"seeddance"`
}

type AIProviderConfig struct {
	APIKey     string `mapstructure:"api_key"`
	BaseURL    string `mapstructure:"base_url"`
	LLMModel   string `mapstructure:"llm_model"`
	TTSModel   string `mapstructure:"tts_model"`
	VideoModel string `mapstructure:"video_model"`
}

// Load 加载配置，支持环境变量和配置文件
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("/etc/mishi")

	// 设置环境变量前缀
	viper.SetEnvPrefix("MISHI")
	viper.AutomaticEnv()
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))

	// 设置默认值
	setDefaults()

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	if err := validateConfig(&cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}

func validateConfig(cfg *Config) error {
	mode := strings.ToLower(strings.TrimSpace(cfg.Server.Mode))
	strictMode := mode != "debug" && mode != "test"

	if strings.TrimSpace(cfg.JWT.Secret) == "" {
		if strictMode {
			return fmt.Errorf("jwt.secret is required in %s mode", cfg.Server.Mode)
		}
		cfg.JWT.Secret = generateDevSecret()
	}

	return nil
}

func setDefaults() {
	// Server 默认值
	viper.SetDefault("server.address", ":8080")
	viper.SetDefault("server.mode", "debug")
	viper.SetDefault("server.read_timeout", 30)
	viper.SetDefault("server.write_timeout", 30)

	// Database 默认值
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)
	viper.SetDefault("database.user", "mishi")
	viper.SetDefault("database.password", "")
	viper.SetDefault("database.dbname", "mishi")
	viper.SetDefault("database.sslmode", "disable")
	viper.SetDefault("database.max_conns", 20)

	// Redis 默认值
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", 6379)
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 0)

	// Log 默认值
	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")

	// Email 默认值
	viper.SetDefault("email.host", "")
	viper.SetDefault("email.port", 587)
	viper.SetDefault("email.username", "")
	viper.SetDefault("email.password", "")
	viper.SetDefault("email.from_address", "")
	viper.SetDefault("email.from_name", "Mishi")
	viper.SetDefault("email.reset_url", "")

	// JWT 默认值
	viper.SetDefault("jwt.secret", "")
	viper.SetDefault("jwt.access_ttl_minutes", 60)
	viper.SetDefault("jwt.refresh_ttl_days", 30)
	viper.SetDefault("jwt.issuer", "mishi-backend")

	// AI 默认值
	viper.SetDefault("ai.provider", "deepseek")
	viper.SetDefault("ai.timeout_seconds", 30)
	viper.SetDefault("ai.max_retries", 2)

	viper.SetDefault("ai.openai.api_key", "")
	viper.SetDefault("ai.openai.base_url", "https://api.openai.com/v1")
	viper.SetDefault("ai.openai.llm_model", "gpt-4o-mini")
	viper.SetDefault("ai.openai.tts_model", "gpt-4o-mini-tts")
	viper.SetDefault("ai.openai.video_model", "sora-2")

	viper.SetDefault("ai.deepseek.api_key", "")
	viper.SetDefault("ai.deepseek.base_url", "https://api.deepseek.com/v1")
	viper.SetDefault("ai.deepseek.llm_model", "deepseek-chat")
	viper.SetDefault("ai.deepseek.tts_model", "")
	viper.SetDefault("ai.deepseek.video_model", "")

	viper.SetDefault("ai.seeddance.api_key", "")
	viper.SetDefault("ai.seeddance.base_url", "")
	viper.SetDefault("ai.seeddance.llm_model", "seeddance2.0")
	viper.SetDefault("ai.seeddance.tts_model", "seeddance2.0-tts")
	viper.SetDefault("ai.seeddance.video_model", "seeddance2.0-video")
}

func generateDevSecret() string {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "dev-only-ephemeral-secret"
	}
	return base64.RawURLEncoding.EncodeToString(buf)
}
