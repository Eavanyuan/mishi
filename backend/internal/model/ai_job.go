package model

import (
	"encoding/json"
	"time"
)

type AIJobType string

const (
	AIJobTypeInterpretation AIJobType = "interpretation"
	AIJobTypeTTSReading     AIJobType = "tts_reading"
	AIJobTypeStoryVideo     AIJobType = "story_video"
)

type AIJobStatus string

const (
	AIJobStatusPending AIJobStatus = "pending"
	AIJobStatusRunning AIJobStatus = "running"
	AIJobStatusSuccess AIJobStatus = "success"
	AIJobStatusFailed  AIJobStatus = "failed"
)

type AIJob struct {
	ID            int64           `json:"id"`
	JobID         string          `json:"job_id"`
	JobType       AIJobType       `json:"job_type"`
	Provider      string          `json:"provider"`
	Status        AIJobStatus     `json:"status"`
	UserID        int64           `json:"user_id"`
	PoemID        int64           `json:"poem_id"`
	InputHash     string          `json:"input_hash"`
	InputPayload  json.RawMessage `json:"input_payload,omitempty"`
	OutputPayload json.RawMessage `json:"output_payload,omitempty"`
	ErrorCode     int             `json:"error_code,omitempty"`
	ErrorMessage  string          `json:"error_message,omitempty"`
	CostTokens    int64           `json:"cost_tokens,omitempty"`
	CostCredits   int64           `json:"cost_credits,omitempty"`
	CreatedAt     time.Time       `json:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at"`
	FinishedAt    *time.Time      `json:"finished_at,omitempty"`
}
