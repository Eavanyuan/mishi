package service

import (
	"context"
	"crypto/rand"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/model"
)

type AIJobStore struct {
	db *database.DB
}

func NewAIJobStore(db *database.DB) *AIJobStore {
	return &AIJobStore{db: db}
}

func (s *AIJobStore) EnsureSchema(ctx context.Context) error {
	// Keep this DDL aligned with backend/migrations/0001_ai_jobs_baseline.up.sql.
	const q = `
CREATE TABLE IF NOT EXISTS ai_jobs (
    id BIGSERIAL PRIMARY KEY,
    job_id VARCHAR(64) UNIQUE NOT NULL,
    job_type VARCHAR(32) NOT NULL,
    provider VARCHAR(32) NOT NULL,
    status VARCHAR(16) NOT NULL,
    user_id BIGINT NOT NULL,
    poem_id BIGINT NOT NULL,
    input_hash VARCHAR(40) NOT NULL,
    input_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_payload JSONB,
    error_code INT DEFAULT 0,
    error_message TEXT DEFAULT '',
    cost_tokens BIGINT DEFAULT 0,
    cost_credits BIGINT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_status_created_at ON ai_jobs(status, created_at);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_user_created_at ON ai_jobs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_poem_type_provider_hash ON ai_jobs(poem_id, job_type, provider, input_hash);
`
	_, err := s.db.Pool.Exec(ctx, q)
	return err
}

func (s *AIJobStore) CreateJob(
	ctx context.Context,
	userID int64,
	poemID int64,
	jobType model.AIJobType,
	provider string,
	inputPayload map[string]any,
) (*model.AIJob, error) {
	rawInput, err := json.Marshal(inputPayload)
	if err != nil {
		return nil, err
	}
	inputHash := hashJobInput(jobType, provider, poemID, rawInput)
	jobID, err := newJobID()
	if err != nil {
		return nil, err
	}

	const q = `
INSERT INTO ai_jobs (job_id, job_type, provider, status, user_id, poem_id, input_hash, input_payload)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id, created_at, updated_at
`
	var (
		id        int64
		createdAt time.Time
		updatedAt time.Time
	)
	if err := s.db.Pool.QueryRow(
		ctx,
		q,
		jobID,
		jobType,
		provider,
		model.AIJobStatusPending,
		userID,
		poemID,
		inputHash,
		rawInput,
	).Scan(&id, &createdAt, &updatedAt); err != nil {
		return nil, err
	}

	return &model.AIJob{
		ID:           id,
		JobID:        jobID,
		JobType:      jobType,
		Provider:     provider,
		Status:       model.AIJobStatusPending,
		UserID:       userID,
		PoemID:       poemID,
		InputHash:    inputHash,
		InputPayload: rawInput,
		CreatedAt:    createdAt,
		UpdatedAt:    updatedAt,
	}, nil
}

func (s *AIJobStore) GetJobByJobID(ctx context.Context, jobID string) (*model.AIJob, error) {
	const q = `
SELECT id, job_id, job_type, provider, status, user_id, poem_id, input_hash, input_payload,
       output_payload, error_code, error_message, cost_tokens, cost_credits, created_at, updated_at, finished_at
FROM ai_jobs
WHERE job_id = $1
LIMIT 1
`
	var (
		job        model.AIJob
		jobType    string
		status     string
		outputRaw  []byte
		finishedAt *time.Time
	)
	err := s.db.Pool.QueryRow(ctx, q, jobID).Scan(
		&job.ID,
		&job.JobID,
		&jobType,
		&job.Provider,
		&status,
		&job.UserID,
		&job.PoemID,
		&job.InputHash,
		&job.InputPayload,
		&outputRaw,
		&job.ErrorCode,
		&job.ErrorMessage,
		&job.CostTokens,
		&job.CostCredits,
		&job.CreatedAt,
		&job.UpdatedAt,
		&finishedAt,
	)
	if err != nil {
		return nil, err
	}
	job.JobType = model.AIJobType(jobType)
	job.Status = model.AIJobStatus(status)
	if len(outputRaw) > 0 {
		job.OutputPayload = outputRaw
	}
	job.FinishedAt = finishedAt
	return &job, nil
}

func (s *AIJobStore) UpdateStatus(ctx context.Context, jobID string, status model.AIJobStatus) error {
	const q = `
UPDATE ai_jobs
SET status = $2, updated_at = NOW()
WHERE job_id = $1
`
	_, err := s.db.Pool.Exec(ctx, q, jobID, status)
	return err
}

func (s *AIJobStore) MarkSuccess(
	ctx context.Context,
	jobID string,
	output map[string]any,
	costTokens int64,
) error {
	raw, err := json.Marshal(output)
	if err != nil {
		return err
	}
	const q = `
UPDATE ai_jobs
SET status = 'success',
    output_payload = $2,
    cost_tokens = $3,
    updated_at = NOW(),
    finished_at = NOW()
WHERE job_id = $1
`
	_, err = s.db.Pool.Exec(ctx, q, jobID, raw, costTokens)
	return err
}

func (s *AIJobStore) MarkFailed(ctx context.Context, jobID string, code int, message string) error {
	const q = `
UPDATE ai_jobs
SET status = 'failed',
    error_code = $2,
    error_message = $3,
    updated_at = NOW(),
    finished_at = NOW()
WHERE job_id = $1
`
	_, err := s.db.Pool.Exec(ctx, q, jobID, code, message)
	return err
}

func (s *AIJobStore) GetLatestSuccessfulInterpretation(ctx context.Context, poemID int64) (*model.AIJob, error) {
	const q = `
SELECT id, job_id, job_type, provider, status, user_id, poem_id, input_hash, input_payload,
       output_payload, error_code, error_message, cost_tokens, cost_credits, created_at, updated_at, finished_at
FROM ai_jobs
WHERE poem_id = $1 AND job_type = 'interpretation' AND status = 'success'
ORDER BY finished_at DESC NULLS LAST, id DESC
LIMIT 1
`
	var (
		job        model.AIJob
		jobType    string
		status     string
		outputRaw  []byte
		finishedAt *time.Time
	)
	err := s.db.Pool.QueryRow(ctx, q, poemID).Scan(
		&job.ID,
		&job.JobID,
		&jobType,
		&job.Provider,
		&status,
		&job.UserID,
		&job.PoemID,
		&job.InputHash,
		&job.InputPayload,
		&outputRaw,
		&job.ErrorCode,
		&job.ErrorMessage,
		&job.CostTokens,
		&job.CostCredits,
		&job.CreatedAt,
		&job.UpdatedAt,
		&finishedAt,
	)
	if err != nil {
		return nil, err
	}
	job.JobType = model.AIJobType(jobType)
	job.Status = model.AIJobStatus(status)
	job.OutputPayload = outputRaw
	job.FinishedAt = finishedAt
	return &job, nil
}

func hashJobInput(jobType model.AIJobType, provider string, poemID int64, raw []byte) string {
	sum := sha1.Sum([]byte(fmt.Sprintf("%s|%s|%d|%s", jobType, provider, poemID, string(raw))))
	return hex.EncodeToString(sum[:])
}

func newJobID() (string, error) {
	buf := make([]byte, 12)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return "aj_" + hex.EncodeToString(buf), nil
}
