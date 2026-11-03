package service

import (
	"context"

	"github.com/mishi-app/backend/internal/config"
)

type SeedDanceProvider struct {
	inner *OpenAIProvider
}

func NewSeedDanceProvider(global config.AIConfig, provider config.AIProviderConfig) *SeedDanceProvider {
	return &SeedDanceProvider{
		inner: NewOpenAIProvider(global, provider),
	}
}

func (p *SeedDanceProvider) Name() string { return "seeddance" }

func (p *SeedDanceProvider) Capabilities() AICapabilities {
	return AICapabilities{
		Interpretation: true,
		TTSReading:     false,
		StoryVideo:     false,
	}
}

func (p *SeedDanceProvider) GenerateInterpretation(ctx context.Context, req AIInterpretationRequest) (*AIInterpretationResult, error) {
	return p.inner.GenerateInterpretation(ctx, req)
}

func (p *SeedDanceProvider) GenerateTTS(ctx context.Context, req AITTSRequest) (*AITTSResult, error) {
	return nil, ErrAICapabilityNotSupported
}

func (p *SeedDanceProvider) GenerateStoryVideo(ctx context.Context, req AIStoryVideoRequest) (*AIStoryVideoResult, error) {
	return nil, ErrAICapabilityNotSupported
}
