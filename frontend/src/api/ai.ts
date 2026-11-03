import { apiClient } from './client';

export type AIJobType = 'interpretation' | 'tts_reading' | 'story_video';
export type AIJobStatus = 'pending' | 'queued' | 'running' | 'success' | 'succeeded' | 'failed';
export type AIJobFailureKind = 'unsupported' | 'provider_not_configured' | 'empty_result' | 'external_failure';
export type AIJobTerminalStatus = 'success' | 'failed';

export interface AIJobOutput {
  kind?: string;
  job_type?: AIJobType;
  provider?: string;
  status?: string;
  tokens?: number;
  text?: string;
  interpretation?: string;
  audio_url?: string;
  video_url?: string;
  thumbnail_url?: string;
  duration?: number;
  result?: Record<string, unknown>;
  artifacts?: Record<string, unknown>;
  [key: string]: unknown;
}

export interface CreateAIJobRequest {
  poem_id: number;
  job_type: AIJobType;
  style?: string;
  voice?: string;
  text?: string;
  seconds?: number;
}

export interface CreateAIJobResponse {
  job_id: string;
  job_type: AIJobType;
  status: AIJobStatus;
  provider: string;
  poem_id: number;
}

export interface AIJobResponse {
  job_id: string;
  job_type: AIJobType;
  status: AIJobStatus;
  provider: string;
  poem_id: number;
  output: AIJobOutput;
  error_code?: number;
  error_message?: string;
  created_at: string;
  updated_at: string;
  finished_at?: string;
}

export interface LatestInterpretationResponse {
  poem_id: number;
  provider: string;
  interpretation?: string;
  job_id: string;
  finished_at?: string;
}

export interface NormalizedAIJobResult {
  jobType: AIJobType;
  status: AIJobTerminalStatus;
  provider: string;
  errorCode?: number;
  errorMessage?: string;
  failureKind?: AIJobFailureKind;
  text: string;
  audioUrl: string;
  videoUrl: string;
  thumbnailUrl: string;
  durationSeconds?: number;
  rawOutput: AIJobOutput;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function pickString(...values: unknown[]): string {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
  }
  return '';
}

function pickNumber(...values: unknown[]): number | undefined {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
  }
  return undefined;
}

function normalizeStatus(status: AIJobStatus): AIJobTerminalStatus {
  return status === 'failed' ? 'failed' : 'success';
}

export function normalizeAIJobFailureKind(errorCode?: number, errorMessage?: string): AIJobFailureKind | undefined {
  if (errorCode === 50101) {
    return 'unsupported';
  }
  if (errorCode === 50102) {
    return 'provider_not_configured';
  }

  const message = (errorMessage ?? '').toLowerCase();
  if (message.includes('not configured') || message.includes('未配置')) {
    return 'provider_not_configured';
  }
  if (message.includes('unsupported') || message.includes('不支持')) {
    return 'unsupported';
  }

  return errorCode ? 'external_failure' : undefined;
}

export function extractAIJobResult(job: AIJobResponse): NormalizedAIJobResult {
  const output = job.output ?? {};
  const result = isRecord(output.result) ? output.result : {};
  const artifacts = isRecord(output.artifacts) ? output.artifacts : {};
  const normalizedStatus = normalizeStatus(job.status);

  const text = pickString(
    output.text,
    output.interpretation,
    result.text,
    result.interpretation,
    result.content,
    artifacts.text
  );
  const audioUrl = pickString(output.audio_url, result.audio_url, artifacts.audio_url, result.audioUrl, artifacts.audioUrl);
  const videoUrl = pickString(output.video_url, result.video_url, artifacts.video_url, result.videoUrl, artifacts.videoUrl);
  const thumbnailUrl = pickString(
    output.thumbnail_url,
    result.thumbnail_url,
    artifacts.thumbnail_url,
    result.thumbnailUrl,
    artifacts.thumbnailUrl
  );
  const durationSeconds = pickNumber(output.duration, result.duration, artifacts.duration, result.duration_seconds, artifacts.duration_seconds);

  return {
    jobType: job.job_type,
    status: normalizedStatus,
    provider: job.provider,
    errorCode: job.error_code,
    errorMessage: job.error_message,
    failureKind: normalizeAIJobFailureKind(job.error_code, job.error_message),
    text,
    audioUrl,
    videoUrl,
    thumbnailUrl,
    durationSeconds,
    rawOutput: output,
  };
}

export async function createAIJob(req: CreateAIJobRequest): Promise<CreateAIJobResponse> {
  return apiClient.post('/ai/jobs', req);
}

export async function getAIJob(jobId: string): Promise<AIJobResponse> {
  return apiClient.get(`/ai/jobs/${jobId}`);
}

export async function getLatestAIInterpretation(poemId: number): Promise<LatestInterpretationResponse> {
  return apiClient.get(`/poems/${poemId}/interpretation/ai`);
}
