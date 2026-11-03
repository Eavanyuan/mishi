# 觅诗项目依赖队列（v2）

更新时间：2026-03-18 10:57  
维护人：Coordinator Agent（唯一写入）

## 0) 使用规则
- 本文件为跨角色调度唯一真相（single source of truth）。
- 仅 Coordinator 可编辑。
- 其他角色通过各自域文档的 `Scheduling Request` 提交变更需求。

## 1) 状态机
允许状态：`todo | in_progress | blocked | review | done | cancelled`

流转规则：
- `todo -> in_progress`：Coordinator 排期后执行
- `in_progress -> review`：owner 提交 evidence 后进入评审
- `review -> done`：approver 明确通过
- 任意状态 -> `blocked`：必须填写 `block_reason` 与 `next_check_at`
- 任意状态 -> `cancelled`：必须填写取消原因

## 2) 任务表
| task_id | title | owner | approver | state | priority | depends_on | due_date | updated_at | evidence_link | block_reason | next_check_at |
|---|---|---|---|---|---|---|---|---|---|---|---|
| MISHI-001 | 数据库外键约束修复 | Backend Agent D012 | 架构指导Agent D017 | blocked | P1 | MISHI-013, MISHI-008 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待MISHI-013方案评审，Backend已提交方案 | 2026-03-18 11:00 |
| MISHI-002 | Flutter Base URL修正 | App Agent D019 | 架构指导Agent D017 | done | P0 |  | 2026-03-17 14:00 | 2026-03-17 19:15 | mishi_app/lib/shared/constants/app_constants.dart#L3, mishi_app/lib/core/network/api_client.dart#L10, collab/20_architecture/2026-03-17-architecture-review-round-3-arch.md#2.1-mishi-002-flutter-base-url-修正- |  |  |
| MISHI-003 | 数据库分区扩展验证 | Backend Agent D012 + DevOps | 架构指导Agent D017 | blocked | P1 |  | 2026-03-18 14:00 | 2026-03-18 10:57 |  | 等待MISHI-013方案执行，今日14:00截止 | 2026-03-18 11:00 |
| MISHI-004 | checkins表唯一约束调整 | Backend Agent D012 | 架构指导Agent D017 | blocked | P1 | MISHI-014, MISHI-012 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待MISHI-014方案提交，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-005 | Flutter核心服务层实现 | App Agent D019 | 架构指导Agent D017 | blocked | P2 | MISHI-017 | 2026-03-18 18:00 | 2026-03-18 10:57 |  | 等待服务层设计文档，今日14:00截止 | 2026-03-18 11:00 |
| MISHI-006 | 前端项目结构完善 | Frontend Agent D011 | 架构指导Agent D017 | blocked | P2 | MISHI-018 | 2026-03-18 18:00 | 2026-03-18 10:57 |  | 等待MISHI-018设计文档完成，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-007 | 跨技术栈数据模型一致性检查 | 架构指导Agent D017 | PM Agent | done | P1 |  | 2026-03-17 18:00 | 2026-03-17 18:00 | collab/20_architecture/2026-03-17-risk-assessment-report.md#3.4-跨技术栈数据模型不一致 |  |  |
| MISHI-008 | 数据库外键约束修复方案评审 | Architect Agent | Coordinator Agent | blocked | P1 | MISHI-013 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待评审Backend提交的方案，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-009 | Flutter 服务层设计评审 | Architect Agent | Coordinator Agent | todo | P2 | MISHI-005 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 准备就绪，等待MISHI-017设计文档 | 2026-03-18 14:00 |
| MISHI-010 | 前端项目结构设计评审 | Architect Agent | Coordinator Agent | todo | P2 | MISHI-006 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 准备就绪，等待MISHI-018设计文档完成 | 2026-03-18 12:00 |
| MISHI-011 | API 契约与实现一致性检查 | Architect Agent | Coordinator Agent | todo | P2 | MISHI-005, MISHI-006 | 2026-03-19 18:00 | 2026-03-18 10:57 |  | 准备就绪，等待客户端设计文档 | 2026-03-18 14:00 |
| MISHI-012 | checkins表唯一约束调整方案评审 | Architect Agent | PM Agent | blocked | P1 | MISHI-014 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待MISHI-014方案提交，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-013 | 外键约束修复方案提交 | Backend Agent D012 | Architect Agent | review | P0 |  | 2026-03-18 12:00 | 2026-03-18 10:57 | collab/40_backend/2026-03-18-fk-constraints-fix-be.md |  |  |
| MISHI-014 | 唯一约束调整方案提交 | Backend Agent D012 | Architect Agent | blocked | P0 |  | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待Backend提交方案，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-015 | Flutter多环境配置设计 | App Agent D019 | Architect Agent | review | P2 |  | 2026-03-18 16:00 | 2026-03-18 10:57 | collab/60_app/2026-03-18-flutter-multi-env-config-app.md |  |  |
| MISHI-016 | 分区扩展验证报告 | Backend Agent D012 + DevOps | Architect Agent | blocked | P1 | MISHI-003 | 2026-03-18 14:00 | 2026-03-18 10:57 |  | 依赖MISHI-003未完成，今日14:00截止 | 2026-03-18 11:00 |
| MISHI-017 | Flutter服务层设计文档 | App Agent D019 | Architect Agent | todo | P2 | MISHI-015 | 2026-03-18 14:00 | 2026-03-18 10:57 |  | 今日14:00截止，等待MISHI-015完成 | 2026-03-18 11:00 |
| MISHI-018 | 前端项目结构设计文档 | Frontend Agent D011 | Architect Agent | in_progress | P2 |  | 2026-03-18 12:00 | 2026-03-18 10:57 | collab/50_frontend/2026-03-17-frontend-structure-fe.md |  |  |
| MISHI-019 | ADR文档创建 | Architect Agent | Coordinator Agent | review | P2 |  | 2026-03-18 18:00 | 2026-03-18 10:57 | collab/99_decisions/ (ADR-001至ADR-008), collab/20_architecture/2026-03-18-architecture-review-round-6-arch.md#4 |  |  |
| MISHI-020 | Base URL修正状态确认 | App Agent D019 | Architect Agent | blocked | P0 |  | 2026-03-18 10:00 | 2026-03-18 10:57 |  | 已逾期57分钟，App Agent未提交状态确认 | 2026-03-18 11:00 |
| MISHI-021 | 数据库方案紧急提交 | Backend Agent D012 | Architect Agent | blocked | P0 |  | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待MISHI-013方案执行，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-022 | 架构紧急评审通道 | Architect Agent | Coordinator Agent | blocked | P0 | MISHI-020, MISHI-021 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 依赖任务未完成，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-023 | 季节推荐算法澄清处理 | Architect Agent + Backend Agent | PM Agent | todo | P2 |  | 2026-03-18 14:00 | 2026-03-18 10:57 |  | 今日14:00截止 | 2026-03-18 11:00 |
| MISHI-024 | PM紧急协调请求处理 | Coordinator Agent | PM Agent | in_progress | P0 |  | 2026-03-18 10:05 | 2026-03-18 10:57 | collab/10_requirements/2026-03-18-database-degradation-acceptance-pm.md |  |  |
| MISHI-025 | 数据库紧急方案最终协调 | Coordinator Agent | PM Agent | todo | P0 |  | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 今日12:00截止 | 2026-03-18 11:00 |
| MISHI-026 | MISHI-002完成影响评估 | Coordinator Agent | Architect Agent | todo | P1 | MISHI-002 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 今日12:00截止 | 2026-03-18 11:00 |
| MISHI-027 | 数据库紧急方案最后通牒 | PM Agent | Coordinator Agent | review | P0 | MISHI-024 | 2026-03-18 10:00 | 2026-03-18 10:57 | collab/10_requirements/2026-03-18-database-degradation-acceptance-pm.md |  |  |
| MISHI-028 | 架构师紧急方案准备 | Architect Agent | PM Agent | review | P0 | MISHI-027 | 2026-03-18 10:00 | 2026-03-18 10:57 | collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3 |  |  |
| MISHI-029 | 危机应对计划制定 | Coordinator Agent | PM Agent | todo | P0 | MISHI-027 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 今日12:00截止 | 2026-03-18 11:00 |
| MISHI-030 | 数据库紧急方案执行跟踪 | Backend Agent D012 | Architect Agent | blocked | P0 | MISHI-028 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 等待MISHI-013方案执行，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-031 | 降级版API契约定义 | Architect Agent | PM Agent | todo | P1 |  | 2026-03-18 14:00 | 2026-03-18 10:57 |  | 创建MVP版API契约，今日14:00截止 | 2026-03-18 11:00 |
| MISHI-032 | 应用层补偿逻辑设计 | Backend Agent D012 | Architect Agent | todo | P1 | MISHI-001, MISHI-004 | 2026-03-18 16:00 | 2026-03-18 10:57 |  | 设计实现外键约束移除后的应用层补偿，今日16:00截止 | 2026-03-18 11:00 |
| MISHI-033 | 危机响应进展评估 | Coordinator Agent | PM Agent | todo | P0 | MISHI-030 | 2026-03-18 12:00 | 2026-03-18 10:57 |  | 评估数据库方案执行进展，今日12:00截止 | 2026-03-18 11:00 |
| MISHI-034 | Backend状态最后通牒 | PM Agent | Coordinator Agent | todo | P0++ | MISHI-024 | 2026-03-18 10:05 | 2026-03-18 10:57 |  | 已逾期52分钟，PM未发布最后通牒 | 2026-03-18 11:00 |
| MISHI-035 | 项目生存可行性评估 | PM Agent | Coordinator Agent | todo | P0++ | MISHI-034 | 2026-03-18 10:15 | 2026-03-18 10:57 |  | 已逾期42分钟，PM未进行评估 | 2026-03-18 11:00 |
| MISHI-036 | 极端降级技术方案准备 | Architect Agent | PM Agent | todo | P0+ | MISHI-035 | 2026-03-18 10:30 | 2026-03-18 10:57 |  | 已逾期27分钟，等待PM评估结果 | 2026-03-18 11:00 |
| MISHI-037 | 资源重新分配执行 | Coordinator Agent | PM Agent | todo | P0++ | MISHI-034 | 2026-03-18 10:10 | 2026-03-18 10:57 |  | 已逾期47分钟，等待PM最后通牒结果 | 2026-03-18 11:00 |
| MISHI-028 | 架构师紧急方案准备 | Architect Agent | PM Agent | review | P0 | MISHI-027 | 2026-03-18 10:00 | 2026-03-18 10:32 | collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3 |  |  |
| MISHI-029 | 危机应对计划制定 | Coordinator Agent | PM Agent | todo | P0 | MISHI-027 | 2026-03-18 12:00 | 2026-03-18 10:32 |  | 今日12:00截止 | 2026-03-18 10:30 |
| MISHI-030 | 数据库紧急方案执行跟踪 | Backend Agent D012 | Architect Agent | blocked | P0 | MISHI-028 | 2026-03-18 12:00 | 2026-03-18 10:32 |  | 无法开始执行，Backend无响应 | 2026-03-18 10:05 |
| MISHI-031 | 降级版API契约定义 | Architect Agent | PM Agent | todo | P1 |  | 2026-03-18 14:00 | 2026-03-18 10:32 |  | 创建MVP版API契约，今日14:00截止 | 2026-03-18 10:30 |
| MISHI-032 | 应用层补偿逻辑设计 | Backend Agent D012 | Architect Agent | blocked | P1 | MISHI-001, MISHI-004 | 2026-03-18 16:00 | 2026-03-18 10:32 |  | 依赖数据库方案执行，Backend无响应 | 2026-03-18 10:05 |
| MISHI-033 | 危机响应进展评估 | Coordinator Agent | PM Agent | todo | P0 | MISHI-030 | 2026-03-18 12:00 | 2026-03-18 10:32 |  | 评估数据库方案执行进展，今日12:00截止 | 2026-03-18 10:30 |
| MISHI-034 | Backend状态最后通牒 | PM Agent | Coordinator Agent | todo | P0++ | MISHI-024 | 2026-03-18 10:05 | 2026-03-18 10:32 |  | 强制Backend Agent在10:05前报告状态，否则启动资源重新分配 | 2026-03-18 10:05 |
| MISHI-035 | 项目生存可行性评估 | PM Agent | Coordinator Agent | todo | P0++ | MISHI-034 | 2026-03-18 10:15 | 2026-03-18 10:32 |  | 基于Backend响应评估项目继续可行性 | 2026-03-18 10:15 |
| MISHI-036 | 极端降级技术方案准备 | Architect Agent | PM Agent | todo | P0+ | MISHI-035 | 2026-03-18 10:30 | 2026-03-18 10:32 |  | 准备无Backend参与的技术降级方案 | 2026-03-18 10:30 |
| MISHI-037 | 资源重新分配执行 | Coordinator Agent | PM Agent | todo | P0++ | MISHI-034 | 2026-03-18 10:10 | 2026-03-18 10:32 |  | 如Backend无响应，执行资源重新分配 | 2026-03-18 10:10 |
| MISHI-028 | 架构师紧急方案准备 | Architect Agent | PM Agent | review | P0 | MISHI-027 | 2026-03-18 10:00 | 2026-03-18 09:40 | collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3 |  |  |
| MISHI-029 | 危机应对计划制定 | Coordinator Agent | PM Agent | todo | P0 | MISHI-027 | 2026-03-18 12:00 | 2026-03-18 09:40 |  | 今日12:00截止 | 2026-03-18 10:00 |
| MISHI-030 | 数据库紧急方案执行跟踪 | Backend Agent D012 | Architect Agent | todo | P0 | MISHI-028 | 2026-03-18 12:00 | 2026-03-18 09:40 |  | 执行架构师提供的数据库方案，今日12:00截止 | 2026-03-18 09:55 |
| MISHI-031 | 降级版API契约定义 | Architect Agent | PM Agent | todo | P1 |  | 2026-03-18 14:00 | 2026-03-18 09:40 |  | 创建MVP版API契约，今日14:00截止 | 2026-03-18 10:00 |
| MISHI-032 | 应用层补偿逻辑设计 | Backend Agent D012 | Architect Agent | todo | P1 | MISHI-001, MISHI-004 | 2026-03-18 16:00 | 2026-03-18 09:40 |  | 设计实现外键约束移除后的应用层补偿，今日16:00截止 | 2026-03-18 12:00 |
| MISHI-033 | 危机响应进展评估 | Coordinator Agent | PM Agent | todo | P0 | MISHI-030 | 2026-03-18 12:00 | 2026-03-18 09:40 |  | 评估数据库方案执行进展，今日12:00截止 | 2026-03-18 10:00 |

## 3) 变更日志（append-only）
| ts | actor | change | tasks |
|---|---|---|---|
| 2026-03-17 12:00 | Coordinator Agent | 初始化 v2 模板 | TPL-001 |
| 2026-03-17 11:30 | Coordinator Agent | 基于风险评估报告更新任务队列 | MISHI-001, MISHI-002, MISHI-003, MISHI-004, MISHI-005, MISHI-006, MISHI-007 |
| 2026-03-17 12:35 | Coordinator Agent | 处理 PM/Architect Scheduling Request：更新状态、添加评审任务、调整依赖关系 | MISHI-001, MISHI-002, MISHI-004, MISHI-005, MISHI-006, MISHI-008, MISHI-009, MISHI-010, MISHI-011, MISHI-012 |
| 2026-03-17 14:30 | Coordinator Agent | 处理架构评审轮次1 Scheduling Request：更新任务状态、添加执行任务、调整依赖与阻塞项 | MISHI-001, MISHI-003, MISHI-004, MISHI-005, MISHI-006, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-016, MISHI-017, MISHI-018, MISHI-019 |
| 2026-03-17 15:10 | Coordinator Agent | 处理架构评审轮次2与PM需求澄清：更新阻塞状态、添加紧急任务、调整优先级 | MISHI-001, MISHI-002, MISHI-004, MISHI-005, MISHI-006, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-019, MISHI-020, MISHI-021, MISHI-022, MISHI-023 |
| 2026-03-17 17:25 | Coordinator Agent | 启动协作流水线轮次：扫描Completion Sync（无发现），更新逾期任务检查时间，添加PM紧急协调任务 | MISHI-001, MISHI-002, MISHI-003, MISHI-004, MISHI-005, MISHI-006, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-016, MISHI-020, MISHI-021, MISHI-022, MISHI-024 |
| 2026-03-17 19:15 | Coordinator Agent | 协作流水线标准轮次：处理PM与Architect的Completion Sync，更新MISHI-002为done，调整阻塞任务检查频率，应对数据库严重阻塞危机 | MISHI-002, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-019, MISHI-024 |
| 2026-03-17 20:10 | Coordinator Agent | 协作流水线轮次结束：处理Architect轮次4与PM危机响应的Completion Sync，升级数据库阻塞为项目危机，添加紧急应对任务，调整客户端任务优先级 | MISHI-001, MISHI-003, MISHI-004, MISHI-006, MISHI-008, MISHI-009, MISHI-010, MISHI-011, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-016, MISHI-018, MISHI-019, MISHI-020, MISHI-021, MISHI-022, MISHI-024, MISHI-027, MISHI-028, MISHI-029 |
| 2026-03-18 09:10 | Coordinator Agent | 新一天协作流水线启动：更新所有逾期任务状态，反映严重逾期情况（15-19小时），调整检查时间，准备重新规划今日任务 | MISHI-001, MISHI-003, MISHI-004, MISHI-005, MISHI-006, MISHI-008, MISHI-009, MISHI-010, MISHI-011, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-016, MISHI-017, MISHI-018, MISHI-019, MISHI-020, MISHI-021, MISHI-022, MISHI-023, MISHI-024, MISHI-025, MISHI-026, MISHI-027, MISHI-028, MISHI-029 |
| 2026-03-18 09:40 | Coordinator Agent | 协作流水线轮次结束：处理PM危机恢复计划与架构师紧急方案的Completion Sync，更新任务状态和时间线，添加危机响应跟踪任务，启动数据库紧急方案执行 | MISHI-001, MISHI-003, MISHI-004, MISHI-005, MISHI-006, MISHI-008, MISHI-009, MISHI-010, MISHI-011, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-016, MISHI-017, MISHI-018, MISHI-019, MISHI-020, MISHI-021, MISHI-022, MISHI-023, MISHI-024, MISHI-025, MISHI-026, MISHI-027, MISHI-028, MISHI-029, MISHI-030, MISHI-031, MISHI-032, MISHI-033 |
| 2026-03-18 09:50 | Coordinator Agent | 启动协作流水线标准轮次：更新任务状态反映09:55检查点，准备数据安全检查结果评估，调整调度顺序应对即将到期的任务 | MISHI-001, MISHI-003, MISHI-004, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-016, MISHI-020, MISHI-021, MISHI-030 |
| 2026-03-18 10:32 | Coordinator Agent | 协作流水线轮次结束：处理PM验收标准澄清与架构师危机升级评审的Completion Sync和Scheduling Request，更新任务状态反映09:55检查点失效，添加紧急决策任务，启动危机升级响应 | MISHI-001, MISHI-003, MISHI-004, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-020, MISHI-021, MISHI-022, MISHI-024, MISHI-027, MISHI-028, MISHI-030, MISHI-031, MISHI-032, MISHI-034, MISHI-035, MISHI-036, MISHI-037 |
| 2026-03-18 10:57 | Coordinator Agent | 启动协作流水线标准轮次：处理Backend外键约束修复方案与App多环境配置设计的Completion Sync，更新任务状态，调整调度顺序 | MISHI-001, MISHI-003, MISHI-004, MISHI-008, MISHI-012, MISHI-013, MISHI-014, MISHI-015, MISHI-020, MISHI-021, MISHI-022, MISHI-030, MISHI-032, MISHI-034, MISHI-035, MISHI-036, MISHI-037 |
