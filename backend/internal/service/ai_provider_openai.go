package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/mishi-app/backend/internal/config"
)

type OpenAIProvider struct {
	base aiProviderBase
}

func NewOpenAIProvider(global config.AIConfig, provider config.AIProviderConfig) *OpenAIProvider {
	return &OpenAIProvider{base: newAIProviderBase(global, provider)}
}

func (p *OpenAIProvider) Name() string { return "openai" }

func (p *OpenAIProvider) Capabilities() AICapabilities {
	return AICapabilities{
		Interpretation: true,
		TTSReading:     false,
		StoryVideo:     false,
	}
}

func (p *OpenAIProvider) GenerateInterpretation(ctx context.Context, req AIInterpretationRequest) (*AIInterpretationResult, error) {
	model := strings.TrimSpace(p.base.provider.LLMModel)
	if model == "" {
		model = "gpt-4o-mini"
	}
	if !p.base.hasAPIKey() {
		return nil, ErrAIProviderNotConfigured
	}

	baseURL := strings.TrimRight(strings.TrimSpace(p.base.provider.BaseURL), "/")
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}

	sysPrompt, userPrompt := buildInterpretationPrompts(req)

	payload := map[string]any{
		"model": model,
		"messages": []map[string]string{
			{"role": "system", "content": sysPrompt},
			{"role": "user", "content": userPrompt},
		},
		"temperature": 0.7,
	}

	var out struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
		Usage struct {
			TotalTokens int64 `json:"total_tokens"`
		} `json:"usage"`
	}

	if err := p.postJSON(ctx, baseURL+"/chat/completions", payload, &out); err != nil {
		return nil, err
	}
	if len(out.Choices) == 0 || strings.TrimSpace(out.Choices[0].Message.Content) == "" {
		return nil, fmt.Errorf("empty interpretation response")
	}
	return &AIInterpretationResult{
		Text:   strings.TrimSpace(out.Choices[0].Message.Content),
		Tokens: out.Usage.TotalTokens,
	}, nil
}

func (p *OpenAIProvider) GenerateTTS(ctx context.Context, req AITTSRequest) (*AITTSResult, error) {
	return nil, ErrAICapabilityNotSupported
}

func (p *OpenAIProvider) GenerateStoryVideo(ctx context.Context, req AIStoryVideoRequest) (*AIStoryVideoResult, error) {
	return nil, ErrAICapabilityNotSupported
}

func (p *OpenAIProvider) postJSON(ctx context.Context, url string, body any, out any) error {
	data, err := json.Marshal(body)
	if err != nil {
		return err
	}
	reqCtx, cancel := context.WithTimeout(ctx, p.base.timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(reqCtx, http.MethodPost, url, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+p.base.provider.APIKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return fmt.Errorf("provider http %d: %s", resp.StatusCode, string(raw))
	}
	if err := json.Unmarshal(raw, out); err != nil {
		return fmt.Errorf("decode provider response failed: %w", err)
	}
	return nil
}

func buildInterpretationPrompts(req AIInterpretationRequest) (string, string) {
	sysPrompt := "你是古诗词现代转述助手。必须输出中文，忠于原意，禁止虚构史实。"
	userPrompt := fmt.Sprintf(
		`请将下面古诗词转为“结构化现代解读”，严格按以下版式输出纯文本：
【逐句白话】
1. ...
2. ...

【现代文（80-120字）】
...

【典故/意象说明】
- ...
- ...

规则：
1) 忠于原意，不添加原作没有的事实；
2) 若典故不确定，明确写“常见解读/可能指向”，不要断言；
3) 语言简洁，适配移动端阅读；
4) 风格偏好：%s。

标题：%s
作者：%s（%s）
正文：
%s`,
		strings.TrimSpace(req.Style),
		req.Title,
		req.Author,
		req.Dynasty,
		formatPoemLines(req.Content),
	)
	return sysPrompt, userPrompt
}

func formatPoemLines(lines []string) string {
	if len(lines) == 0 {
		return "（无正文）"
	}
	out := make([]string, 0, len(lines))
	for i, line := range lines {
		text := strings.TrimSpace(line)
		if text == "" {
			continue
		}
		out = append(out, strconv.Itoa(i+1)+". "+text)
	}
	if len(out) == 0 {
		return "（无正文）"
	}
	return strings.Join(out, "\n")
}
