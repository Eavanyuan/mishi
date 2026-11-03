-- Baseline migration for ai_jobs.
-- Keep this file aligned with backend/internal/service/ai_job_store.go.

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
