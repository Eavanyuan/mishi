# AI Orchestrator Multi-Provider Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在现有 mishi 项目中实现可全局切换厂商的 AI 编排能力，支持诗词 AI 解读、AI 诵读、故事动画三类异步任务。

**Architecture:** 后端新增 `ai_jobs` 通用任务表与 `AIProvider` 适配层，通过 `MISHI_AI_PROVIDER` 全局切换 OpenAI/DeepSeek/SeedDance。API 层统一提供创建任务与查询任务状态接口；任务由服务层异步执行并回写结果。Flutter 端新增 AI 调用服务并在详情页接入任务发起与轮询展示。

**Tech Stack:** Go (Gin + pgx + viper), PostgreSQL JSONB, Flutter (Riverpod + Dio + just_audio)

---

### Task 1: 配置与模型基础设施

**Files:**
- Modify: `backend/internal/config/config.go`
- Modify: `backend/.env.example`
- Modify: `backend/config.yaml`
- Create: `backend/internal/model/ai_job.go`

**Step 1: 写配置字段测试或编译约束（最小）**

- 增加 `AIConfig` 与 provider 相关字段，确保 `Load()` 后可读取。

**Step 2: 运行编译检查**

Run: `cd backend && go test ./internal/config -run TestNonExistent -count=1`
Expected: 无测试但编译通过。

**Step 3: 实现配置与模型**

- 增加 `Config.AI`、默认值、环境变量映射。
- 新增 `AIJob`、`AIJobType`、`AIJobStatus`、结果结构体。

**Step 4: 运行格式化与编译**

Run: `cd backend && go test ./...`
Expected: 通过。

**Step 5: 提交（后续统一提交）**

- 本任务先不单独提交，待联调通过后合并提交。

### Task 2: Provider 抽象与工厂

**Files:**
- Create: `backend/internal/service/ai_provider.go`
- Create: `backend/internal/service/ai_provider_openai.go`
- Create: `backend/internal/service/ai_provider_deepseek.go`
- Create: `backend/internal/service/ai_provider_seeddance.go`

**Step 1: 先定义接口与请求响应结构**

- `GenerateInterpretation/GenerateTTS/GenerateStoryVideo`。

**Step 2: 跑编译确保接口可用**

Run: `cd backend && go test ./internal/service -run TestNonExistent -count=1`
Expected: 编译通过。

**Step 3: 实现 provider 工厂与三厂商适配**

- OpenAI/DeepSeek 走 OpenAI-Compatible chat 接口（解读）。
- TTS/Video 先给出统一实现路径与可配置 endpoint，若不可用返回标准不支持错误。
- SeedDance 提供适配骨架（至少可返回标准错误码）。

**Step 4: 运行 service 包测试/编译**

Run: `cd backend && go test ./internal/service -count=1`
Expected: 通过。

### Task 3: `ai_jobs` 存储与编排服务

**Files:**
- Create: `backend/internal/service/ai_job_store.go`
- Create: `backend/internal/service/ai_orchestrator.go`

**Step 1: 写失败用例（最小）**

- 针对 job 状态流转写单测草案：`pending -> running -> success/failed`。

**Step 2: 创建表与仓储方法**

- `EnsureSchema`
- `CreateJob`
- `GetJobByID`
- `UpdateStatus`
- `UpdateResult`
- `FindLatestSuccessfulInterpretation`

**Step 3: 实现 orchestrator 异步执行**

- 创建任务后 goroutine 异步处理。
- 处理重试与错误落库。

**Step 4: 运行测试**

Run: `cd backend && go test ./internal/service -count=1`
Expected: 通过。

### Task 4: 后端 API 接口接入

**Files:**
- Create: `backend/internal/handler/ai.go`
- Modify: `backend/internal/server/server.go`

**Step 1: 写 handler 单测骨架（可先编译约束）**

- 创建任务接口参数校验。

**Step 2: 实现路由与 handler**

- `POST /v1/ai/jobs`
- `GET /v1/ai/jobs/:job_id`
- `GET /v1/poems/:id/interpretation/ai`
- 接入鉴权。

**Step 3: 跑后端全量测试**

Run: `cd backend && go test ./...`
Expected: 全通过。

### Task 5: Flutter 端 AI 接入

**Files:**
- Create: `mishi_app/lib/models/ai_job.dart`
- Create: `mishi_app/lib/services/api/ai_service.dart`
- Modify: `mishi_app/lib/features/poem_detail/pages/poem_detail_page.dart`

**Step 1: 新增 AI service + model**

- `createJob` + `getJob` + 轮询辅助。

**Step 2: 详情页接入三个按钮**

- AI 解读：弹窗展示结果文本。
- AI 诵读：拿 `audio_url` 后用现有播放器播放。
- 故事动画：先展示 `video_url` 与状态（MVP）。

**Step 3: 跑 Flutter 检查**

Run: 
- `cd mishi_app && fvm flutter analyze`
- `cd mishi_app && fvm flutter test`
Expected: 全通过。

### Task 6: 文档与联调

**Files:**
- Modify: `backend/README.md`
- Modify: `mishi_app/README.md`（如存在）
- Modify: `memory/2026-03-23.md`

**Step 1: 更新环境变量与 API 文档**

- 增加 AI provider 配置说明。

**Step 2: 联调命令记录**

Run:
- `cd backend && go test ./...`
- `cd mishi_app && fvm flutter analyze`
- `cd mishi_app && fvm flutter test`

**Step 3: 总结已知限制**

- 不同 provider 的能力差异与降级说明。

