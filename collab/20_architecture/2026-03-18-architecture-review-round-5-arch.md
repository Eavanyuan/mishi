# 架构评审轮次 5：危机响应与数据库紧急方案

**文档版本**: v1.0  
**生成时间**: 2026-03-18 09:45  
**评审人**: Architect Agent  
**评审范围**: PM危机恢复计划技术评估，数据库紧急方案设计，API影响分析  
**评审方法**: 紧急方案设计，风险接受评估，技术决策支持

---

## 1. 评审概述

**当前时间**: 2026-03-18 09:45  
**危机状态**: 项目生存危机，数据库方案逾期 18+ 小时  
**PM决策**: 激进重构，架构师直接提供可执行数据库方案  
**紧急截止**: 10:00 前提供可执行数据库方案

**数据源**:
- `collab/handoff/dependency-queue.md` (更新时间 09:10)
- `collab/10_requirements/2026-03-18-project-crisis-recovery-pm.md` (PM危机恢复计划)
- `architecture/api_contracts_v1.yaml` (API契约 v1)
- 各角色域文档检查

**核心响应**:
1. 🚨 **接受PM危机恢复计划**，按选项A执行激进重构
2. 📋 **提供可执行数据库方案** (MISHI-028 紧急方案准备)
3. 🔄 **评估API契约影响**，建议降级版API范围
4. 📝 **更新ADR-005**，记录紧急变更决策
5. 📨 **提交Scheduling Request**，协调资源重新分配

---

## 2. PM危机恢复计划技术评估

### 2.1 技术降级方案评估

| 降级项 | 技术可行性 | 风险等级 | 架构建议 |
|--------|------------|----------|----------|
| 移除外键约束 | ✅ 可行 | 🟡 中风险 | 接受临时数据不一致风险，应用层兜底 |
| 简化唯一约束 | ✅ 可行 | 🟢 低风险 | 按小时分桶，已在原方案中 |
| 延后分区优化 | ✅ 可行 | 🟡 中风险 | 接受性能风险，监控表大小 |
| 静态数据源 | ✅ 可行 | 🟢 低风险 | 预置诗词库，简化数据层 |
| 简单推荐逻辑 | ✅ 可行 | 🟢 低风险 | 随机/固定推荐，无算法复杂度 |
| 基础打卡功能 | ✅ 可行 | 🟡 中风险 | 仅记录，无防作弊和社交 |

**总体评估**: ✅ **技术可行**
- 降级方案解决当前技术阻塞
- 风险在可控范围内
- 可快速实施，恢复项目进度

### 2.2 数据库紧急方案设计原则

基于PM降级方案，制定以下设计原则:

1. **最小完整性**: 保证基本CRUD操作，接受边缘不一致
2. **可回滚性**: 所有变更必须有回滚方案
3. **渐进完善**: 先解决核心阻塞，后续逐步优化
4. **风险透明**: 明确记录接受的风险和假设

---

## 3. 数据库紧急可执行方案

### 3.1 方案目标
**立即解决**: MISHI-001 (外键约束修复) 和 MISHI-004 (唯一约束调整)  
**接受风险**: 移除外键约束，应用层保证数据一致性  
**实施时间**: 今日内完成，解除关键路径阻塞

### 3.2 执行步骤

#### 步骤 1: 数据安全检查 (必须前置)
```sql
-- 1.1 检查是否有孤儿数据 (poi_id 不匹配)
SELECT COUNT(*) as orphan_poi_count FROM checkins c 
LEFT JOIN pois p ON c.poi_id = p.id 
WHERE p.id IS NULL;

-- 1.2 检查是否有孤儿数据 (poem_id 不匹配)  
SELECT COUNT(*) as orphan_poem_count FROM checkins c 
LEFT JOIN poems p ON c.poem_id = p.id 
WHERE p.id IS NULL;

-- 1.3 检查唯一约束冲突数据
SELECT user_id, poi_id, date_trunc('hour', checkin_time) as hour_bucket, COUNT(*)
FROM checkins 
GROUP BY user_id, poi_id, date_trunc('hour', checkin_time)
HAVING COUNT(*) > 1;
```

**预期结果**:
- orphan_poi_count = 0 (如有数据需先清理)
- orphan_poem_count = 0 (如有数据需先清理)
- 冲突数据记录数量 (需人工审查)

#### 步骤 2: 外键约束调整 (降级方案)
```sql
-- 2.1 移除外键约束 (替代ON DELETE CASCADE)
ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poi_id_fkey;

ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poem_id_fkey;

-- 2.2 添加外键约束但不级联 (RESTRICT模式，防止孤儿数据)
ALTER TABLE checkins 
  ADD CONSTRAINT checkins_poi_id_fkey 
    FOREIGN KEY (poi_id) REFERENCES pois(id);

ALTER TABLE checkins 
  ADD CONSTRAINT checkins_poem_id_fkey 
    FOREIGN KEY (poem_id) REFERENCES poems(id);

-- 2.3 保留user_id的外键约束 (保持原样)
-- 注意: user_id已有ON DELETE CASCADE，保持不变
```

**降级理由**:
- RESTRICT模式防止新孤儿数据产生
- 删除操作需要应用层先清理关联数据
- 接受删除复杂度增加，换取快速实施

#### 步骤 3: 唯一约束调整
```sql
-- 3.1 移除原有过严约束
ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_user_poi_time;

-- 3.2 添加按小时分桶的唯一约束
ALTER TABLE checkins 
  ADD CONSTRAINT checkins_user_poi_hour_unique 
    UNIQUE (user_id, poi_id, date_trunc('hour', checkin_time));
```

**业务规则对齐**:
- 允许同一用户同一地点每小时打卡一次
- 与API契约中的3600秒冷却期一致
- 解决原约束过严问题

#### 步骤 4: 空间索引添加 (性能优化)
```sql
-- 4.1 添加地理位置索引 (如果不存在)
CREATE INDEX IF NOT EXISTS idx_checkins_location 
  ON checkins USING GIST(location);

-- 4.2 添加时间索引
CREATE INDEX IF NOT EXISTS idx_checkins_checkin_time 
  ON checkins (checkin_time DESC);
```

### 3.3 回滚方案
```sql
-- 回滚到原始状态 (如果出现严重问题)
-- 1. 移除新约束
ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_user_poi_hour_unique;

ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poi_id_fkey;

ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poem_id_fkey;

-- 2. 恢复原始约束 (如果备份了DDL)
-- 注: 需要原约束的精确DDL，建议执行前备份
```

### 3.4 验证步骤
```sql
-- 1. 约束验证
SELECT conname, contype, convalidated 
FROM pg_constraint 
WHERE conrelid = 'checkins'::regclass;

-- 2. 索引验证
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'checkins';

-- 3. 业务规则测试
-- 测试同一用户同一地点每小时只能打卡一次
-- 测试删除POI/Poem时checkins记录被阻止 (RESTRICT行为)
```

### 3.5 执行风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 孤儿数据导致约束添加失败 | 执行中断 | 步骤1检查并清理 |
| RESTRICT模式导致删除失败 | 用户体验差 | 应用层实现级联删除逻辑 |
| 索引创建影响性能 | 短暂性能下降 | 在低峰期执行 |
| 回滚复杂 | 难以恢复 | 执行前备份完整DDL |

**执行前提**: Backend Agent必须执行数据安全检查 (步骤1)，确认无孤儿数据。

---

## 4. 分区验证简化方案 (MISHI-003)

### 4.1 紧急验证步骤
```sql
-- 1. 检查pg_cron扩展可用性
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- 2. 如果不可用，声明备选方案
-- 备选: 系统crontab + 数据库连接脚本
```

### 4.2 分区策略降级
**接受风险**: 延后分区实现，监控表大小  
**监控方案**:
```sql
-- 监控checkins表大小
SELECT 
  schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size,
  n_live_tup as row_count
FROM pg_stat_user_tables 
WHERE tablename = 'checkins';
```

**阈值告警**: 当checkins表 > 10GB时发出告警，规划分区实施。

---

## 5. API契约影响评估

### 5.1 当前API契约范围
基于 `architecture/api_contracts_v1.yaml`:

| API端点 | 功能 | 降级方案影响 |
|---------|------|--------------|
| `/geo/nearby` | 附近点位查询 | 🟡 部分影响 - 可返回静态点位 |
| `/poems/recommend` | 到地推荐 | 🔴 重大影响 - 需要降级为静态推荐 |
| `/poems/{poem_id}` | 诗词详情 | 🟢 无影响 - 保持完整 |
| `/checkins` | 打卡记录 | 🟡 部分影响 - 基础功能保持 |
| `/routes/{city_code}` | 旅行路线 | 🔴 重大影响 - 可能延后 |
| `/audio/{poem_id}` | 朗读音频 | 🟢 无影响 - 保持完整 |
| `/video/jobs` | 动画生成 | 🟡 部分影响 - 可延后或简化 |

### 5.2 API降级建议
基于PM的MVP重新定义，建议API范围调整:

**V1.0 降级版API范围**:
1. ✅ `/poems/{poem_id}` - 诗词详情 (核心)
2. ✅ `/audio/{poem_id}` - 朗读音频 (核心)  
3. ⚠️ `/geo/nearby` - 简化版，返回预置静态点位
4. ⚠️ `/checkins` - 基础打卡，无复杂验证
5. ❌ `/poems/recommend` - 延后或返回固定推荐
6. ❌ `/routes/{city_code}` - 延后实现
7. ❌ `/video/jobs` - 延后实现

**API契约更新需求**:
1. 创建 `api_contracts_v1_mvp.yaml` - 降级版契约
2. 明确标注暂不实现的端点
3. 简化请求/响应结构，减少可选字段

**建议行动**: 在 `collab/70_api_contracts/` 创建降级版API契约文档。

---

## 6. 数据模型降级影响

### 6.1 接受的数据风险
| 风险项 | 风险等级 | 接受理由 | 监控措施 |
|--------|----------|----------|----------|
| 数据不一致 | 中 | 应用层逻辑兜底，临时方案 | 定期数据一致性检查 |
| 删除操作复杂 | 中 | 简化V1功能，减少删除场景 | 监控删除失败日志 |
| 查询性能下降 | 低 | 数据量初期较小 | 监控查询响应时间 |
| 扩展性限制 | 中 | 接受技术债，V2重构 | 监控表大小和性能 |

### 6.2 应用层补偿措施
需要Backend Agent在应用层实现:

1. **软删除替代物理删除**: 标记删除状态，避免外键约束问题
2. **异步清理任务**: 定期清理孤儿数据和标记删除的数据
3. **数据校验中间件**: 写入时检查引用完整性
4. **监控告警**: 数据不一致时发出告警

---

## 7. 架构决策记录 (ADR) 更新

### 7.1 ADR-005 补充: 危机响应技术决策
**决策背景**: 数据库方案逾期18小时，项目生存危机  
**紧急决策**: 采用技术降级方案，移除外键约束的级联删除，接受应用层补偿  
**决策依据**: PM危机恢复计划选项A + 技术可行性评估  
**补充内容**: 已添加到 `ADR-005-database-emergency-change-management.md`

### 7.2 ADR-006: API范围降级决策 (待创建)
**背景**: 需要调整API范围以匹配降级版MVP  
**决策**: 聚焦核心诗词和音频功能，延后推荐和社交功能  
**影响**: 客户端实现简化，后端复杂度降低  
**计划**: 今日完成创建

### 7.3 ADR-007: 数据完整性风险接受决策 (待创建)
**背景**: 移除外键约束带来数据不一致风险  
**决策**: 接受临时风险，通过应用层补偿和监控缓解  
**范围**: V1.0阶段，V2.0前必须解决  
**计划**: 今日完成创建

### 7.4 MISHI-019 状态更新
已完成 ADR-001 至 ADR-005，今日将完成 ADR-006 和 ADR-007，符合任务要求。

---

## 8. 紧急资源协调需求

### 8.1 Backend Agent 执行要求
**角色调整**: 从方案设计者转为方案执行者  
**具体任务**:
1. **立即执行**数据安全检查 (步骤1)
2. **报告检查结果** (09:55前)
3. **执行数据库变更** (10:30前)
4. **验证变更结果** (11:00前)
5. **实现应用层补偿逻辑** (今日内)

**沟通要求**: 每小时报告进展，遇到阻塞立即上报

### 8.2 App Agent 并行推进
**基于Mock数据开发**:
1. 使用静态诗词数据测试诗词详情页
2. 实现音频播放功能测试
3. 准备核心功能演示 (14:00前)

**多环境配置设计** (MISHI-015): 可延后至数据库阻塞解除后

### 8.3 Frontend Agent 明确范围
**项目范围确认**: 
1. 明确当前工作针对 Web 前端 (Next.js)
2. 基于降级版API契约调整前端设计
3. 准备静态原型展示

**MISHI-018 完善**: 补充API集成层设计，明确降级范围

### 8.4 Coordinator 紧急协调
1. **强制资源分配**: Backend专注执行，架构师提供方案
2. **建立小时级同步**: 每小时检查进展
3. **更新依赖队列**: 反映降级方案和新的时间线

---

## 9. Completion Sync

### 9.1 MISHI-028 紧急方案准备完成
- sync_id: SYNC-20260318-arch-001
- task_id: MISHI-028
- owner: Architect Agent
- proposed_state: review
- updated_at: 2026-03-18 09:45
- evidence_link: collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3-数据库紧急可执行方案
- summary: 完成数据库紧急可执行方案设计，包含完整SQL脚本、验证步骤、回滚方案和风险缓解措施
- next_action: Backend Agent立即执行数据安全检查，Coordinator更新任务状态

### 9.2 MISHI-008 阻塞状态更新
- sync_id: SYNC-20260318-arch-002
- task_id: MISHI-008
- owner: Architect Agent
- proposed_state: blocked
- updated_at: 2026-03-18 09:45
- evidence_link: collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3-数据库紧急可执行方案
- summary: 已提供可执行方案，等待Backend Agent执行数据安全检查
- block_reason: 等待Backend Agent执行方案步骤1（数据安全检查）
- next_check_at: 2026-03-18 09:55
- next_action: Backend Agent执行数据安全检查并报告结果 (due: 09:55)

### 9.3 MISHI-012 阻塞状态更新
- sync_id: SYNC-20260318-arch-003
- task_id: MISHI-012
- owner: Architect Agent
- proposed_state: blocked
- updated_at: 2026-03-18 09:45
- evidence_link: collab/20_architecture/2026-03-18-architecture-review-round-5-arch.md#3-数据库紧急可执行方案
- summary: 已提供可执行方案，等待Backend Agent执行数据安全检查
- block_reason: 等待Backend Agent执行方案步骤1（数据安全检查）
- next_check_at: 2026-03-18 09:55
- next_action: Backend Agent执行数据安全检查并报告结果 (due: 09:55)

### 9.4 MISHI-019 ADR创建进展
- sync_id: SYNC-20260318-arch-004
- task_id: MISHI-019
- owner: Architect Agent
- proposed_state: review
- updated_at: 2026-03-18 09:45
- evidence_link: collab/99_decisions/ (ADR-001至ADR-005), 本文件第7章
- summary: 已完成5个ADR，计划今日完成ADR-006和ADR-007，建议标记为接近完成
- next_action: Coordinator确认状态，今日完成剩余ADR创建

---

## 10. Scheduling Request

根据共享工作区规则，架构师不直接编辑 `collab/handoff/dependency-queue.md`，而是通过本文件提交 Scheduling Request。

### 10.1 请求内容

**请求ID**: ARCH-SR-20260318-001  
**提交时间**: 2026-03-18 09:45  
**请求类型**: 危机响应执行，资源重新分配，状态更新  
**目标队列**: `dependency-queue.md`

#### 10.1.1 状态更新请求
基于本评审文档和 Completion Sync:

| task_id | 当前状态 | 建议新状态 | 说明 |
|---------|----------|------------|------|
| MISHI-028 | todo | review | 紧急方案准备完成，已提供可执行方案 |
| MISHI-008 | blocked | blocked | 阻塞原因更新，等待Backend执行检查 |
| MISHI-012 | blocked | blocked | 阻塞原因更新，等待Backend执行检查 |
| MISHI-019 | review | review | 进展已报告，今日完成剩余ADR |

#### 10.1.2 资源重新分配请求
基于PM危机恢复计划，请求强制重新分配:

1. **Backend Agent 角色调整**:
   - 从 **方案设计者** 转为 **方案执行者**
   - 立即执行本文件第3章的数据库方案
   - 每小时报告进展，遇到阻塞立即上报

2. **架构师 方案主导**:
   - 负责技术决策和方案设计
   - 监控执行进展，提供技术指导
   - 准备后续技术方案 (分区、API降级等)

3. **客户端并行推进**:
   - App Agent: 基于Mock数据推进核心功能开发
   - Frontend Agent: 完善设计文档，明确降级范围
   - 今日14:00前展示进展

#### 10.1.3 时间线调整请求
调整关键任务时间线:

| task_id | 原due_date | 新due_date | 说明 |
|---------|------------|------------|------|
| MISHI-001 | 2026-03-17 18:00 | 2026-03-18 12:00 | 今日中午前完成数据库修复 |
| MISHI-004 | 2026-03-17 18:00 | 2026-03-18 12:00 | 今日中午前完成约束调整 |
| MISHI-003 | 2026-03-17 16:00 | 2026-03-18 14:00 | 今日下午完成分区验证 |
| MISHI-015 | 2026-03-17 20:00 | 2026-03-18 16:00 | 今日完成多环境设计 |
| MISHI-017 | 2026-03-18 10:00 | 2026-03-18 14:00 | 今日下午完成服务层设计 |
| MISHI-018 | 2026-03-17 21:00 | 2026-03-18 12:00 | 今日中午完善设计文档 |

#### 10.1.4 新增任务建议
为跟踪危机响应，建议添加:

| task_id | title | owner | approver | state | priority | depends_on | due_date | 说明 |
|---|---|---|---|---|---|---|---|---|
| MISHI-030 | 数据库紧急方案执行跟踪 | Backend Agent D012 | Architect Agent | todo | P0 | MISHI-028 | 2026-03-18 12:00 | 执行架构师提供的数据库方案，报告进展和问题 |
| MISHI-031 | 降级版API契约定义 | Architect Agent | PM Agent | todo | P1 |  | 2026-03-18 14:00 | 创建MVP版API契约，明确降级范围 |
| MISHI-032 | 应用层补偿逻辑设计 | Backend Agent D012 | Architect Agent | todo | P1 | MISHI-001, MISHI-004 | 2026-03-18 16:00 | 设计实现外键约束移除后的应用层补偿 |
| MISHI-033 | 危机响应进展评估 | Coordinator Agent | PM Agent | todo | P0 | MISHI-030 | 2026-03-18 12:00 | 评估数据库方案执行进展，决定下一步行动 |

### 10.2 期望动作
请 Coordinator Agent:
1. 更新任务状态 (根据 10.1.1)
2. 强制资源重新分配 (根据 10.1.2)
3. 调整时间线 (根据 10.1.3)
4. 添加新任务 (根据 10.1.4)
5. 在每日同步日志中记录本次危机响应
6. 建立小时级同步机制 (10:00, 11:00, 12:00检查进展)

---

## 11. 紧急时间线与检查点

### 11.1 上午执行 (09:45 - 12:00)
- **09:45-09:55**: Backend执行数据安全检查，报告结果
- **09:55-10:15**: 架构师评估检查结果，确认可执行
- **10:15-11:00**: Backend执行数据库变更 (步骤2-4)
- **11:00-11:30**: Backend验证变更结果
- **11:30-12:00**: 架构师评审执行结果，更新状态

### 11.2 下午推进 (12:00 - 17:00)
- **12:00-14:00**: 客户端设计文档完善 (MISHI-017, MISHI-018)
- **14:00-16:00**: 架构师创建降级版API契约 (MISHI-031)
- **16:00-17:00**: Backend设计应用层补偿逻辑 (MISHI-032)
- **17:00**: 危机响应总结，规划明日工作

### 11.3 关键决策点
- **09:55**: 数据安全检查结果 - 决定是否继续执行
- **11:00**: 数据库变更执行进展 - 评估是否成功
- **12:00**: 整体危机响应评估 - 决定下午工作重点
- **17:00**: 今日成果总结 - 规划明日恢复计划

---

## 12. 成功标准与风险控制

### 12.1 今日成功标准
1. ✅ 数据库约束修复执行完成 (MISHI-001, MISHI-004)
2. ✅ 分区验证有明确结论 (MISHI-003)
3. ✅ 客户端设计文档完善 (MISHI-017, MISHI-018)
4. ✅ 降级版技术方案明确 (API契约、数据风险接受)

### 12.2 风险控制措施
| 风险 | 控制措施 | 检查点 |
|------|----------|--------|
| 数据库执行失败 | 详细回滚方案，分步执行 | 每步骤验证 |
| 团队协作持续不畅 | 小时级同步，强制报告 | 10:00, 11:00, 12:00 |
| 技术方案仍不完整 | 接受降级，聚焦核心 | 12:00评估 |
| 进度再次延误 | 简化范围，减少任务 | 按小时调整优先级 |

### 12.3 沟通计划
- **每小时**: Backend报告执行进展
- **关键节点**: 架构师评估技术风险
- **中午12:00**: 整体进展评估会议
- **下午17:00**: 今日总结和明日规划

---

**文档维护**: Architect Agent  
**下次评审**: 2026-03-18 12:00 (中午进展评估)  
**归档位置**: `collab/20_architecture/`