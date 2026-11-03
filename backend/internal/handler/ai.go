package handler

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/mishi-app/backend/internal/model"
	"github.com/mishi-app/backend/internal/service"
	"github.com/mishi-app/backend/pkg/response"
)

type createAIJobRequest struct {
	JobType string `json:"job_type" binding:"required"`
	PoemID  int64  `json:"poem_id" binding:"required"`
	Style   string `json:"style"`
	Voice   string `json:"voice"`
	Text    string `json:"text"`
	Seconds int    `json:"seconds"`
}

type buildVideoPromptRequest struct {
	PoemID  int64  `json:"poem_id" binding:"required"`
	Style   string `json:"style"`
	Seconds int    `json:"seconds"`
}

func CreateAIJob(orchestrator *service.AIOrchestrator) gin.HandlerFunc {
	return func(c *gin.Context) {
		if orchestrator == nil {
			response.ServiceUnavailable(c)
			return
		}
		userID, ok := getAuthUserID(c)
		if !ok {
			response.Unauthorized(c)
			return
		}

		var req createAIJobRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: job_type/poem_id 必填")
			return
		}
		jobType := normalizeJobType(req.JobType)
		if jobType == "" {
			response.BadRequest(c, "参数错误: 不支持的 job_type")
			return
		}
		if req.PoemID <= 0 {
			response.BadRequest(c, "参数错误: poem_id 非法")
			return
		}

		input := map[string]any{
			"style":   req.Style,
			"voice":   req.Voice,
			"text":    req.Text,
			"seconds": req.Seconds,
		}
		job, err := orchestrator.CreateAndDispatch(c.Request.Context(), userID, req.PoemID, jobType, input)
		if err != nil {
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"job_id":   job.JobID,
			"job_type": job.JobType,
			"status":   job.Status,
			"provider": job.Provider,
			"poem_id":  job.PoemID,
		})
	}
}

func GetAIJob(orchestrator *service.AIOrchestrator) gin.HandlerFunc {
	return func(c *gin.Context) {
		if orchestrator == nil {
			response.ServiceUnavailable(c)
			return
		}
		userID, ok := getAuthUserID(c)
		if !ok {
			response.Unauthorized(c)
			return
		}
		jobID := strings.TrimSpace(c.Param("job_id"))
		if jobID == "" {
			response.BadRequest(c, "参数错误: job_id 非法")
			return
		}

		job, err := orchestrator.GetJob(c.Request.Context(), jobID)
		if err != nil {
			if err == pgx.ErrNoRows {
				response.NotFound(c)
				return
			}
			response.InternalServerError(c)
			return
		}
		if job.UserID != userID {
			response.Forbidden(c)
			return
		}

		output := map[string]any{}
		if len(job.OutputPayload) > 0 {
			_ = json.Unmarshal(job.OutputPayload, &output)
		}

		response.Success(c, gin.H{
			"job_id":        job.JobID,
			"job_type":      job.JobType,
			"status":        job.Status,
			"provider":      job.Provider,
			"poem_id":       job.PoemID,
			"output":        output,
			"error_code":    job.ErrorCode,
			"error_message": job.ErrorMessage,
			"cost_tokens":   job.CostTokens,
			"cost_credits":  job.CostCredits,
			"created_at":    job.CreatedAt,
			"updated_at":    job.UpdatedAt,
			"finished_at":   job.FinishedAt,
		})
	}
}

func GetLatestAIPoemInterpretation(orchestrator *service.AIOrchestrator) gin.HandlerFunc {
	return func(c *gin.Context) {
		if orchestrator == nil {
			response.ServiceUnavailable(c)
			return
		}
		poemID, err := strconv.ParseInt(c.Param("id"), 10, 64)
		if err != nil || poemID <= 0 {
			response.BadRequest(c, "参数错误: poem_id 非法")
			return
		}

		job, err := orchestrator.GetLatestInterpretation(c.Request.Context(), poemID)
		if err != nil {
			if err == pgx.ErrNoRows {
				response.NotFound(c)
				return
			}
			response.InternalServerError(c)
			return
		}
		output := map[string]any{}
		if len(job.OutputPayload) > 0 {
			_ = json.Unmarshal(job.OutputPayload, &output)
		}
		interpretation := output["text"]
		if interpretation == nil {
			if result, ok := output["result"].(map[string]any); ok {
				interpretation = result["text"]
			}
		}
		response.Success(c, gin.H{
			"poem_id":        poemID,
			"provider":       job.Provider,
			"interpretation": interpretation,
			"job_id":         job.JobID,
			"finished_at":    job.FinishedAt,
		})
	}
}

func BuildVideoPrompt(orchestrator *service.AIOrchestrator) gin.HandlerFunc {
	return func(c *gin.Context) {
		if orchestrator == nil {
			response.ServiceUnavailable(c)
			return
		}
		if _, ok := getAuthUserID(c); !ok {
			response.Unauthorized(c)
			return
		}

		var req buildVideoPromptRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.BadRequest(c, "参数错误: poem_id 必填")
			return
		}
		if req.PoemID <= 0 {
			response.BadRequest(c, "参数错误: poem_id 非法")
			return
		}
		if req.Seconds <= 0 {
			req.Seconds = 10
		}

		prompt, err := orchestrator.BuildStoryVideoPrompt(c.Request.Context(), req.PoemID, req.Style, req.Seconds)
		if err != nil {
			if err == pgx.ErrNoRows {
				response.NotFound(c)
				return
			}
			response.InternalServerError(c)
			return
		}

		response.Success(c, gin.H{
			"poem_id":      req.PoemID,
			"seconds":      req.Seconds,
			"style":        req.Style,
			"video_prompt": prompt,
		})
	}
}

func normalizeJobType(raw string) model.AIJobType {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case string(model.AIJobTypeInterpretation):
		return model.AIJobTypeInterpretation
	case string(model.AIJobTypeTTSReading), "tts", "audio":
		return model.AIJobTypeTTSReading
	case string(model.AIJobTypeStoryVideo), "video":
		return model.AIJobTypeStoryVideo
	default:
		return ""
	}
}
