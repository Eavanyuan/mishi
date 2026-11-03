# Mishi Launch Sprint Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不扩大需求面的前提下，把 Mishi 从“可演示”推进到“可稳定联调并具备上线准备”的状态，优先补齐 AI 真实链路、运行环境、密钥治理、数据库迁移与发布规范。

**Architecture:** 维持当前 `Go backend + React Web + Flutter App + PostgreSQL/Redis` 架构，不做大规模重构；通过四条相对独立的冲刺战线，把运行时依赖、AI provider 能力、配置安全和数据库交付流程收敛到可验证、可重复、可交接的状态。执行上采用“总控协调 + 分战线 agent 并行推进 + 统一验收”的方式。

**Tech Stack:** Go, Gin, pgx/PostgreSQL, Redis, React/Vite/TypeScript, Flutter/Riverpod, Docker Compose, SQL seed scripts

---

## Sprint Scope

本轮只做四项：

1. AI TTS/视频真实化
2. 运行环境收敛与服务可启动
3. 密钥治理与配置安全
4. 数据库 migration / seed / 发布规范

不纳入本轮：

1. 新增业务页面或大范围 UI 改版
2. 推荐算法重写
3. 大规模架构升级或微服务拆分

## Exit Criteria

冲刺完成时需要同时满足：

1. 后端能在标准方式下稳定启动，并通过健康检查。
2. Web 与 Flutter 能连到同一套后端完成核心主流程联调。
3. AI 解读、TTS、视频生成链路的“真实能力 / 降级能力 / 禁用提示”边界清晰且可验证。
4. 仓库中不再保留明文生产密钥，配置来源和覆盖优先级明确。
5. 数据库初始化、迁移、seed、回滚与发布步骤有统一入口和文档。

## Workstreams

### Workstream A: AI TTS/视频真实化

**Owner:** AI Agent

**Goal:** 让 AI 解读、TTS、视频三类能力具备可预期的运行结果，至少做到“真实调用或显式降级”，不能停留在静默 mock。

**Expected Outputs:**

1. Provider 能力矩阵与真实/降级路径说明。
2. TTS 与视频 job 的最小可上线实现。
3. Web/Flutter 对 AI job 成功、失败、能力不支持三种状态的统一呈现。
4. 对应测试与验收命令。

**Primary Files:**

1. `backend/internal/service/ai_provider_openai.go`
2. `backend/internal/service/ai_provider_deepseek.go`
3. `backend/internal/service/ai_provider_seeddance.go`
4. `backend/internal/service/ai_orchestrator.go`
5. `backend/internal/handler/*.go`
6. `frontend/src/pages/PoemDetail/index.tsx`
7. `mishi_app/lib/features/poem_detail/pages/poem_detail_page.dart`

**Acceptance:**

1. 未配置能力时，接口返回显式可读错误，不冒充真实资源。
2. 已配置能力时，AI job 可落到成功状态并产出真实可消费字段。
3. Web/Flutter 对 job 失败和 unsupported 状态有可见反馈。

### Workstream B: 运行环境收敛与服务可启动

**Owner:** Runtime Agent

**Goal:** 把“依赖靠记忆启动”变成“按文档或脚本一键启动”，保证本地和预发布环境都能稳定拉起。

**Expected Outputs:**

1. 标准启动入口与依赖检查脚本。
2. PostgreSQL/Redis/Backend 的统一启动说明或 compose 编排。
3. 健康检查与最小联调检查脚本。
4. 故障定位说明。

**Primary Files:**

1. `backend/config.yaml`
2. `backend/.env.example`
3. `backend/docker-compose.yml`
4. `backend/Makefile`
5. `backend/scripts/*`
6. `backend/README.md`

**Acceptance:**

1. 新环境按文档准备后能拉起后端。
2. `/health` 可返回正常状态。
3. 核心 API 至少能通过一轮 smoke test。

### Workstream C: 密钥治理与配置安全

**Owner:** Security Agent

**Goal:** 清理仓库内敏感信息暴露，明确所有运行配置的来源、优先级和注入方式。

**Expected Outputs:**

1. 敏感信息排查清单。
2. 配置优先级与覆盖规则说明。
3. `.env.example` / `config.yaml` / README 的安全化改造。
4. 密钥轮换建议。

**Primary Files:**

1. `backend/config.yaml`
2. `backend/.env`
3. `backend/.env.example`
4. `backend/README.md`
5. `frontend/README.md`
6. `mishi_app` 环境配置相关文件

**Acceptance:**

1. 仓库中无明文真实 API key。
2. 所有敏感配置均可通过环境变量注入。
3. README 明确开发、测试、生产配置边界。

### Workstream D: 数据库 migration / seed / 发布规范

**Owner:** Data Agent

**Goal:** 让数据库变更与初始化从“单个 SQL 文件”升级为“可迁移、可回放、可发布”的标准流程。

**Expected Outputs:**

1. migration 目录与命名规范。
2. schema 初始化、seed 导入、环境升级的标准步骤。
3. 数据初始化脚本与说明。
4. 发布/回滚检查清单。

**Primary Files:**

1. `sql/init-database-v1.sql`
2. `sql/seeds/*`
3. `backend/migrations/*`
4. `backend/docker-compose.yml`
5. `backend/README.md`
6. `backend/scripts/*`

**Acceptance:**

1. 新库可从零初始化到可运行状态。
2. 既有库可按 migration 升级。
3. seed 数据可重复导入且行为可预期。

## Coordination Model

### Coordinator

总控负责：

1. 维护总任务板与依赖顺序。
2. 把共享前提先收敛，再放行并行任务。
3. 统一验收、统一回归、统一发布说明。

### Shared Dependency Order

推荐执行顺序：

1. 先做 Workstream C，避免继续把真实密钥写进仓库。
2. 再做 Workstream B，保证服务可启动。
3. 然后并行推进 Workstream A 与 D。
4. 最后做一次端到端联调和发布演练。

## Task Breakdown

### Phase 1: Freeze Scope And Safety Guard

1. 记录本轮冲刺边界，不再新增业务功能。
2. 清点当前脏工作区，避免误覆盖用户现有修改。
3. 标记所有共享文件，避免多个 agent 同时编辑同一文件。

### Phase 2: Prepare Runtime Baseline

1. 确认 PostgreSQL/Redis 启动方式和连接参数。
2. 确认后端配置加载顺序与默认值。
3. 补齐最小启动脚本和健康检查脚本。
4. 形成“从零启动”文档。

### Phase 3: Secure Configuration

1. 移除仓库内明文密钥。
2. 把敏感配置迁移到环境变量。
3. 校正文档与示例配置。
4. 形成密钥轮换说明。

### Phase 4: Standardize Database Delivery

1. 建立 migration 目录与执行规范。
2. 拆分 schema 初始化与 seed 数据。
3. 增加可重复执行的数据库初始化入口。
4. 形成发布与回滚清单。

### Phase 5: Realize AI Capability Paths

1. 定义 provider 能力矩阵。
2. 真实实现支持的能力。
3. 对不支持的能力返回明确错误与前端提示。
4. 为 Web/Flutter 补齐 AI job 状态反馈。

### Phase 6: Final Verification

1. 运行后端测试。
2. 运行 Web 构建与关键流程验证。
3. 运行 Flutter analyze/test。
4. 进行一次后端健康检查和核心 API smoke test。
5. 输出上线准备报告。

## Agent Assignment

1. `Coordinator Agent`
   负责总控、依赖排序、验收口径、最终联调。
2. `AI Agent`
   负责 Workstream A，仅修改 AI provider / orchestrator / AI 消费端相关文件。
3. `Runtime Agent`
   负责 Workstream B，仅修改启动脚本、配置说明、compose/Makefile/README。
4. `Security Agent`
   负责 Workstream C，仅修改配置模板、文档和安全相关加载逻辑。
5. `Data Agent`
   负责 Workstream D，仅修改 migration、seed、数据库初始化脚本与文档。

## Verification Commands

1. `cd backend && go test ./...`
2. `cd frontend && npm run build`
3. `cd mishi_app && export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890 FVM_CACHE_PATH=/Users/yuanyuan/Documents/workspace/mishi/.fvm_cache && fvm flutter analyze`
4. `cd mishi_app && export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890 FVM_CACHE_PATH=/Users/yuanyuan/Documents/workspace/mishi/.fvm_cache && fvm flutter test`

## Notes

1. 当前仓库工作区较脏，执行前要先确认每个 agent 的写入边界。
2. 共享文件优先由 Coordinator 串行整合，避免并行冲突。
3. 子 agent 返回后，需要把每条战线细化成具体 implementation tickets。

## Executable Tickets

### Priority P0

1. `SEC-001` 轮换并移除仓库中的真实 AI key 与其他明文敏感值。
2. `SEC-002` 收敛后端配置优先级，明确 `.env` 使用方式，禁止弱默认 secret 静默兜底。
3. `RUN-001` 修复 PostgreSQL/Redis/Backend 启动链，保证后端在标准环境下可启动。
4. `RUN-002` 修复 Docker healthcheck、启动等待与本机/容器双模式配置差异。

### Priority P1

1. `DB-001` 建立 baseline migration，替代“单文件全量初始化即迁移”的当前模式。
2. `DB-002` 拆分基础 seed 与专题 seed，消除执行顺序依赖。
3. `AI-001` 建立 provider capability matrix，明确 LLM/TTS/Video 支持边界。
4. `AI-002` 打通至少一条真实 TTS/Video 生成链路，停止用 mock URL 冒充成功。

### Priority P2

1. `AI-003` 统一 `ai_jobs` 输出结构、失败码和展示语义。
2. `WEB-001` 补齐 Web 端 AI job 成功/失败/unsupported 三态体验。
3. `APP-001` 补齐 Flutter 端 AI 结果回填、视频入口与持久展示。
4. `QA-001` 建立 clean-env smoke test 与上线前回归清单。

## Dispatch Board

### Coordinator Agent

**Scope:** 总控、依赖管理、冲刺看板、最终验收

**Tickets:**

1. `COORD-001` 维护本计划文档和共享任务板，冻结本轮范围。
2. `COORD-002` 标记共享文件所有权，避免多 agent 并发改同一文件。
3. `COORD-003` 汇总各 agent PR/补丁，组织统一验证。
4. `COORD-004` 更新发布说明与最终上线准备报告。

**Deliverables:**

1. `docs/plans/2026-04-15-launch-sprint-plan.md`
2. `collab/90_release/release-plan.md`
3. 上线准备报告

### Security Agent

**Scope:** 密钥治理、配置安全、环境注入

**Tickets:**

1. `SEC-001` 清理 [backend/config.yaml](/Users/yuanyuan/Documents/workspace/mishi/backend/config.yaml) 中的真实密钥与敏感默认值。
2. `SEC-002` 修正 [backend/.env.example](/Users/yuanyuan/Documents/workspace/mishi/backend/.env.example) 与 README，使敏感配置全部走环境变量。
3. `SEC-003` 审核并移除 Web/脚本中的演示账号密码与硬编码测试口令。
4. `SEC-004` 为后端增加“非测试环境缺少关键 secret 就 fail fast”的规则。
5. `SEC-005` 输出密钥轮换与注入规范。

**Primary Files:**

1. [backend/config.yaml](/Users/yuanyuan/Documents/workspace/mishi/backend/config.yaml)
2. [backend/.env.example](/Users/yuanyuan/Documents/workspace/mishi/backend/.env.example)
3. [backend/internal/config/config.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/config/config.go)
4. [backend/internal/service/jwt_service.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/jwt_service.go)
5. [backend/internal/service/email_service.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/email_service.go)
6. [frontend/src/components/layout/Header.tsx](/Users/yuanyuan/Documents/workspace/mishi/frontend/src/components/layout/Header.tsx)
7. [mishi_app/lib/shared/constants/app_constants.dart](/Users/yuanyuan/Documents/workspace/mishi/mishi_app/lib/shared/constants/app_constants.dart)

**Acceptance:**

1. `rg -n "sk-|change-me-in-production|mishi_password|123456|demo@mishi.app"` 不再命中真实敏感值。
2. 生产敏感配置全部由环境变量注入。
3. 缺少关键 secret 时服务显式失败，不静默回退。

### Runtime Agent

**Scope:** 可启动性、容器编排、健康检查、脚本收敛

**Tickets:**

1. `RUN-001` 修复 [backend/docker-compose.yml](/Users/yuanyuan/Documents/workspace/mishi/backend/docker-compose.yml) 的 backend healthcheck 与依赖等待。
2. `RUN-002` 修复 [backend/Dockerfile](/Users/yuanyuan/Documents/workspace/mishi/backend/Dockerfile) 运行镜像工具缺失问题。
3. `RUN-003` 统一本机 `make run` 与容器模式的数据库/Redis 配置入口。
4. `RUN-004` 升级 [backend/scripts/init.sh](/Users/yuanyuan/Documents/workspace/mishi/backend/scripts/init.sh) / [backend/scripts/e2e-web.sh](/Users/yuanyuan/Documents/workspace/mishi/backend/scripts/e2e-web.sh) / [backend/Makefile](/Users/yuanyuan/Documents/workspace/mishi/backend/Makefile) 为标准启动链。
5. `RUN-005` 建立 `/health` 与 smoke check 的最小验收脚本。

**Primary Files:**

1. [backend/docker-compose.yml](/Users/yuanyuan/Documents/workspace/mishi/backend/docker-compose.yml)
2. [backend/Dockerfile](/Users/yuanyuan/Documents/workspace/mishi/backend/Dockerfile)
3. [backend/Makefile](/Users/yuanyuan/Documents/workspace/mishi/backend/Makefile)
4. [backend/scripts/init.sh](/Users/yuanyuan/Documents/workspace/mishi/backend/scripts/init.sh)
5. [backend/scripts/e2e-web.sh](/Users/yuanyuan/Documents/workspace/mishi/backend/scripts/e2e-web.sh)
6. [backend/README.md](/Users/yuanyuan/Documents/workspace/mishi/backend/README.md)

**Acceptance:**

1. `make docker-up` 后 PostgreSQL、Redis、Backend 全部 healthy。
2. `make run` 在 localhost 配置下可稳定启动。
3. `curl /health` 返回可用状态。

### Data Agent

**Scope:** migration、seed、数据库初始化与发布规范

**Tickets:**

1. `DB-001` 在 [backend/migrations](/Users/yuanyuan/Documents/workspace/mishi/backend/migrations) 建立 baseline migration 结构。
2. `DB-002` 把 `sql/init-database-v1.sql` 拆分为 schema baseline 与可重复 seed。
3. `DB-003` 把 `ai_jobs` schema 纳入 migration，不再仅靠应用启动时补表。
4. `DB-004` 规范专题 seed 的顺序和幂等行为，消除重叠诗词覆盖不确定性。
5. `DB-005` 定义新库初始化、存量库升级、seed 导入、回滚四条标准路径。

**Primary Files:**

1. [sql/init-database-v1.sql](/Users/yuanyuan/Documents/workspace/mishi/sql/init-database-v1.sql)
2. [sql/seeds/2026-03-25-yangzhou-hot-poems.sql](/Users/yuanyuan/Documents/workspace/mishi/sql/seeds/2026-03-25-yangzhou-hot-poems.sql)
3. [sql/seeds/2026-03-25-yangzhou-spring-hot-poems.sql](/Users/yuanyuan/Documents/workspace/mishi/sql/seeds/2026-03-25-yangzhou-spring-hot-poems.sql)
4. [backend/migrations](/Users/yuanyuan/Documents/workspace/mishi/backend/migrations)
5. [backend/README.md](/Users/yuanyuan/Documents/workspace/mishi/backend/README.md)

**Acceptance:**

1. 新空库可一键初始化。
2. 存量库可通过 migration 升级。
3. 专题 seed 可重复执行且结果一致。

### AI Backend Agent

**Scope:** AI provider、orchestrator、job schema、视频 prompt

**Tickets:**

1. `AI-001` 在 [backend/internal/service/ai_provider.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_provider.go) 建立能力矩阵。
2. `AI-002` 为至少一个 provider 打通真实 TTS。
3. `AI-003` 为至少一个 provider 打通真实视频生成，或输出清晰可消费的异步任务结果。
4. `AI-004` 统一 [backend/internal/service/ai_orchestrator.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_orchestrator.go) 的失败码、输出 payload 与重试语义。
5. `AI-005` 升级 [backend/internal/service/video_prompt_builder.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/video_prompt_builder.go) 为时间轴稳定提示词模板。

**Primary Files:**

1. [backend/internal/service/ai_provider.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_provider.go)
2. [backend/internal/service/ai_provider_openai.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_provider_openai.go)
3. [backend/internal/service/ai_provider_deepseek.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_provider_deepseek.go)
4. [backend/internal/service/ai_provider_seeddance.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_provider_seeddance.go)
5. [backend/internal/service/ai_orchestrator.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_orchestrator.go)
6. [backend/internal/service/ai_job_store.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/ai_job_store.go)
7. [backend/internal/service/video_prompt_builder.go](/Users/yuanyuan/Documents/workspace/mishi/backend/internal/service/video_prompt_builder.go)

**Acceptance:**

1. 有真实 key 时，`interpretation` / `tts_reading` / `story_video` 都能形成真实结果或明确失败。
2. 不支持的 provider 不再返回 mock URL。
3. `ai_jobs` 记录可用于排障与运营查看。

### Web Agent

**Scope:** Web 端 AI 体验、失败态、历史回填

**Tickets:**

1. `WEB-001` 升级 [frontend/src/pages/PoemDetail/index.tsx](/Users/yuanyuan/Documents/workspace/mishi/frontend/src/pages/PoemDetail/index.tsx) 的 AI job 状态流。
2. `WEB-002` 为音频、视频、解读分别补齐成功态和失败态展示。
3. `WEB-003` 补 latest AI interpretation / 媒体结果回填逻辑。
4. `WEB-004` 保证 unsupported / timeout / provider error 的文案可读。

**Acceptance:**

1. 详情页可稳定显示 AI 解读、AI 音频、AI 视频结果。
2. AI 失败时不会只剩通用报错。

### Flutter Agent

**Scope:** Flutter 端 AI 结果展示、回填、媒体入口

**Tickets:**

1. `APP-001` 升级 [poem_detail_page.dart](/Users/yuanyuan/Documents/workspace/mishi/mishi_app/lib/features/poem_detail/pages/poem_detail_page.dart) 的 AI job 完成态展示。
2. `APP-002` 补 AI 解读历史回填，不再只在当前交互态可见。
3. `APP-003` 补视频结果入口与失败态。
4. `APP-004` 统一音频播放器、轮询反馈和异常提示。

**Acceptance:**

1. Flutter 详情页能稳定消费 AI job 结果。
2. 页面重进后仍可看到最近生成结果。

### QA Agent

**Scope:** smoke test、clean-env 验证、上线前回归

**Tickets:**

1. `QA-001` 从干净环境验证 `docker-up -> health -> smoke`。
2. `QA-002` 回归认证、首页推荐、详情、打卡、AI 任务三条链路。
3. `QA-003` 验证不再出现 mock 音频/视频 URL。
4. `QA-004` 形成上线前检查单和证据记录。

**Acceptance:**

1. 全量验证命令可重复执行。
2. 报告里能明确指出剩余 blocker 与非 blocker。

## Recommended Execution Order

1. `Security Agent` 先做 `SEC-001` 到 `SEC-004`
2. `Runtime Agent` 并行做 `RUN-001` 到 `RUN-004`
3. `Data Agent` 在运行环境稳定后推进 `DB-001` 到 `DB-005`
4. `AI Backend Agent` 在配置安全与迁移基线稳定后推进 `AI-001` 到 `AI-005`
5. `Web Agent` 和 `Flutter Agent` 在 AI 输出 schema 稳定后并行推进
6. `QA Agent` 最后做统一 smoke 与回归

## Hand-off Prompts

可直接发给各 agent 的一句话任务：

1. `Security Agent`: “清理仓库中的明文密钥和弱默认值，收敛为环境变量注入，并让缺失关键 secret 时显式失败。”  
2. `Runtime Agent`: “把 PostgreSQL/Redis/Backend 的本机与容器启动链统一起来，修复 healthcheck 和启动竞态，让 `make docker-up` 与 `make run` 都稳定可用。”  
3. `Data Agent`: “建立 baseline migration，拆分 schema 与 seed，定义新库初始化、存量升级、seed 导入、回滚四条标准路径。”  
4. `AI Backend Agent`: “建立 provider capability matrix，并打通至少一条真实 TTS/视频生成链路，统一 ai_jobs 输出和错误语义。”  
5. `Web Agent`: “补齐诗词详情页 AI 结果的成功态、失败态、回填和媒体展示。”  
6. `Flutter Agent`: “补齐诗词详情页 AI 结果回填、视频入口、音频体验和异常提示。”  
7. `QA Agent`: “从干净环境做启动、健康检查、核心流程、AI 结果真实性的 smoke 与回归验证。”  
