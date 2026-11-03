# 数据库补充表设计

**文档版本**: v1.0  
**输出时间**: 2026-03-16 16:24  
**责任人**: Backend Agent  
**依赖方**: Arch Agent, Coordinator  
**数据库**: PostgreSQL 15 + PostGIS 3.3  
**状态**: 补充设计，待合并到主设计文档

---

## 设计背景

根据觅诗项目需求，在现有 `users`、`pois`、`poems` 三张核心表基础上，补充以下三张业务表：

1. **checkins** - 打卡记录表，支持防作弊风控
2. **video_jobs** - AI视频生成任务表，支持成本控制  
3. **recommendations** - 推荐记录表，用于算法优化

## 1. 打卡记录表 (checkins)

### 1.1 表设计

```sql
-- 启用 PostGIS 扩展（如果尚未启用）
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE checkins (
    -- 主键
    id BIGSERIAL PRIMARY KEY COMMENT '自增主键',
    
    -- 外键关联
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE COMMENT '用户ID',
    poem_id BIGINT NOT NULL REFERENCES poems(id) ON DELETE CASCADE COMMENT '诗词ID',
    poi_id BIGINT NOT NULL REFERENCES pois(id) ON DELETE CASCADE COMMENT '地点ID',
    
    -- 地理位置（实际打卡位置）
    location GEOMETRY(POINT, 4326) NOT NULL COMMENT '打卡坐标 (WGS84)',
    
    -- 设备指纹（防作弊）
    device_info JSONB NOT NULL DEFAULT '{}' COMMENT '设备信息 {
        "fingerprint": "设备指纹",
        "model": "设备型号",
        "os": "操作系统版本",
        "brand": "品牌",
        "screen_resolution": "屏幕分辨率",
        "battery_level": "电池电量"
    }',
    
    -- 网络信息
    ip_address VARCHAR(45) COMMENT 'IP地址 (支持IPv6)',
    
    -- 风控标记
    is_cheating BOOLEAN DEFAULT FALSE COMMENT '是否作弊标记',
    cheating_reasons JSONB COMMENT '作弊原因标签 ["虚拟定位", "设备伪造"]',
    
    -- 打卡时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    -- 唯一约束：防止同一用户在短时间内重复打卡同一地点
    CONSTRAINT checkins_user_poi_unique UNIQUE (user_id, poi_id, date_trunc('hour', created_at))
);

COMMENT ON TABLE checkins IS '打卡记录表（支持防作弊风控）';
```

### 1.2 索引策略

```sql
-- 1. 用户打卡历史索引（按时间倒序，快速查询用户打卡记录）
CREATE INDEX idx_checkins_user_history ON checkins(user_id, created_at DESC);

-- 2. 地理位置索引（空间查询，查找附近打卡记录）
CREATE INDEX idx_checkins_location ON checkins USING GIST(location);

-- 3. 风控查询索引（快速定位可疑记录）
CREATE INDEX idx_checkins_cheating ON checkins(is_cheating, created_at) 
    WHERE is_cheating = TRUE;

-- 4. POI统计索引（用于统计地点打卡次数）
CREATE INDEX idx_checkins_poi ON checkins(poi_id, created_at);

-- 5. 时间范围查询索引
CREATE INDEX idx_checkins_created_at ON checkins(created_at);
```

### 1.3 分区策略

考虑到打卡记录会快速增长，建议按月分区：

```sql
-- 创建主表（分区表）
CREATE TABLE checkins_partitioned (
    -- 字段与 checkins 相同
    -- ...
) PARTITION BY RANGE (created_at);

-- 创建默认分区（用于存储不匹配的数据）
CREATE TABLE checkins_default PARTITION OF checkins_partitioned DEFAULT;

-- 每月自动创建分区（通过定时任务）
CREATE OR REPLACE FUNCTION create_checkins_partition()
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- 创建未来3个月的分区
    FOR i IN 0..2 LOOP
        start_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month' * i);
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'checkins_' || TO_CHAR(start_date, 'YYYYMM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF checkins_partitioned
             FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 每月1号执行分区创建
SELECT cron.schedule('create-checkins-partitions', '0 0 1 * *', 
    'SELECT create_checkins_partition()');
```

### 1.4 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | BIGSERIAL | ✅ | 自增主键 |
| user_id | BIGINT | ✅ | 用户ID，关联users表 |
| poem_id | BIGINT | ✅ | 诗词ID，关联poems表 |
| poi_id | BIGINT | ✅ | 地点ID，关联pois表 |
| location | GEOMETRY(POINT, 4326) | ✅ | 实际打卡坐标，WGS84坐标系 |
| device_info | JSONB | ✅ | 设备指纹信息，用于防作弊 |
| ip_address | VARCHAR(45) | ❌ | IP地址，支持IPv6 |
| is_cheating | BOOLEAN | ❌ | 风控标记，默认false |
| cheating_reasons | JSONB | ❌ | 作弊原因标签数组 |
| created_at | TIMESTAMP | ✅ | 创建时间，默认当前时间 |

## 2. AI视频任务表 (video_jobs)

### 2.1 表设计

```sql
CREATE TABLE video_jobs (
    -- 主键（UUID，便于分布式生成）
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY COMMENT '任务ID',
    
    -- 外键关联
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE COMMENT '用户ID',
    poem_id BIGINT NOT NULL REFERENCES poems(id) ON DELETE CASCADE COMMENT '诗词ID',
    
    -- 任务状态
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'completed', 'failed')) 
        COMMENT '任务状态',
    
    -- 成本控制
    cost_credits INT NOT NULL DEFAULT 1 COMMENT '消耗配额',
    
    -- 生成结果
    video_url VARCHAR(512) COMMENT '生成视频URL',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
    completed_at TIMESTAMP COMMENT '完成时间',
    
    -- 错误信息（失败时记录）
    error_message TEXT COMMENT '错误信息',
    
    -- 任务元数据
    metadata JSONB DEFAULT '{}' COMMENT '任务元数据 {
        "style": "风格参数",
        "duration": "视频时长",
        "resolution": "分辨率"
    }'
);

-- 更新触发器（自动更新updated_at）
CREATE OR REPLACE FUNCTION update_video_jobs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER video_jobs_updated_at_trigger
    BEFORE UPDATE ON video_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_video_jobs_updated_at();

COMMENT ON TABLE video_jobs IS 'AI视频生成任务表（支持成本控制）';
```

### 2.2 索引策略

```sql
-- 1. 用户任务查询索引（按时间倒序）
CREATE INDEX idx_video_jobs_user ON video_jobs(user_id, created_at DESC);

-- 2. 状态查询索引（用于任务调度）
CREATE INDEX idx_video_jobs_status ON video_jobs(status, created_at);

-- 3. 时间范围索引
CREATE INDEX idx_video_jobs_created_at ON video_jobs(created_at);

-- 4. 完成时间索引（统计成功率等）
CREATE INDEX idx_video_jobs_completed_at ON video_jobs(completed_at) 
    WHERE completed_at IS NOT NULL;

-- 5. 成本统计索引
CREATE INDEX idx_video_jobs_cost ON video_jobs(user_id, cost_credits, created_at);
```

### 2.3 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | UUID | ✅ | 任务ID，使用UUID v4 |
| user_id | BIGINT | ✅ | 用户ID，关联users表 |
| poem_id | BIGINT | ✅ | 诗词ID，关联poems表 |
| status | VARCHAR(20) | ✅ | 任务状态：pending/processing/completed/failed |
| cost_credits | INT | ✅ | 消耗配额，默认1 |
| video_url | VARCHAR(512) | ❌ | 生成视频URL |
| created_at | TIMESTAMP | ✅ | 创建时间 |
| updated_at | TIMESTAMP | ✅ | 更新时间，自动维护 |
| completed_at | TIMESTAMP | ❌ | 完成时间（仅当状态为completed/failed时） |
| error_message | TEXT | ❌ | 错误信息（失败时记录） |
| metadata | JSONB | ❌ | 任务元数据，存储风格、时长等参数 |

## 3. 推荐记录表 (recommendations)

### 3.1 表设计

```sql
CREATE TABLE recommendations (
    -- 主键
    id BIGSERIAL PRIMARY KEY COMMENT '自增主键',
    
    -- 外键关联
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE COMMENT '用户ID',
    poem_id BIGINT NOT NULL REFERENCES poems(id) ON DELETE CASCADE COMMENT '诗词ID',
    poi_id BIGINT REFERENCES pois(id) ON DELETE SET NULL COMMENT '地点ID（可选）',
    
    -- 推荐触发类型
    trigger_type VARCHAR(20) NOT NULL 
        CHECK (trigger_type IN ('location', 'season', 'manual', 'history', 'popular'))
        COMMENT '触发类型',
    
    -- 推荐算法因子
    season_factor NUMERIC(3,2) CHECK (season_factor >= 0 AND season_factor <= 1) 
        COMMENT '季节匹配度 (0-1)',
    location_distance INT COMMENT '距离 (米)',
    
    -- 用户行为时间戳
    shown_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '展示时间',
    clicked_at TIMESTAMP COMMENT '点击时间',
    
    -- 推荐权重
    recommendation_score NUMERIC(3,2) DEFAULT 1.0 
        CHECK (recommendation_score >= 0 AND recommendation_score <= 1)
        COMMENT '推荐分数 (0-1)',
    
    -- 会话上下文
    session_id VARCHAR(64) COMMENT '会话ID',
    
    -- 创建时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
);

COMMENT ON TABLE recommendations IS '推荐记录表（用于算法优化）';
```

### 3.2 索引策略

```sql
-- 1. 用户推荐历史索引（按展示时间倒序）
CREATE INDEX idx_recommendations_user_history ON recommendations(user_id, shown_at DESC);

-- 2. 算法分析索引（用于优化算法参数）
CREATE INDEX idx_recommendations_algorithm ON recommendations(trigger_type, season_factor, location_distance);

-- 3. 点击行为分析索引
CREATE INDEX idx_recommendations_clicked ON recommendations(clicked_at) 
    WHERE clicked_at IS NOT NULL;

-- 4. 推荐效果评估索引
CREATE INDEX idx_recommendations_score ON recommendations(recommendation_score DESC, shown_at);

-- 5. 会话追踪索引
CREATE INDEX idx_recommendations_session ON recommendations(session_id, shown_at);

-- 6. 诗词推荐统计索引
CREATE INDEX idx_recommendations_poem ON recommendations(poem_id, shown_at);
```

### 3.3 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | BIGSERIAL | ✅ | 自增主键 |
| user_id | BIGINT | ✅ | 用户ID |
| poem_id | BIGINT | ✅ | 诗词ID |
| poi_id | BIGINT | ❌ | 地点ID（可选） |
| trigger_type | VARCHAR(20) | ✅ | 触发类型：location/season/manual/history/popular |
| season_factor | NUMERIC(3,2) | ❌ | 季节匹配度，0-1之间 |
| location_distance | INT | ❌ | 距离，单位米 |
| shown_at | TIMESTAMP | ✅ | 展示时间，默认当前时间 |
| clicked_at | TIMESTAMP | ❌ | 点击时间（用户点击后更新） |
| recommendation_score | NUMERIC(3,2) | ❌ | 推荐分数，0-1之间 |
| session_id | VARCHAR(64) | ❌ | 会话ID，用于追踪用户单次会话 |
| created_at | TIMESTAMP | ✅ | 创建时间 |

## 4. 与现有设计的差异说明

### 4.1 checkins表差异

| 特性 | 现有设计 (2026-03-17) | 补充设计 (本文档) | 说明 |
|------|---------------------|-------------------|------|
| 设备信息 | 分散字段 (device_id, model, os_version) | JSONB统一存储 | 更灵活，支持扩展 |
| 风控标记 | risk_score + review_status | is_cheating布尔标记 | 简化风控逻辑 |
| IP地址 | 无单独字段 | ip_address字段 | 支持IPv6风控 |
| 分区策略 | 未提及 | 按月分区 | 支持海量数据 |

### 4.2 video_jobs表差异

| 特性 | 现有设计 (2026-03-17) | 补充设计 (本文档) | 说明 |
|------|---------------------|-------------------|------|
| 主键类型 | BIGSERIAL + job_id(UUID) | 直接使用UUID | 简化设计 |
| 状态枚举 | 6种状态 (PENDING/RUNNING/SUCCESS/FAILED/TIMEOUT/CANCELLED) | 4种状态 (pending/processing/completed/failed) | 简化状态机 |
| 成本字段 | cost(DECIMAL) | cost_credits(INT) | 使用积分制，简化计费 |
| 元数据存储 | 分散字段 (style, duration) | metadata JSONB | 更灵活的参数存储 |

### 4.3 recommendations表

现有设计中无此表，为全新设计。

## 5. 迁移建议

如果已有数据需要迁移，建议按以下步骤：

### 5.1 checkins表迁移
```sql
-- 1. 创建新表（使用分区版本）
CREATE TABLE checkins_new (...);

-- 2. 迁移数据（转换设备信息字段）
INSERT INTO checkins_new (user_id, poem_id, poi_id, location, device_info, ...)
SELECT 
    user_id, poem_id, poi_id, location,
    jsonb_build_object(
        'fingerprint', device_id,
        'model', device_model,
        'os', os_version
    ) as device_info,
    ...
FROM checkins_old;

-- 3. 切换表名（需要维护窗口）
ALTER TABLE checkins RENAME TO checkins_old;
ALTER TABLE checkins_new RENAME TO checkins;
```

### 5.2 video_jobs表迁移
```sql
-- 建议保留原有表，新功能使用新表
-- 或逐步迁移已完成的任务
```

### 5.3 recommendations表
无需迁移，全新创建。

## 6. 交付物清单

- [x] checkins表完整DDL（含索引、分区策略）
- [x] video_jobs表完整DDL（含索引、触发器）
- [x] recommendations表完整DDL（含索引）
- [x] 字段详细说明表
- [x] 与现有设计的差异分析
- [x] 迁移建议方案

---

**文档状态**: ✅ 已完成  
**输出时间**: 2026-03-16 16:24  
**责任人**: Backend Agent  
**审核建议**: 请Arch Agent评估与现有设计的兼容性，Coordinator确认业务需求匹配度