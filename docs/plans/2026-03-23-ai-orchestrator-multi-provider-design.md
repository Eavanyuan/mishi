# AI 编排与多厂商兼容设计（OpenAI / DeepSeek / SeedDance）

## 1. 目标与范围

本设计面向 mishi 项目新增三类 AI 能力并支持全局厂商切换：

1. 诗词 AI 解读（文本生成）
2. AI 诗词诵读（TTS 音频生成）
3. 诗词故事动画（视频生成）

采用异步任务编排（B2），以提升稳定性、可观测性与成本可控性。

## 2. 关键决策

1. 厂商切换方式：全局配置切换（环境变量）
2. 编排模式：统一 AI Orchestrator + Provider Adapter
3. 交互模式：异步任务（创建任务返回 job_id，客户端轮询状态）
4. 扩展策略：新增厂商只需新增 adapter，不改业务 handler

## 3. 系统架构

### 3.1 模块分层

1. API Handler 层：创建任务、查询任务状态、读取最新成功结果
2. Orchestrator 层：统一参数、调用 provider、状态推进、重试
3. Provider Adapter 层：OpenAI/DeepSeek/SeedDance 的协议适配
4. Repository 层：`ai_jobs` 持久化与查询

### 3.2 核心接口（内部）

`AIProvider`：

1. `GenerateInterpretation(ctx, req)`
2. `GenerateTTS(ctx, req)`
3. `GenerateStoryVideo(ctx, req)`

`ProviderFactory` 根据 `MISHI_AI_PROVIDER` 返回实现。

## 4. 数据设计

新增 `ai_jobs` 表（通用任务表）：

1. `job_id`（唯一）
2. `job_type`：`interpretation|tts_reading|story_video`
3. `provider`：`openai|deepseek|seeddance`
4. `status`：`pending|running|success|failed`
5. `user_id`、`poem_id`
6. `input_payload`、`output_payload`（JSONB）
7. `input_hash`（去重）
8. `error_code`、`error_message`
9. `cost_tokens`、`cost_credits`
10. `created_at`、`updated_at`、`finished_at`

索引：

1. `job_id` 唯一索引
2. `status + created_at`（worker 拉取）
3. `poem_id + job_type + provider + input_hash`（缓存命中）

## 5. API 设计

### 5.1 统一任务接口

1. `POST /v1/ai/jobs`
2. `GET /v1/ai/jobs/:job_id`
3. `GET /v1/poems/:id/interpretation/ai`（读取最新成功）

### 5.2 兼容接口（可选）

保留 `POST /v1/video/jobs`，内部转发为 `job_type=story_video`。

## 6. 配置设计

全局主配置：

1. `MISHI_AI_PROVIDER=openai|deepseek|seeddance`
2. `MISHI_AI_TIMEOUT_SECONDS`
3. `MISHI_AI_MAX_RETRIES`

厂商配置：

1. OpenAI：`MISHI_OPENAI_API_KEY`、`MISHI_OPENAI_BASE_URL`、模型配置
2. DeepSeek：`MISHI_DEEPSEEK_API_KEY`、`MISHI_DEEPSEEK_BASE_URL`、模型配置
3. SeedDance：`MISHI_SEEDDANCE_API_KEY`、`MISHI_SEEDDANCE_BASE_URL`、模型配置

## 7. 失败与降级策略

1. 非幂等能力禁自动重试（视频提交），幂等能力允许有限重试
2. 厂商能力不支持返回标准错误码（`501xx`）
3. 默认不自动跨厂商降级（可配置）
4. 超时、频控、配额耗尽均可观测落库

## 8. 安全与成本

1. API Key 仅环境变量注入
2. Prompt 长度限制 + 基础内容安全过滤
3. 日配额与速率限制（按 user + job_type）
4. 成本指标写入 `ai_jobs`，支持后续审计与运营分析

## 9. Flutter 集成

1. 详情页新增 AI 入口：解读、诵读、故事动画
2. 创建任务后轮询 `GET /v1/ai/jobs/:job_id`
3. `success` 后分别渲染文本、音频 URL、视频 URL

## 10. MVP 边界

本期只实现：

1. 后端异步任务编排最小闭环
2. OpenAI 实际可用 + DeepSeek/SeedDance 适配骨架
3. Flutter 端基础调用与展示

V2 再补：

1. 推送通知回调
2. 更细粒度成本治理与缓存策略
3. 多厂商动态路由（请求级）
