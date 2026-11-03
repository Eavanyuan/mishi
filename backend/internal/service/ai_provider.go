package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/mishi-app/backend/internal/config"
	"github.com/mishi-app/backend/internal/model"
)

var (
	ErrAICapabilityNotSupported = errors.New("ai capability not supported")
	ErrAIProviderNotConfigured  = errors.New("ai provider not configured")
)

type AIInterpretationRequest struct {
	Title   string
	Author  string
	Dynasty string
	Content []string
	Style   string
}

type AIInterpretationResult struct {
	Text   string
	Tokens int64
}

type AITTSRequest struct {
	Text  string
	Voice string
	Style string
}

type AITTSResult struct {
	AudioURL string
	Duration int
	Tokens   int64
}

type AIStoryVideoRequest struct {
	Title   string
	Content []string
	Style   string
	Seconds int
	Prompt  string
}

type AIStoryVideoResult struct {
	VideoURL     string
	ThumbnailURL string
	Tokens       int64
}

type AICapabilities struct {
	Interpretation bool
	TTSReading     bool
	StoryVideo     bool
}

func (c AICapabilities) Supports(jobType model.AIJobType) bool {
	switch jobType {
	case model.AIJobTypeInterpretation:
		return c.Interpretation
	case model.AIJobTypeTTSReading:
		return c.TTSReading
	case model.AIJobTypeStoryVideo:
		return c.StoryVideo
	default:
		return false
	}
}

type AIProvider interface {
	Name() string
	Capabilities() AICapabilities
	GenerateInterpretation(ctx context.Context, req AIInterpretationRequest) (*AIInterpretationResult, error)
	GenerateTTS(ctx context.Context, req AITTSRequest) (*AITTSResult, error)
	GenerateStoryVideo(ctx context.Context, req AIStoryVideoRequest) (*AIStoryVideoResult, error)
}

func NewAIProvider(cfg config.AIConfig) (AIProvider, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.Provider)) {
	case "", "openai":
		return NewOpenAIProvider(cfg, cfg.OpenAI), nil
	case "deepseek":
		return NewDeepSeekProvider(cfg, cfg.DeepSeek), nil
	case "seeddance", "seeddance2.0", "seeddance2":
		return NewSeedDanceProvider(cfg, cfg.SeedDance), nil
	default:
		return nil, fmt.Errorf("unknown ai provider: %s", cfg.Provider)
	}
}

type aiProviderBase struct {
	global   config.AIConfig
	provider config.AIProviderConfig
	timeout  time.Duration
}

func newAIProviderBase(global config.AIConfig, provider config.AIProviderConfig) aiProviderBase {
	timeoutSeconds := global.TimeoutSeconds
	if timeoutSeconds <= 0 {
		timeoutSeconds = 30
	}
	return aiProviderBase{
		global:   global,
		provider: provider,
		timeout:  time.Duration(timeoutSeconds) * time.Second,
	}
}

func (b aiProviderBase) hasAPIKey() bool {
	return strings.TrimSpace(b.provider.APIKey) != ""
}
