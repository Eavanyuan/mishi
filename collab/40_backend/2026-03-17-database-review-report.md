# 数据库设计技术评审报告

**文档版本**: v1.0  
**评审时间**: 2026-03-17 09:30  
**评审人**: Arch Agent (技术评审)  
**评审对象**: 
- 主设计文档: `2026-03-17-database-schema-design.md`
- 补充设计文档: `2026-03-16-database-supplement-tables.md`
- API契约: `2026-03-16-api-contract-v1.1.md`

**数据库**: PostgreSQL 15 + PostGIS 3.3  
**评审方法**: 逐表分析、索引评估、分区验证、API匹配度检查、安全风控评估

---

## 1. 总体评分

### 评分标准与得分

| 维度 | 权重 | 得分 | 说明 |
|------|------|------|------|
| 设计完整性 | 20% | 18/20 | 表结构覆盖了核心业务需求，但缺少徽章/成就等扩展表 |
| 技术合理性 | 30% | 22/30 | 数据类型基本合理，但存在外键约束不一致、唯一约束过严等问题 |
| 性能优化 | 20% | 15/20 | 索引策略基本覆盖，但缺少部分复合索引，分区方案待统一 |
| 安全性和风控 | 10% | 8/10 | 风控字段设计合理，但缺乏操作审计日志和敏感数据加密 |
| 可扩展性和维护性 | 10% | 8/10 | 分区、清理、备份策略明确，但缺少迁移脚本和版本管理 |
| API契约匹配度 | 10% | 9/10 | 快速评审显示88%匹配度，差异可通过业务层转换解决 |

### 总体评分: 80/100 ⭐⭐⭐⭐

### 评审结论: **有条件通过**

**条件**: 需在开发前解决以下高优先级问题：
1. 统一外键约束的级联删除策略
2. 调整checkins表的唯一约束逻辑
3. 为checkins表添加空间索引
4. 统一分区策略并确认pg_cron扩展可用性
5. 为所有表添加updated_at自动更新触发器

---

## 2. 主要优点和亮点

### 2.1 架构设计合理
- **核心表分离清晰**: poems、pois、users三张核心表职责单一，扩展性好
- **关联表设计规范**: poi_poems多对多关联表包含相关性评分，支持智能推荐
- **风控体系完整**: checkins表包含设备指纹、风险评分、人工审核队列，防作弊能力较强

### 2.2 性能优化到位
- **空间索引优化**: pois表location和geofence字段均创建GIST索引，支持高效空间查询
- **JSONB索引合理**: poems表的tags、best_seasons等字段创建GIN索引，支持包含查询
- **全文搜索支持**: poems表content_text字段配置中文全文搜索索引，提升搜索体验
- **分区策略前瞻**: user_events表按月分区，checkins表也设计分区方案，应对数据增长

### 2.3 扩展性考虑周全
- **JSONB灵活扩展**: 多处使用JSONB字段（如device_info、metadata），便于后续添加字段
- **系统配置表**: 支持动态调整限额、开关等参数，无需修改代码
- **清理策略明确**: 定义数据清理和归档策略，避免数据无限膨胀

### 2.4 与API契约匹配度高
- **字段对应关系清晰**: 大部分API字段能在数据库中找到直接或间接对应
- **业务逻辑可实现**: API特有的计算字段（如distance、score_breakdown）可通过SQL函数或业务层计算实现
- **性能指标对齐**: 数据库索引设计支持API的性能目标（P95延迟要求）

---

## 3. 发现的问题和风险（按优先级排序）

### 3.1 🔴 高优先级（必须修复）

#### 问题1: 外键约束级联策略不一致
- **位置**: checkins表
- **描述**: poi_id和poem_id外键缺少ON DELETE CASCADE，而user_id有该策略。当pois或poems记录被删除时，相关打卡记录会成为孤儿数据或导致删除失败。
- **风险**: 数据不一致或删除操作异常
- **建议SQL**:
```sql
-- 修改checkins表外键约束
ALTER TABLE checkins 
  DROP CONSTRAINT checkins_poi_id_fkey,
  ADD CONSTRAINT checkins_poi_id_fkey 
    FOREIGN KEY (poi_id) REFERENCES pois(id) ON DELETE CASCADE;

ALTER TABLE checkins 
  DROP CONSTRAINT checkins_poem_id_fkey,
  ADD CONSTRAINT checkins_poem_id_fkey 
    FOREIGN KEY (poem_id) REFERENCES poems(id) ON DELETE CASCADE;
```

#### 问题2: checkins表唯一约束过于严格
- **位置**: checkins表 CONSTRAINT checkins_user_poi_time UNIQUE (user_id, poi_id, checkin_time)
- **描述**: 精确到秒的唯一约束可能导致合法重复打卡被拒绝（如用户离开后再次访问）。API契约中允许冷却期（checkin.cooldown_seconds=3600）后重新打卡。
- **风险**: 用户体验差，业务规则冲突
- **建议SQL**:
```sql
-- 改为按小时去重（与补充设计一致）
ALTER TABLE checkins 
  DROP CONSTRAINT checkins_user_poi_time,
  ADD CONSTRAINT checkins_user_poi_hour_unique 
    UNIQUE (user_id, poi_id, date_trunc('hour', checkin_time));
```

#### 问题3: checkins表缺少空间索引
- **位置**: checkins表location字段
- **描述**: 该字段用于存储打卡坐标，但未创建GIST索引。当需要查询某个区域内的打卡记录时性能低下。
- **风险**: 地理位置查询性能差
- **建议SQL**:
```sql
CREATE INDEX idx_checkins_location ON checkins USING GIST(location);
```

#### 问题4: 分区策略不统一且依赖未确认的扩展
- **位置**: user_events表和补充设计中的checkins分区
- **描述**: 
  1. 主设计中的user_events分区依赖pg_cron扩展，未确认是否已安装
  2. 补充设计中的checkins分区与主设计中的checkins表结构不一致
  3. 分区自动创建函数缺少错误处理和监控
- **风险**: 分区功能不可用，导致单表过大性能下降
- **建议**:
  1. 确认PostgreSQL实例是否已安装pg_cron和postgis扩展
  2. 统一checkins表设计，选择一种分区方案
  3. 为分区函数添加日志记录和异常处理

#### 问题5: 缺少updated_at自动更新机制
- **位置**: 所有包含updated_at字段的表
- **描述**: 当前设计依赖应用层更新updated_at字段，容易遗漏导致数据不准确
- **风险**: 数据更新时间不可靠，影响同步和监控
- **建议SQL**:
```sql
-- 通用更新触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为每个表创建触发器（示例：poems表）
CREATE TRIGGER update_poems_updated_at 
  BEFORE UPDATE ON poems 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 3.2 🟡 中优先级（建议修复）

#### 问题6: JSONB字段设计可优化
- **位置**: poems表的content、tags、best_seasons等字段
- **描述**: 对于固定结构的数组数据（如诗句数组、标签数组），使用PostgreSQL原生数组类型可能更高效，且与API的数组格式更匹配。
- **风险**: JSONB解析开销，索引体积较大
- **建议**: 
  - 评估将content字段改为TEXT[]数组类型的可行性
  - 如坚持使用JSONB，确保content_text与content内容同步（添加触发器）

#### 问题7: 缺少关键复合索引
- **位置**: 多个表
- **描述**:
  1. poems表缺少(poi_id, status, view_count)索引，影响热门诗词推荐
  2. poi_poems表缺少(poem_id, relevance_score)索引，影响诗词相关地点查询
  3. recommendations表缺少(user_id, trigger_type, shown_at)索引，影响推荐算法分析
- **风险**: 特定查询场景性能不佳
- **建议SQL**:
```sql
-- poems表复合索引
CREATE INDEX idx_poems_poi_status_view ON poems(poi_id, status, view_count DESC) WHERE poi_id IS NOT NULL;

-- poi_poems表复合索引  
CREATE INDEX idx_poi_poems_poem_relevance ON poi_poems(poem_id, relevance_score DESC);

-- recommendations表复合索引
CREATE INDEX idx_recommendations_user_trigger_time ON recommendations(user_id, trigger_type, shown_at DESC);
```

#### 问题8: 缺少操作审计日志表
- **位置**: 整体设计
- **描述**: 当前设计只有用户行为日志（user_events），缺乏管理员操作、敏感数据变更等审计日志。
- **风险**: 安全事件无法追溯，合规性不足
- **建议**: 添加audit_logs表，记录用户ID、操作类型、操作对象、IP地址、时间戳等。

#### 问题9: 数据一致性风险
- **位置**: poems表的content和content_text字段
- **描述**: content_text字段用于全文搜索，但依赖应用层保证与content字段的一致性。
- **风险**: 两个字段内容不一致导致搜索结果不准确
- **建议**: 添加触发器自动从content生成content_text
```sql
CREATE OR REPLACE FUNCTION sync_poem_content_text()
RETURNS TRIGGER AS $$
BEGIN
    -- 从JSONB数组提取文本并拼接
    SELECT string_agg(value->>'text', E'\n')
    INTO NEW.content_text
    FROM jsonb_array_elements(NEW.content) AS value;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_poem_content_text_trigger
  BEFORE INSERT OR UPDATE ON poems
  FOR EACH ROW EXECUTE FUNCTION sync_poem_content_text();
```

### 3.3 🟢 低优先级（优化建议）

#### 问题10: 字段长度和类型细节
- **描述**:
  1. users表的password_hash字段VARCHAR(255)可能不足，bcrypt哈希值可能更长
  2. checkins表的device_id字段VARCHAR(128)可能不够存储复杂设备指纹
  3. 多个表的status字段使用VARCHAR(20)，建议使用枚举类型或更小的类型
- **建议**: 
  - password_hash改为VARCHAR(255)或TEXT
  - device_id改为VARCHAR(256)或TEXT
  - 考虑使用SMALLINT加字典表替代状态字符串

#### 问题11: 枚举值不一致
- **描述**: video_jobs表的状态枚举在主设计和补充设计中不一致（6种 vs 4种），与API契约也不完全匹配。
- **建议**: 以API契约为准，统一状态枚举

#### 问题12: 缺少注释和文档
- **描述**: 部分索引、约束、触发器缺少注释，影响维护
- **建议**: 为所有数据库对象添加COMMENT

---

## 4. 具体改进建议

### 4.1 数据库设计层

#### 建议1: 统一并固化checkins表设计
- **方案**: 合并主设计和补充设计的优点
  - 保留主设计的详细风控字段（risk_score, risk_reasons, review_status）
  - 采用补充设计的device_info JSONB统一设备信息
  - 添加ip_address字段支持IPv6
  - 采用按月分区策略
- **优先级**: 高

#### 建议2: 优化JSONB字段使用
- **方案**: 
  - 保持content为JSONB，但添加内容验证约束
  - 将tags、best_seasons等简单数组改为TEXT[]数组类型
  - 为所有JSONB字段添加CHECK约束验证格式
- **优先级**: 中

#### 建议3: 添加缺失的关键表
- **方案**:
  - badges表：存储徽章定义和用户获得的徽章
  - audit_logs表：记录敏感操作审计日志
  - dictionary表：存储枚举值的统一字典
- **优先级**: 中

### 4.2 性能优化层

#### 建议4: 实施分区策略
- **步骤**:
  1. 确认pg_cron扩展可用
  2. 统一user_events和checkins的分区策略（均按月分区）
  3. 创建分区维护监控
- **优先级**: 高

#### 建议5: 添加复合索引
- **步骤**: 根据第3.2节问题7的建议创建复合索引
- **优先级**: 中

#### 建议6: 设置索引维护策略
- **步骤**: 定期执行REINDEX和VACUUM ANALYZE
```sql
-- 每周日凌晨执行
SELECT cron.schedule('db-maintenance', '0 2 * * 0', 
    'REINDEX DATABASE CONCURRENTLY mishi; VACUUM ANALYZE;');
```
- **优先级**: 低

### 4.3 安全风控层

#### 建议7: 增强数据安全
- **方案**:
  1. 对password_hash字段添加强度验证约束
  2. 对ip_address字段添加格式验证
  3. 对敏感查询（如用户信息）添加行级安全策略
- **优先级**: 中

#### 建议8: 完善审计追踪
- **方案**: 创建audit_logs表并配置相关触发器
- **优先级**: 中

---

## 5. 技术债务评估

### 5.1 短期债务（需在开发前解决）
| 债务项 | 影响 | 解决成本 |
|--------|------|----------|
| 外键约束不一致 | 数据完整性风险 | 低（SQL脚本） |
| 唯一约束过严 | 业务逻辑冲突 | 低（SQL脚本） |
| 缺少空间索引 | 查询性能差 | 低（创建索引） |
| 分区策略不统一 | 运维复杂度高 | 中（设计统一方案） |

### 5.2 中期债务（可在V1.2版本解决）
| 债务项 | 影响 | 解决成本 |
|--------|------|----------|
| JSONB字段优化 | 存储和性能优化 | 中（数据迁移） |
| 缺少复合索引 | 特定查询性能 | 低（创建索引） |
| 缺少审计日志 | 安全合规性 | 中（设计实现） |
| 枚举值不一致 | 代码复杂度 | 低（统一枚举） |

### 5.3 长期债务（规划中）
| 债务项 | 影响 | 解决成本 |
|--------|------|----------|
| 数据归档策略 | 存储成本 | 高（ETL流程） |
| 跨地域复制 | 可用性和性能 | 高（架构改造） |
| 实时分析分离 | OLTP性能 | 高（CDC同步） |

**总技术债务评分**: 65/100（中等水平）

---

## 6. 实施建议和优先级

### 6.1 实施路线图

#### 阶段1: 紧急修复（本周内）
1. 修复外键约束不一致问题
2. 调整checkins表唯一约束
3. 为checkins表添加空间索引
4. 确认扩展依赖（postgis、pg_cron）

#### 阶段2: 核心优化（下周末前）
1. 统一checkins表设计并实施分区
2. 为所有表添加updated_at触发器
3. 添加关键复合索引
4. 实施数据清理策略

#### 阶段3: 增强完善（V1.2版本）
1. 优化JSONB字段设计
2. 添加审计日志表
3. 完善枚举字典
4. 添加徽章系统表

#### 阶段4: 长期规划（V2.0版本）
1. 数据归档和冷热分离
2. 读写分离和负载均衡
3. 跨地域部署

### 6.2 优先级矩阵

| 优先级 | 问题 | 预计工时 | 负责方 |
|--------|------|----------|--------|
| P0 | 外键约束修复 | 2小时 | DBA |
| P0 | checkins唯一约束调整 | 1小时 | DBA |
| P0 | 确认扩展依赖 | 1小时 | DevOps |
| P1 | 统一checkins表设计 | 8小时 | Backend + DBA |
| P1 | 添加updated_at触发器 | 4小时 | DBA |
| P1 | 添加关键复合索引 | 2小时 | DBA |
| P2 | 优化JSONB字段 | 16小时 | Backend + DBA |
| P2 | 添加审计日志表 | 12小时 | Backend |
| P3 | 添加徽章系统表 | 8小时 | Backend |

### 6.3 风险评估与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 分区策略实施失败 | 中 | 高 | 先在不分区环境下测试，准备回滚方案 |
| 数据迁移丢失 | 低 | 高 | 全量备份，分批次迁移，数据校验 |
| 性能不达预期 | 中 | 中 | 压力测试，性能监控，索引优化 |
| 扩展不可用 | 低 | 高 | 准备替代方案（如外部定时任务） |

---

## 7. 附录：详细问题清单

### 7.1 表级问题汇总

| 表名 | 问题数量 | 严重程度 | 状态 |
|------|----------|----------|------|
| checkins | 5 | 高 | 待修复 |
| poems | 3 | 中 | 待优化 |
| video_jobs | 2 | 中 | 待统一 |
| poi_poems | 1 | 低 | 待优化 |
| users | 2 | 低 | 待优化 |
| recommendations | 1 | 中 | 待优化 |
| 整体设计 | 3 | 中 | 待补充 |

### 7.2 API契约匹配度详情

| 接口 | 匹配度 | 主要差异 | 解决方案 |
|------|--------|----------|----------|
| GET /poems/{id} | 90% | interpretations结构不同 | 业务层转换 |
| GET /geo/nearby | 95% | distance需计算 | PostGIS函数 |
| POST /checkins | 85% | device_info结构不同 | JSONB转换 |
| POST /video/jobs | 80% | 状态枚举不同 | 映射表 |

**总体匹配度**: 87.5%

### 7.3 性能基准预期

| 查询场景 | 当前设计预期P95 | 优化后目标P95 | 优化措施 |
|----------|----------------|---------------|----------|
| 附近POI查询 | 50ms | 30ms | 空间索引优化 |
| 诗词推荐 | 200ms | 100ms | 复合索引添加 |
| 打卡历史 | 100ms | 50ms | 分区+索引 |
| 视频任务状态 | 50ms | 20ms | 索引优化 |

---

## 8. 最终结论

### 8.1 评审总结

觅诗项目的数据库设计在**业务覆盖完整性**和**基础技术合理性**方面表现良好，得分为80分，达到"有条件通过"标准。

**主要优势**:
1. 核心表结构清晰，符合领域驱动设计原则
2. 空间数据管理和全文搜索设计专业
3. 风控体系考虑全面
4. 扩展性设计前瞻

**待改进领域**:
1. 数据一致性和完整性约束需加强
2. 性能优化细节需完善
3. 运维和监控设计需补充
4. 安全审计机制需建立

### 8.2 建议决策

✅ **建议批准数据库设计进入开发阶段，但需在开发前解决所有高优先级问题。**

**理由**:
1. 核心业务需求已完全覆盖
2. 技术问题均有明确解决方案
3. 修复成本可控，不影响项目进度
4. 团队具备实施能力

**附加条件**:
1. 开发团队需在编码前确认所有SQL修改已实施
2. 需建立数据库变更审查流程
3. 性能测试需作为验收标准之一

### 8.3 下一步行动

1. **立即行动**: DBA团队根据本报告第6.1节阶段1内容执行紧急修复
2. **本周会议**: 架构组、后端组、DBA组评审实施计划
3. **下周交付**: 完整的schema.sql和migration脚本
4. **持续监控**: 上线后监控数据库性能指标，按需优化

---

**报告生成时间**: 2026-03-17 10:00  
**评审人**: Arch Agent  
**报告状态**: ✅ 已完成  
**下一评审节点**: 开发完成后的性能测试报告