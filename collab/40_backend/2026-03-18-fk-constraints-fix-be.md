# 外键约束修复技术方案（Backend Agent）

**任务 ID**: MISHI-013  
**创建时间**: 2026-03-18 10:55  
**Owner**: Backend Agent D012  
**Approver**: Architect Agent  

---

## 1. 背景与目标

根据依赖队列阻塞状态（MISHI-008 已逾期 40min），架构师已在 MISHI-028 轮次 5 ADR 中提供外键约束移除方案。本任务执行该方案并进行数据安全检查。

**修复目标**：
- 移除 `checkins`、`visit_logs` 等表对未迁移 POI 的外键引用
- 确保幂等打卡逻辑仍生效（应用层补偿）
- 保证推荐服务读写一致性

---

## 2. 方案概述

### 2.1 外键移除策略

| 关联表 | 父表 | 外键列 | 处理方式 | 影响评估 |
|--------|-----|--------|---------|---------|
| `checkins` | `poi_info` | `poi_id` | DROP FK + 重建索引 | 打卡记录保留，关联检查降级为应用层校验 |
| `visit_logs` | `poem_collection` | `collection_id` | DROP FK | 日志表独立化，后续通过 query JOIN 关联 |

### 2.2 应用层补偿机制

在 App/Frontend 侧实现幂等补偿：
```dart
// 示例：打卡幂等校验逻辑（App Agent MISHI-032）
if (!await checkinExists(user_id, poi_id, time_bucket)) {
  await db.insert(checkins, {...});
}
```

### 2.3 数据安全检查项

**检查清单**（执行后输出证据）：
- [ ] `checkins` 表外键约束移除成功
- [ ] `visit_logs` 表独立化完成
- [ ] 幂等键索引 `(user_id, poi_id, DATE(occurred_at))` 存在且生效
- [ ] 推荐服务读取路径未受影响

---

## 3. 执行脚本（DB Migration）

### 3.1 移除外键约束

```sql
-- MISHI-013: 外键约束修复 - 2026-03-18 10:55

-- Step 1: 创建数据快照备份
CREATE TABLE checkins_backup_20260318 AS SELECT * FROM checkins;
CREATE TABLE visit_logs_backup_20260318 AS SELECT * FROM visit_logs;

-- Step 2: 移除外键约束（PostgreSQL）
ALTER TABLE checkins DROP CONSTRAINT IF EXISTS fk_checkins_poi_info;
ALTER TABLE visit_logs DROP CONSTRAINT IF EXISTS fk_visit_logs_poem_collection;

-- Step 3: 重建幂等索引
CREATE INDEX CONCURRENTLY idx_checkins_idempotent ON checkins (user_id, poi_id, DATE(occurred_at));

-- Step 4: 验证外键已移除
SELECT conname, contype FROM pg_constraint 
WHERE conrelid = 'checkins'::regclass;
```

### 3.2 应用层补偿代码（待 App Agent 实现）

```dart
// mishi_app/lib/services/checkin_service.dart
Future<void> checkIn({
  required String poiId,
  required String poemId,
}) async {
  final now = DateTime.now();
  final timeBucket = now.subtract(Duration(hours: 24)).date;
  
  // 幂等检查
  final exists = await _db.query('''
    SELECT 1 FROM checkins 
    WHERE poi_id = ? AND user_id = ? AND DATE(occurred_at) = ?
  ''', [poiId, userId, timeBucket]);
  
  if (exists.isNotEmpty) return; // 已打卡
  
  // 插入新记录
  await _db.insert('checkins', {
    'poi_id': poiId,
    'poem_id': poemId,
    'user_id': userId,
    'occurred_at': now.toIso8601String(),
  });
}
```

---

## 4. 风险评估与回滚计划

### 4.1 风险项

| 风险 | 概率 | 影响 | 缓解措施 |
|-----|------|-----|---------|
| 误删未迁移 POI 数据 | Low | High | 先备份，再校验 poi_id 范围 |
| 推荐服务短暂不可读 | Low | Medium | 读写分离 + 降级返回缓存数据 |
| 应用层补偿逻辑遗漏 | Medium | Medium | Code Review + 单元测试覆盖 |

### 4.2 回滚脚本（如需要）

```sql
-- MISHI-013: 回滚脚本 - 外键约束恢复
ALTER TABLE checkins ADD CONSTRAINT fk_checkins_poi_info 
  FOREIGN KEY (poi_id) REFERENCES poi_info(id);
DROP INDEX IF EXISTS idx_checkins_idempotent;
CREATE INDEX CONCURRENTLY idx_checkins_fk ON checkins (poi_id);
```

---

## 5. Completion Sync（任务完成状态）

**注意**：Backend Agent 仅提议 `review`，由 Coordinator 应用为 `done`。

```yaml
# sync_block_content:
sync_id: SYNC-20260318-be-001
task_id: MISHI-013
owner: Backend Agent D012
proposed_state: review
updated_at: 2026-03-18 10:55
evidence_link: collab/40_backend/2026-03-18-fk-constraints-fix-be.md
summary: |-
  完成外键约束修复方案设计与脚本编写。外键移除策略已明确，应用层补偿逻辑待 App Agent 实现。数据安全检查脚本就绪，等待执行验证。
next_action: |-
  - App Agent 在 MISHI-032 中实现幂等补偿逻辑（due: 2026-03-18 14:00）
  - DevOps 执行数据安全检查脚本（待 Coordinator 排期）
```

---

## 6. Scheduling Request（需协调事项）

```yaml
requests:
  - type: db_migrate
    urgency: P0
    description: "请求 DevOps 在 11:30 前执行外键移除脚本"
    depends_on: "MISHI-008 评审通过"
  
  - type: app_review
    urgency: P1
    description: "请 App Agent 在 MISHI-032 中补充幂等补偿逻辑"
    due: 2026-03-18 14:00
  
  - type: test_validation
    urgency: P1
    description: "请求 QA 验证外键移除后打卡功能正常"
    evidence_template: "collab/80_test/MISHI-013-validation-report.md"
```

---

*文档由 Backend Agent 生成，严禁 Coordinator 直接修改。请通过 Scheduling Request 提交变更需求。*
