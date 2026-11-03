# ADR-001: 数据库外键约束策略

## Context
在觅诗项目的数据库设计中，checkins 表的外键约束策略存在不一致：
- `user_id` 外键有 `ON DELETE CASCADE`
- `poi_id` 和 `poem_id` 外键没有 `ON DELETE CASCADE`

这种不一致导致：
1. 删除 POI 或诗词记录时，相关打卡记录成为孤儿数据
2. 或者删除操作失败（如果外键约束是 `RESTRICT`）
3. 数据完整性风险增加

需要制定统一的外键约束策略，确保数据一致性和操作可预测性。

## Decision
所有外键约束统一采用 `ON DELETE CASCADE` 策略。

具体实施：
1. 修改 checkins 表的 poi_id 和 poem_id 外键，添加 `ON DELETE CASCADE`
2. 未来创建的所有外键默认使用 `ON DELETE CASCADE`
3. 只有在明确的业务需求下，才允许使用其他策略（如 `SET NULL` 或 `RESTRICT`）

## Alternatives
考虑过的其他选项：

### 1. ON DELETE SET NULL
- **优点**: 保留打卡记录，仅将外键设为 NULL
- **缺点**: 
  - 打卡记录失去关联的 POI/诗词，业务意义不完整
  - 需要应用层处理 NULL 值，增加复杂度
  - 可能违反业务规则（打卡必须关联有效的 POI 和诗词）

### 2. ON DELETE RESTRICT
- **优点**: 防止意外删除关联数据
- **缺点**: 
  - 删除操作需要应用层先清理关联数据，增加复杂度
  - 可能阻碍合法的数据清理操作
  - 需要额外的业务逻辑处理删除顺序

### 3. ON DELETE NO ACTION (默认)
- **优点**: 与 RESTRICT 类似，但检查时机略有不同
- **缺点**: 与 RESTRICT 类似，可能导致操作失败

### 4. 应用层手动处理
- **优点**: 完全控制删除逻辑
- **缺点**: 
  - 容易遗漏，导致数据不一致
  - 增加应用层复杂度
  - 性能较差（需要多次查询和操作）

## Consequences
### 正面影响
1. **数据一致性**: 自动维护参照完整性，无孤儿数据
2. **操作简单**: 删除操作自动级联，无需额外逻辑
3. **性能**: 数据库级联删除通常比应用层多次操作更高效
4. **可维护性**: 统一策略减少认知负担

### 负面影响
1. **删除范围扩大**: 删除 POI 或诗词会连带删除相关打卡记录
2. **恢复困难**: 级联删除后需要从备份恢复相关数据
3. **潜在意外**: 如果未意识到级联关系，可能意外删除更多数据

### 缓解措施
1. **数据备份**: 重要删除操作前建议备份数据
2. **操作确认**: 管理界面中提示级联删除的影响范围
3. **权限控制**: 限制有删除权限的用户范围
4. **审计日志**: 记录所有删除操作，便于追溯

## Rollback Plan
如果需要回滚此决策：

1. **短期回滚**（在实施前）:
   - 不执行外键约束修改 SQL
   - 维持现状，但需接受数据一致性风险

2. **中期回滚**（实施后但数据影响有限）:
   - 执行反向 SQL，移除 `ON DELETE CASCADE`:
     ```sql
     ALTER TABLE checkins 
       DROP CONSTRAINT checkins_poi_id_fkey,
       ADD CONSTRAINT checkins_poi_id_fkey 
         FOREIGN KEY (poi_id) REFERENCES pois(id);
     
     ALTER TABLE checkins 
       DROP CONSTRAINT checkins_poem_id_fkey,
       ADD CONSTRAINT checkins_poem_id_fkey 
         FOREIGN KEY (poem_id) REFERENCES poems(id);
     ```
   - 需要检查是否有孤儿数据，并清理或修复

3. **长期回滚**（已有大量级联删除）:
   - 从备份恢复被级联删除的数据
   - 修改应用层，实现手动关联数据清理逻辑
   - 更新文档，说明新的删除处理流程

**回滚触发条件**:
- 级联删除导致重要业务数据意外丢失
- 性能问题（级联删除过慢影响用户体验）
- 业务需求变化，需要保留关联记录

---

**决策状态**: 已批准  
**决策时间**: 2026-03-17  
**决策人**: Architect Agent  
**影响范围**: 所有数据库外键约束  
**相关任务**: MISHI-001, MISHI-008  
**文档版本**: v1.0