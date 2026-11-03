package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/mishi-app/backend/internal/config"
	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/model"
	"github.com/rs/zerolog/log"
)

type AIOrchestrator struct {
	db         *database.DB
	store      *AIJobStore
	provider   AIProvider
	maxRetries int
}

func NewAIOrchestrator(db *database.DB, cfg config.AIConfig) (*AIOrchestrator, error) {
	provider, err := NewAIProvider(cfg)
	if err != nil {
		return nil, err
	}
	store := NewAIJobStore(db)
	if err := store.EnsureSchema(context.Background()); err != nil {
		return nil, fmt.Errorf("ensure ai_jobs schema failed: %w", err)
	}
	maxRetries := cfg.MaxRetries
	if maxRetries < 0 {
		maxRetries = 0
	}
	return &AIOrchestrator{
		db:         db,
		store:      store,
		provider:   provider,
		maxRetries: maxRetries,
	}, nil
}

func (o *AIOrchestrator) ProviderName() string {
	return o.provider.Name()
}

func (o *AIOrchestrator) CreateAndDispatch(
	ctx context.Context,
	userID int64,
	poemID int64,
	jobType model.AIJobType,
	inputPayload map[string]any,
) (*model.AIJob, error) {
	job, err := o.store.CreateJob(ctx, userID, poemID, jobType, o.provider.Name(), inputPayload)
	if err != nil {
		return nil, err
	}

	go func(jobID string) {
		runCtx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		defer cancel()
		if runErr := o.ProcessJob(runCtx, jobID); runErr != nil {
			log.Error().Err(runErr).Str("job_id", jobID).Msg("process ai job failed")
		}
	}(job.JobID)

	return job, nil
}

func (o *AIOrchestrator) GetJob(ctx context.Context, jobID string) (*model.AIJob, error) {
	return o.store.GetJobByJobID(ctx, jobID)
}

func (o *AIOrchestrator) GetLatestInterpretation(ctx context.Context, poemID int64) (*model.AIJob, error) {
	return o.store.GetLatestSuccessfulInterpretation(ctx, poemID)
}

func (o *AIOrchestrator) BuildStoryVideoPrompt(ctx context.Context, poemID int64, style string, seconds int) (string, error) {
	poem, err := o.getPoemMeta(ctx, poemID)
	if err != nil {
		return "", err
	}
	prompt := BuildPoetryVideoPrompt(poem.Title, poem.Author, poem.Dynasty, poem.Content, VideoPromptOptions{
		Seconds:          seconds,
		FPS:              24,
		VisualStyle:      style,
		SubtitleOnlyMode: true,
	})
	return prompt, nil
}

func (o *AIOrchestrator) ProcessJob(ctx context.Context, jobID string) error {
	job, err := o.store.GetJobByJobID(ctx, jobID)
	if err != nil {
		return err
	}
	if err = o.store.UpdateStatus(ctx, jobID, model.AIJobStatusRunning); err != nil {
		return err
	}

	var lastErr error
	if !o.provider.Capabilities().Supports(job.JobType) {
		lastErr = fmt.Errorf("%w: provider=%s job_type=%s", ErrAICapabilityNotSupported, o.provider.Name(), job.JobType)
		_ = o.store.MarkFailed(ctx, jobID, aiJobErrorCode(lastErr), truncateError(lastErr))
		return lastErr
	}
	for attempt := 0; attempt <= o.maxRetries; attempt++ {
		lastErr = o.executeJobOnce(ctx, job)
		if lastErr == nil {
			return nil
		}
		if errors.Is(lastErr, ErrAICapabilityNotSupported) || errors.Is(lastErr, ErrAIProviderNotConfigured) {
			break
		}
	}

	_ = o.store.MarkFailed(ctx, jobID, aiJobErrorCode(lastErr), truncateError(lastErr))
	return lastErr
}

func (o *AIOrchestrator) executeJobOnce(ctx context.Context, job *model.AIJob) error {
	poem, err := o.getPoemMeta(ctx, job.PoemID)
	if err != nil {
		return err
	}
	var payload map[string]any
	if len(job.InputPayload) > 0 {
		_ = json.Unmarshal(job.InputPayload, &payload)
	}

	switch job.JobType {
	case model.AIJobTypeInterpretation:
		style := anyString(payload["style"], "modern")
		res, callErr := o.provider.GenerateInterpretation(ctx, AIInterpretationRequest{
			Title:   poem.Title,
			Author:  poem.Author,
			Dynasty: poem.Dynasty,
			Content: poem.Content,
			Style:   style,
		})
		if callErr != nil {
			return callErr
		}
		return o.store.MarkSuccess(ctx, job.JobID, buildAIJobOutput(job.JobType, o.provider.Name(), res.Tokens, map[string]any{
			"text": res.Text,
		}, nil), res.Tokens)

	case model.AIJobTypeTTSReading:
		text := anyString(payload["text"], strings.Join(poem.Content, " "))
		voice := anyString(payload["voice"], "warm_female")
		style := anyString(payload["style"], "poetry")
		res, callErr := o.provider.GenerateTTS(ctx, AITTSRequest{
			Text:  text,
			Voice: voice,
			Style: style,
		})
		if callErr != nil {
			return callErr
		}
		return o.store.MarkSuccess(ctx, job.JobID, buildAIJobOutput(job.JobType, o.provider.Name(), res.Tokens, map[string]any{
			"audio_url": res.AudioURL,
			"duration":  res.Duration,
		}, map[string]any{
			"audio_url": res.AudioURL,
		}), res.Tokens)

	case model.AIJobTypeStoryVideo:
		style := anyString(payload["style"], "ink")
		seconds := anyInt(payload["seconds"], 15)
		videoPrompt := BuildPoetryVideoPrompt(poem.Title, poem.Author, poem.Dynasty, poem.Content, VideoPromptOptions{
			Seconds:          seconds,
			FPS:              24,
			VisualStyle:      style,
			SubtitleOnlyMode: true,
		})
		res, callErr := o.provider.GenerateStoryVideo(ctx, AIStoryVideoRequest{
			Title:   poem.Title,
			Content: poem.Content,
			Style:   style,
			Seconds: seconds,
			Prompt:  videoPrompt,
		})
		if callErr != nil {
			return callErr
		}
		return o.store.MarkSuccess(ctx, job.JobID, buildAIJobOutput(job.JobType, o.provider.Name(), res.Tokens, map[string]any{
			"video_url":     res.VideoURL,
			"thumbnail_url": res.ThumbnailURL,
			"video_prompt":  videoPrompt,
			"seconds":       seconds,
		}, map[string]any{
			"video_url":     res.VideoURL,
			"thumbnail_url": res.ThumbnailURL,
		}), res.Tokens)
	default:
		return fmt.Errorf("unknown job_type: %s", job.JobType)
	}
}

type poemMeta struct {
	Title   string
	Author  string
	Dynasty string
	Content []string
}

func (o *AIOrchestrator) getPoemMeta(ctx context.Context, poemID int64) (*poemMeta, error) {
	const q = `
SELECT title, author, dynasty, content
FROM poems
WHERE id = $1 AND status = 'published'
LIMIT 1
`
	var (
		meta       poemMeta
		contentRaw []byte
	)
	if err := o.db.Pool.QueryRow(ctx, q, poemID).Scan(&meta.Title, &meta.Author, &meta.Dynasty, &contentRaw); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("poem not found")
		}
		return nil, err
	}
	meta.Content = parsePoemContent(contentRaw)
	if len(meta.Content) == 0 {
		meta.Content = []string{meta.Title}
	}
	return &meta, nil
}

func parsePoemContent(raw []byte) []string {
	if len(raw) == 0 {
		return nil
	}
	var asStrings []string
	if err := json.Unmarshal(raw, &asStrings); err == nil && len(asStrings) > 0 {
		return asStrings
	}
	var asObjects []map[string]any
	if err := json.Unmarshal(raw, &asObjects); err == nil {
		out := make([]string, 0, len(asObjects))
		for _, item := range asObjects {
			if txt, ok := item["text"].(string); ok && strings.TrimSpace(txt) != "" {
				out = append(out, strings.TrimSpace(txt))
			}
		}
		return out
	}
	return nil
}

func anyString(v any, fallback string) string {
	s, ok := v.(string)
	if !ok || strings.TrimSpace(s) == "" {
		return fallback
	}
	return strings.TrimSpace(s)
}

func anyInt(v any, fallback int) int {
	switch vv := v.(type) {
	case int:
		if vv > 0 {
			return vv
		}
	case float64:
		if vv > 0 {
			return int(vv)
		}
	}
	return fallback
}

func buildAIJobOutput(jobType model.AIJobType, provider string, tokens int64, result map[string]any, artifacts map[string]any) map[string]any {
	if result == nil {
		result = map[string]any{}
	}
	if artifacts == nil {
		artifacts = map[string]any{}
	}
	output := map[string]any{
		"kind":      string(jobType),
		"job_type":  string(jobType),
		"provider":  provider,
		"status":    "success",
		"tokens":    tokens,
		"result":    result,
		"artifacts": artifacts,
	}
	for key, value := range result {
		output[key] = value
	}
	for key, value := range artifacts {
		output[key] = value
	}
	return output
}

func aiJobErrorCode(err error) int {
	switch {
	case errors.Is(err, ErrAICapabilityNotSupported):
		return 50101
	case errors.Is(err, ErrAIProviderNotConfigured):
		return 50102
	default:
		return 50001
	}
}

func truncateError(err error) string {
	if err == nil {
		return ""
	}
	msg := err.Error()
	if len(msg) > 500 {
		return msg[:500]
	}
	return msg
}
