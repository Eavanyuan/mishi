package server

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mishi-app/backend/internal/cache"
	"github.com/mishi-app/backend/internal/config"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/handler"
	"github.com/mishi-app/backend/internal/service"
	"github.com/mishi-app/backend/pkg/middleware"
	"github.com/rs/zerolog/log"
)

type Server struct {
	config *config.Config
	router *gin.Engine
	server *http.Server
	db     *database.DB
	cache  *cache.Cache
}

func New(cfg *config.Config) (*Server, error) {
	// 设置Gin模式
	gin.SetMode(cfg.Server.Mode)

	// 初始化数据库
	db, err := database.New(cfg.Database)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	redisCache, err := cache.New(cfg.Redis)
	if err != nil {
		log.Warn().Err(err).Msg("Redis unavailable, continue without cache")
		redisCache = nil
	}

	// 初始化路由
	router := gin.New()
	var mailer service.MailSender
	var aiOrchestrator *service.AIOrchestrator
	if smtpMailer, err := service.NewSMTPMailer(cfg.Email); err == nil {
		mailer = smtpMailer
	} else {
		log.Warn().Err(err).Msg("SMTP mailer disabled")
	}
	if orchestrator, err := service.NewAIOrchestrator(db, cfg.AI); err == nil {
		aiOrchestrator = orchestrator
	} else {
		log.Warn().Err(err).Msg("AI orchestrator disabled")
	}
	jwtSvc := service.NewJWTService(cfg.JWT)

	setupRouter(router, db, redisCache, mailer, jwtSvc, aiOrchestrator)

	return &Server{
		config: cfg,
		router: router,
		db:     db,
		cache:  redisCache,
	}, nil
}

func setupRouter(
	router *gin.Engine,
	db *database.DB,
	redisCache *cache.Cache,
	mailer service.MailSender,
	jwtSvc *service.JWTService,
	aiOrchestrator *service.AIOrchestrator,
) {
	// 全局中间件
	router.Use(
		middleware.Logger(),
		middleware.Recovery(),
		middleware.CORS(),
		middleware.RequestID(),
		middleware.Timestamp(),
	)

	// 健康检查
	router.GET("/health", handler.HealthCheck(db, redisCache))

	// API v1 路由分组
	v1 := router.Group("/v1")
	{
		// 系统接口
		system := v1.Group("/system")
		{
			system.GET("/ping", handler.Ping)
			// 后续添加其他系统接口
		}

		// 地理服务
		geo := v1.Group("/geo")
		{
			geo.GET("/nearby", handler.GeoNearby(db))
			// 后续添加其他地理接口
		}

		// 诗词服务
		poems := v1.Group("/poems")
		{
			poems.GET("/recommend", handler.RecommendPoems(db))
			poems.GET("/search", handler.SearchPoems(db))
			poems.GET("/:id", handler.GetPoem(db))
			poems.GET("/:id/interpretation/ai", handler.GetLatestAIPoemInterpretation(aiOrchestrator))
			// 后续添加其他诗词接口
		}

		// 打卡服务
		checkins := v1.Group("/checkins")
		checkins.Use(middleware.AuthRequired(jwtSvc))
		{
			checkins.POST("/", handler.CreateCheckin(db))
			checkins.GET("/history", handler.GetCheckinHistory(db))
			// 后续添加其他打卡接口
		}

		// 认证服务
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handler.Register(db, jwtSvc))
			auth.POST("/login", handler.Login(db, jwtSvc))
			auth.POST("/sms/send-code", handler.SendSMSCode(redisCache))
			auth.POST("/sms/login", handler.SMSLogin(db, jwtSvc, redisCache))
			auth.POST("/refresh", handler.RefreshToken(db, jwtSvc))
			auth.POST("/logout", middleware.AuthRequired(jwtSvc), handler.Logout)
			auth.POST("/forgot-password", handler.ForgotPassword(db, mailer, redisCache))
			auth.POST("/reset-password", handler.ResetPassword(db, redisCache))
			// 后续添加其他认证接口
		}

		// 用户资料
		profile := v1.Group("/profile")
		profile.Use(middleware.AuthRequired(jwtSvc))
		{
			profile.GET("/:id", handler.GetProfile(db))
			// 后续添加其他用户资料接口
		}

		ai := v1.Group("/ai")
		ai.Use(middleware.AuthRequired(jwtSvc))
		{
			ai.POST("/jobs", handler.CreateAIJob(aiOrchestrator))
			ai.GET("/jobs/:job_id", handler.GetAIJob(aiOrchestrator))
			ai.POST("/video-prompts", handler.BuildVideoPrompt(aiOrchestrator))
		}
	}
}

func (s *Server) Start() error {
	s.server = &http.Server{
		Addr:           s.config.Server.Address,
		Handler:        s.router,
		ReadTimeout:    time.Duration(s.config.Server.ReadTimeout) * time.Second,
		WriteTimeout:   time.Duration(s.config.Server.WriteTimeout) * time.Second,
		MaxHeaderBytes: 1 << 20, // 1MB
	}

	log.Info().Str("address", s.config.Server.Address).Msg("Server starting")
	return s.server.ListenAndServe()
}

func (s *Server) Shutdown(ctx context.Context) error {
	// 关闭数据库连接
	if s.db != nil {
		s.db.Close()
	}
	if s.cache != nil {
		_ = s.cache.Close()
	}

	// 关闭HTTP服务器
	if s.server != nil {
		return s.server.Shutdown(ctx)
	}

	return nil
}
