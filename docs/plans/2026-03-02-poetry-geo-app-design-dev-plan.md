# 古诗词地理沉浸式 App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 16 周内上线一款“到地触发古诗词推荐 + 季节场景匹配 + 旅行地诗词打卡 + 权威解读 + 语音朗读 + 可选 AI 场景动画”的 iOS/Android App（MVP+增强）。

**Architecture:** 采用“移动端 + API 网关 + 领域服务 + AI 编排层 + 地理能力层 + 内容审核后台”的分层架构。先以模块化单体快速上线 MVP，再按流量将推荐、媒体、AI 生成拆分为独立服务。

**Tech Stack:** Flutter、Go/Java（后端）、PostgreSQL+PostGIS、Redis、Elasticsearch、对象存储+CDN、消息队列（Kafka/RabbitMQ）、高德/腾讯地图 SDK、LLM/TTS/视频生成 API。

---

### Task 1: 项目初始化与范围冻结（第 1 周）

**Files:**
- Create: `planning/01_scope_mvp.md`
- Create: `planning/02_success_metrics.md`
- Create: `planning/03_risk_register.md`
- Create: `planning/04_team_raci.md`

**Step 1: 明确 MVP 边界（必须可交付）**
- 功能包含：定位触发、季节匹配推荐、旅行地打卡、诗词详情、故事解读、语音朗读、收藏、基础后台。
- 功能排除：社交关系链、复杂 AR、UGC 审核社区。

**Step 2: 明确量化目标（上线后 30 天）**
- 地理触发命中率 `>=85%`
- 触发卡片点击率 `>=25%`
- 音频播放完成率 `>=40%`
- 季节匹配推荐点击率 `>=30%`
- 到地打卡转化率 `>=20%`
- 崩溃率 `<0.5%`

**Step 3: 建立风险台账并分配责任人**
- 地名映射误命中
- AI 生成耗时和成本失控
- 内容版权和合规风险

**Step 4: 评审并冻结范围**
- 参会角色：产品、设计、客户端、后端、测试、运维、内容运营。

---

### Task 2: 产品与交互设计（第 1-3 周）

**Files:**
- Create: `design/product_prd_v1.md`
- Create: `design/information_architecture.md`
- Create: `design/wireframes_mobile.md`
- Create: `design/ui_spec_tokens.md`
- Create: `design/prototype_link.md`

**Step 1: 产出 PRD v1**
- 用户主流程：到地触发 -> 季节加权推荐卡 -> 阅读解读 -> 朗读/动画 -> 一键打卡 -> 分享。

**Step 2: 设计信息架构与页面清单**
- 页面：启动页、首页地图、附近诗词、诗词详情、播放页、旅行打卡页、旅行路线页、个人中心、设置。

**Step 3: 输出高保真稿与设计规范**
- 视觉：黛青/米白/朱砂色系。
- 字体：标题宋体风格、正文高可读字体。
- 组件：卡片、底部导航、浮层播放器、状态反馈。

**Step 4: 可用性评审（5 名目标用户）**
- 目标：首次完成“到地体验诗词”任务时长 < 90 秒。

---

### Task 3: 技术架构与环境建设（第 2-4 周）

**Files:**
- Create: `architecture/system_context.md`
- Create: `architecture/service_boundaries.md`
- Create: `architecture/api_contracts_v1.yaml`
- Create: `architecture/deployment_topology.md`
- Create: `devops/environments.md`

**Step 1: 定义服务边界**
- `content-service`：诗词/作者/解读/故事。
- `geo-service`：围栏、逆地理、古今地名映射。
- `recommend-service`：规则+召回排序。
- `ai-orchestrator`：LLM/TTS/视频生成编排。
- `media-service`：音视频存储转码分发。

**Step 2: 定义 API 合约（先契约后开发）**
- OpenAPI 输出核心接口：`/geo/nearby`、`/poems/recommend`、`/poems/{id}`、`/audio/{id}`、`/video/jobs`。

**Step 3: 建立环境与发布链路**
- 环境：dev / staging / prod。
- 流水线：CI（单测+lint）-> CD（灰度发布）。

**Step 4: 安全基线**
- 鉴权：JWT + Refresh Token。
- 审计：内容与 AI 请求日志留痕。

---

### Task 4: 数据模型与内容中台（第 3-6 周）

**Files:**
- Create: `backend/db/schema_poems.sql`
- Create: `backend/db/schema_geo_history.sql`
- Create: `backend/db/schema_user_events.sql`
- Create: `backend/cms/content_workflow.md`
- Create: `backend/cms/source_attribution_rules.md`

**Step 1: 设计核心数据表**
- 诗词表、作者表、解读表、故事表、人物表。
- 地点表、古今地名映射表（含时间范围与置信度）。
- 季节标签表、地点季节推荐权重表、用户打卡记录表、旅行路线表。

**Step 2: 建设内容审核流程**
- 流程：录入 -> 一审 -> 二审 -> 发布。
- 强制字段：来源、版本、版权声明。

**Step 3: 导入首批内容**
- 首批：300 首诗词，覆盖北京/西安/杭州重点地点。

**Step 4: 建立检索索引**
- Elasticsearch 建立诗词全文与地名别名索引。

---

### Task 5: 客户端 MVP 开发（第 4-10 周）

**Files:**
- Create: `mobile/lib/features/home/`
- Create: `mobile/lib/features/poem_detail/`
- Create: `mobile/lib/features/player/`
- Create: `mobile/lib/features/profile/`
- Create: `mobile/lib/core/location/`
- Create: `mobile/test/`

**Step 1: 搭建基础工程与导航框架**
- 完成路由、主题、网络层、错误处理框架。

**Step 2: 实现定位与到地触发**
- 接入地图 SDK，支持前后台定位与地理围栏触发。

**Step 3: 实现首页地图 + 推荐卡片**
- 展示当前位置与附近诗词点位，并增加季节标签与打卡入口。

**Step 4: 实现详情页与朗读播放器**
- 诗词正文、解读、背景、季节提示、音频播放、收藏分享。

**Step 5: 埋点与稳定性增强**
- 关键行为埋点：曝光、点击、播放、收藏、分享、打卡、路线完成。

---

### Task 6: 后端 MVP 开发（第 4-10 周）

**Files:**
- Create: `backend/services/content-service/`
- Create: `backend/services/geo-service/`
- Create: `backend/services/recommend-service/`
- Create: `backend/services/media-service/`
- Create: `backend/gateway/`
- Create: `backend/tests/`

**Step 1: 完成内容服务接口**
- 诗词详情、作者信息、解读内容、多版本文本返回。

**Step 2: 完成地理服务接口**
- 附近点位查询、古今地名匹配、命中置信度回传。

**Step 3: 完成推荐服务（规则版）**
- 规则：距离优先 + 热度加权 + 时间段匹配 + 季节因子匹配。

**Step 4: 完成媒体服务**
- 音频 URL 鉴权下发、CDN 缓存策略、播放统计回收。

**Step 5: 完成打卡与路线服务**
- 打卡记录写入、打卡卡片生成、城市路线进度统计与接口下发。

---

### Task 7: AI 能力接入（第 8-12 周）

**Files:**
- Create: `backend/services/ai-orchestrator/`
- Create: `backend/services/ai-orchestrator/prompt_templates.md`
- Create: `backend/services/ai-orchestrator/policy_guardrails.md`
- Create: `mobile/lib/features/ai_video/`

**Step 1: 接入 TTS（优先上线）**
- 预生成热门诗词音频，长尾按需生成并缓存。

**Step 2: 接入 AI 动画（可选开关）**
- 采用异步任务：提交 -> 排队 -> 回调 -> 展示。

**Step 3: 建立内容安全策略**
- 提示词模板固定化 + 敏感词过滤 + 人审兜底。

**Step 4: 建立成本控制策略**
- 每用户每日视频生成限额；失败重试上限；超时熔断。

---

### Task 8: 测试、灰度、上线（第 11-16 周）

**Files:**
- Create: `qa/test_plan_mvp.md`
- Create: `qa/test_cases_geo_ai.md`
- Create: `release/release_checklist.md`
- Create: `release/rollback_plan.md`
- Create: `ops/monitoring_dashboard_spec.md`

**Step 1: 测试执行**
- 功能测试、兼容性测试、弱网测试、定位漂移测试、压测。

**Step 2: 预发布灰度**
- 灰度 5% -> 20% -> 50% -> 100%。
- 关键观察项：崩溃率、触发命中率、响应时延。

**Step 3: 正式发布**
- 应用商店上架、内容活动联动、异常值班排班。

**Step 4: 发布后两周复盘**
- 产出 `release/postmortem_mvp.md`，决定 P1/P2 排期。

---

## 里程碑（Milestones）
- M1（第 2 周末）：PRD/交互/视觉规范冻结。
- M2（第 4 周末）：技术架构与 API 契约冻结。
- M3（第 8 周末）：客户端与后端 MVP 联调通过。
- M4（第 12 周末）：AI 能力联调完成，进入灰度。
- M5（第 16 周末）：正式上线，完成首轮复盘。

## 人员配置建议（最小可行团队）
- 产品经理 1
- 设计师 1
- 客户端工程师 2
- 后端工程师 3（含 1 名地理/检索方向）
- 测试工程师 1-2
- DevOps 1（可兼职）
- 内容运营/编辑 2

## 风险与应对
1. 地理误命中：
- 应对：多信号融合（坐标+地名+行政区）+ 低置信度二次确认。
2. AI 成本超预算：
- 应对：默认关闭视频自动生成、限额、缓存复用、热点预生成。
3. 内容权威性争议：
- 应对：来源可追溯、双审流程、版本化发布与纠错机制。
4. 合规风险：
- 应对：版权审查、内容安全策略、日志审计、未成年人保护开关。

## 验收标准（MVP）
- 功能验收：到地触发、季节标签推荐、旅行打卡、详情阅读、语音播放、收藏分享全部可用。
- 性能验收：核心接口 P95 < 300ms（不含 AI 生成）。
- 稳定性验收：7 天线上崩溃率 < 0.5%。
- 业务验收：核心指标达到 Task 1 设定阈值。
