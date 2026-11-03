# 架构师首轮执行计划与 Scheduling Request

**文档版本**: v1.0  
**生成时间**: 2026-03-17 12:30  
**负责人**: Architect Agent  
**目标**: 评审当前依赖队列中的高风险任务，提供架构指导，并提交 Scheduling Request 以协调后续工作。

---

## 1. 基线架构回顾

已阅读以下基线文档：
- `architecture/overall_architecture_design_v1.md`
- `architecture/api_contracts_v1.yaml`
- `architecture/service_boundaries.md`
- `docs/agents/shared-workspace.md`
- `collab/handoff/dependency-queue.md`
- `collab/handoff/daily-sync.md`
- `collab/20_architecture/2026-03-17-risk-assessment-report.md`
- `collab/40_backend/2026-03-17-database-review-report.md`
- `collab/50_frontend/2026-03-17-flutter-api-fix-checklist.md`

总体架构设计清晰，服务边界明确，API 契约已定义。当前风险主要集中在数据库约束、配置错误和分区验证上。

---

## 2. 依赖队列任务评审

### 2.1 MISHI-001：数据库外键约束修复
- **所有者**: Backend Agent D012
- **状态**: todo
- **截止时间**: 2026-03-17 18:00
- **架构评审**:
  - 问题描述：checkins 表的 poi_id 和 poem_id 外键缺少 ON DELETE CASCADE，与 user_id 外键策略不一致。
  - 评审依据：数据库评审报告已提供具体 SQL 修复方案。
  - 架构符合性：修复方案符合数据库参照完整性最佳实践，与架构设计无冲突。
  - **建议**: 批准执行，要求在执行前备份数据，执行后验证删除操作。

### 2.2 MISHI-002：Flutter Base URL 修正
- **所有者**: App Agent D019
- **状态**: todo
- **截止时间**: 2026-03-17 14:00
- **架构评审**:
  - 问题描述：Flutter 项目中使用错误的 Base URL (`https://api.example.com/v1`)，导致无法连接正式环境。
  - 评审依据：Flutter API 修复检查清单显示 Base URL 已修正为 `https://api.mishi.app/v1`，但依赖队列状态仍为 todo。
  - 架构符合性：Base URL 应符合 API 契约中定义的服务器地址 (`https://api.mishi.app`)。
  - **建议**: 要求 App Agent 确认修复状态，更新依赖队列状态。同时建议实现多环境配置（dev/staging/prod）以避免未来类似问题。

### 2.3 MISHI-003：数据库分区扩展验证
- **所有者**: Backend Agent D012 + DevOps
- **状态**: todo
- **截止时间**: 2026-03-17 16:00
- **架构评审**:
  - 问题描述：user_events 表分区依赖 pg_cron 扩展，未确认 PostgreSQL 实例是否已安装该扩展。
  - 评审依据：风险评估报告指出该依赖可能导致分区功能不可用。
  - 架构符合性：分区策略是架构设计中可扩展性的重要部分，必须确保其可靠性。
  - **建议**:
    1. 立即检查 pg_cron 扩展可用性。
    2. 如果不可用，准备备选方案（系统 crontab 或外部调度器）。
    3. 验证分区维护脚本的正确性。
    4. 要求 DevOps 提供扩展安装或备选方案的实施计划。

### 2.4 MISHI-004：checkins 表唯一约束调整
- **所有者**: Backend Agent D012
- **状态**: todo
- **截止时间**: 2026-03-17 18:00
- **架构评审**:
  - 问题描述：checkins 表唯一约束精确到秒，与业务冷却期（3600秒）规则冲突。
  - 评审依据：数据库评审报告建议改为按小时去重（`date_trunc('hour', checkin_time)`）。
  - 架构符合性：调整后的约束与业务规则一致，同时保持数据完整性。
  - **建议**: 批准执行，要求验证调整后的约束不会影响现有合法数据。同时考虑在应用层加强冷却期校验。

### 2.5 MISHI-005：Flutter 核心服务层实现
- **所有者**: App Agent D019
- **状态**: todo
- **截止时间**: 2026-03-18 18:00
- **架构评审**:
  - 问题描述：Flutter 核心服务层尚未完全实现，需对接 API 契约。
  - 评审依据：Flutter API 修复检查清单列出了模型层和服务层的详细修复项。
  - 架构符合性：服务层实现必须严格遵循 API 契约，确保数据类型、错误处理与架构设计一致。
  - **建议**:
    1. 要求 App Agent 提供详细的设计方案，包括服务层接口定义、错误处理策略和缓存机制。
    2. 架构师将评审设计方案，确保其符合架构边界（如不将业务逻辑过度放在客户端）。
    3. 建议优先实现 GeoService 和 PoemService，因为它们支撑核心的到地推荐流程。

### 2.6 MISHI-006：前端项目结构完善
- **所有者**: Frontend Agent D011
- **状态**: todo
- **截止时间**: 2026-03-18 18:00
- **架构评审**:
  - 问题描述：前端项目结构需要完善，以确保可维护性和可扩展性。
  - 评审依据：目前缺乏相关设计文档。
  - 架构符合性：前端架构应遵循分层原则（视图、组件、状态管理、服务），并与后端服务边界对齐。
  - **建议**:
    1. 要求 Frontend Agent 提供项目结构设计文档，说明目录组织、状态管理方案（如 Provider/Riverpod）、路由策略等。
    2. 架构师将评审该设计，确保其支持未来的城市扩展和多主题能力。
    3. 建议将 API 调用封装在独立的服务层，便于统一处理认证、错误和缓存。

### 2.7 MISHI-007：跨技术栈数据模型一致性检查
- **所有者**: 架构指导Agent D017
- **状态**: done
- **评审说明**: 该任务已完成，报告见 `collab/20_architecture/2026-03-17-risk-assessment-report.md`。架构师认可其结论，并将基于该报告继续监控数据模型一致性。

---

## 3. 架构决策记录（ADR）需求

基于当前评审，以下架构决策需要记录在 `collab/99_decisions`：

1. **数据库外键约束策略**: 所有外键应统一采用 ON DELETE CASCADE 策略，以确保数据一致性。
2. **唯一约束设计原则**: 唯一约束应与业务规则对齐，避免过度限制合法操作。
3. **分区方案依赖管理**: 对于数据库扩展依赖，必须有备选方案和验证流程。
4. **客户端配置管理**: 客户端必须支持多环境配置，且关键配置应通过 CI/CD 验证。

这些 ADR 将在后续的架构文档中详细阐述。

---

## 4. Scheduling Request

根据共享工作区规则，架构师不直接编辑 `collab/handoff/dependency-queue.md`，而是通过本文件提交 Scheduling Request。

### 4.1 请求内容

**请求ID**: ARCH-SR-20260317-001  
**提交时间**: 2026-03-17 12:30  
**请求类型**: 状态更新与任务补充  
**目标队列**: `dependency-queue.md`

#### 4.1.1 状态更新请求
- 更新 MISHI-002 状态为 `in_progress`（如果修复已开始）或 `review`（如果修复已完成需架构评审）。
- 更新 MISHI-007 状态为 `done`（确认已完成）。

#### 4.1.2 新任务添加请求
为确保架构一致性，建议添加以下任务：

| task_id | title | owner | approver | state | priority | depends_on | due_date | 说明 |
|---|---|---|---|---|---|---|---|---|
| MISHI-008 | 数据库外键约束修复方案评审 | Architect Agent | Coordinator | todo | P1 | MISHI-001 | 2026-03-17 19:00 | 评审 Backend Agent 提交的修复 SQL，确保符合架构标准 |
| MISHI-009 | Flutter 服务层设计评审 | Architect Agent | Coordinator | todo | P2 | MISHI-005 | 2026-03-18 12:00 | 评审 App Agent 提交的 Flutter 服务层设计文档 |
| MISHI-010 | 前端项目结构设计评审 | Architect Agent | Coordinator | todo | P2 | MISHI-006 | 2026-03-18 12:00 | 评审 Frontend Agent 提交的前端项目结构设计文档 |
| MISHI-011 | API 契约与实现一致性检查 | Architect Agent | Coordinator | todo | P2 | MISHI-005, MISHI-006 | 2026-03-19 18:00 | 检查各端实现是否严格遵循 API 契约，记录差异并协调解决 |

#### 4.1.3 依赖关系调整
- MISHI-005 和 MISHI-006 应添加依赖：等待 MISHI-002 完成（Base URL 修正），以确保网络层配置正确。
- MISHI-008 依赖于 MISHI-001 完成，但架构评审应在执行前进行？根据流程，执行前需架构批准。建议将 MISHI-001 状态改为 `review`，等待架构评审通过后再执行。

### 4.2 优先级说明
- P1：今日必须完成，涉及系统基本功能。
- P2：明日完成，支撑核心功能开发。

### 4.3 期望动作
请 Coordinator Agent：
1. 更新依赖队列中的任务状态。
2. 添加上述新任务。
3. 调整任务依赖关系。
4. 在每日同步日志中记录本次调度请求。

---

## 5. 后续工作计划

作为 Architect Agent，我将：

1. **今日（2026-03-17）**:
   - 评审 MISHI-001 和 MISHI-004 的具体 SQL 脚本（等待 Backend Agent 提交）。
   - 检查 MISHI-002 修复状态，必要时提供指导。
   - 评审 MISHI-003 的验证结果。

2. **明日（2026-03-18）**:
   - 评审 MISHI-005 和 MISHI-006 的设计文档。
   - 开始编写相关 ADR。

3. **长期**:
   - 定期检查 API 契约变更，确保架构一致性。
   - 识别新的高风险点，特别是 AI 成本、作弊风险、性能瓶颈等。
   - 维护架构决策记录，支持城市扩展规划。

---

**文档维护**: Architect Agent  
**下次评审时间**: 2026-03-17 18:00（今日任务截止时间前）