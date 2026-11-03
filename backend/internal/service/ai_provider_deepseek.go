package service

import (
	"context"

	"github.com/mishi-app/backend/internal/config"
)

type DeepSeekProvider struct {
	inner *OpenAIProvider
}

func NewDeepSeekProvider(global config.AIConfig, provider config.AIProviderConfig) *DeepSeekProvider {
	return &DeepSeekProvider{
		inner: NewOpenAIProvider(global, provider),
	}
}

func (p *DeepSeekProvider) Name() string { return "deepseek" }

func (p *DeepSeekProvider) Capabilities() AICapabilities {
	return p.inner.Capabilities()
}

func (p *DeepSeekProvider) GenerateInterpretation(ctx context.Context, req AIInterpretationRequest) (*AIInterpretationResult, error) {
	return p.inner.GenerateInterpretation(ctx, req)
}

func (p *DeepSeekProvider) GenerateTTS(ctx context.Context, req AITTSRequest) (*AITTSResult, error) {
	return p.inner.GenerateTTS(ctx, req)
}

func (p *DeepSeekProvider) GenerateStoryVideo(ctx context.Context, req AIStoryVideoRequest) (*AIStoryVideoResult, error) {
	return p.inner.GenerateStoryVideo(ctx, req)
}
