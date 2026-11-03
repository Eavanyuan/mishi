# 觅诗数据库表结构设计

**文档版本**: v1.0  
**输出时间**: 2026-03-14 18:52  
**责任人**: Arch Agent  
**依赖方**: Backend Agent  
**数据库**: PostgreSQL 15 + PostGIS 3.3  
**状态**: 待 Coordinator 评审

---

## 1. 数据库架构

### 1.1 数据库选型

**主数据库**: PostgreSQL 15
- ✅ 成熟稳定,ACID 支持
- ✅ PostGIS 空间扩展
- ✅ JSON 字段支持
- ✅ 全文搜索

**缓存层**: Redis 7
- 配额控制
- 会话管理
- 热数据缓存

**对象存储**: OSS/S3
- 音频文件
- 视频文件
- 图片资源

---

## 2. 核心表设计

### 2.1 诗词表 (poems)

**用途**: 存储诗词基础信息和内容

```sql
CREATE TABLE poems (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL COMMENT '诗名',
    author VARCHAR(100) NOT NULL COMMENT '作者',
    dynasty VARCHAR(50) NOT NULL COMMENT '朝代 (唐/宋/元/明/清)',
    content JSONB NOT NULL COMMENT '诗词内容 ["句子1", "句子2"]',
    content_text TEXT NOT NULL COMMENT '纯文本内容 (用于全文搜索)',
    
    -- 标注信息
    tags JSONB COMMENT '标签 ["思乡","月夜"]',
    best_seasons JSONB COMMENT '最佳季节 ["春","夏"]',
    solar_terms JSONB COMMENT '相关节气 ["清明","谷雨"]',
    time_period_tags JSONB COMMENT '时段标签 ["清晨","傍晚"]',
    
    -- 解读内容
    interpretation_basic TEXT COMMENT '基础解读',
    interpretation_textbook TEXT COMMENT '教材版解读',
    interpretation_textbook_source VARCHAR(255) COMMENT '教材来源',
    interpretation_academic TEXT COMMENT '学术版解读',
    interpretation_academic_source VARCHAR(255) COMMENT '学术来源',
    
    -- 媒体资源
    has_audio BOOLEAN DEFAULT FALSE,
    audio_url VARCHAR(512),
    audio_duration INT COMMENT '音频时长 (秒)',
    has_video BOOLEAN DEFAULT FALSE,
    
    -- 统计信息
    view_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    checkin_count INT DEFAULT 0,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    
    -- 审核信息
    created_by BIGINT,
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 索引
    CONSTRAINT poems_title_author_key UNIQUE (title, author, dynasty)
);

-- 索引
CREATE INDEX idx_poems_author ON poems(author);
CREATE INDEX idx_poems_dynasty ON poems(dynasty);
CREATE INDEX idx_poems_view_count ON poems(view_count DESC);
CREATE INDEX idx_poems_status ON poems(status);
CREATE INDEX idx_poems_tags ON poems USING GIN(tags);
CREATE INDEX idx_poems_seasons ON poems USING GIN(best_seasons);

-- 全文搜索索引
CREATE INDEX idx_poems_content_fts ON poems USING GIN(to_tsvector('chinese', content_text));

COMMENT ON TABLE poems IS '诗词表';
```

---

### 2.2 POI 表 (pois)

**用途**: 存储诗词相关地点 (景点、建筑、街区)

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE pois (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT 'POI 名称',
    ancient_name VARCHAR(255) COMMENT '古称',
    modern_name VARCHAR(255) COMMENT '今称',
    
    -- 地理信息
    location GEOMETRY(POINT, 4326) NOT NULL COMMENT '中心坐标 (WGS84)',
    radius INT DEFAULT 100 COMMENT '圆形围栏半径 (米)',
    geofence GEOMETRY(POLYGON, 4326) COMMENT '多边形围栏 (可选)',
    
    -- 分类信息
    city_code VARCHAR(10) NOT NULL COMMENT '城市编码 (如 110000=北京)',
    province_code VARCHAR(10) COMMENT '省份编码',
    category VARCHAR(50) COMMENT '类别 (景点/街区/建筑)',
    
    -- 描述信息
    description TEXT,
    address VARCHAR(500),
    
    -- 统计信息
    visit_count INT DEFAULT 0,
    checkin_count INT DEFAULT 0,
    poems_count INT DEFAULT 0 COMMENT '关联诗词数量',
    
    -- 状态
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1)) COMMENT '0=禁用,1=启用',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pois_name_city_key UNIQUE (name, city_code)
);

-- 空间索引 (关键性能优化)
CREATE INDEX idx_pois_location ON pois USING GIST(location);
CREATE INDEX idx_pois_geofence ON pois USING GIST(geofence);

-- 普通索引
CREATE INDEX idx_pois_city_code ON pois(city_code);
CREATE INDEX idx_pois_status ON pois(status);
CREATE INDEX idx_pois_visit_count ON pois(visit_count DESC);

COMMENT ON TABLE pois IS 'POI 地点表';
```

---

### 2.3 POI-诗词关联表 (poi_poems)

**用途**: 建立 POI 与诗词的多对多关系

```sql
CREATE TABLE poi_poems (
    id BIGSERIAL PRIMARY KEY,
    poi_id BIGINT NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
    poem_id BIGINT NOT NULL REFERENCES poems(id) ON DELETE CASCADE,
    
    -- 关联度
    distance INT DEFAULT 0 COMMENT '诗词描述地点到 POI 的距离 (米)',
    relevance_score FLOAT DEFAULT 1.0 CHECK (relevance_score BETWEEN 0 AND 1) COMMENT '相关性 (0-1)',
    
    -- 来源
    created_by VARCHAR(20) DEFAULT 'manual' CHECK (created_by IN ('manual', 'ai', 'user_contribute')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT poi_poems_unique UNIQUE (poi_id, poem_id)
);

CREATE INDEX idx_poi_poems_poi ON poi_poems(poi_id);
CREATE INDEX idx_poi_poems_poem ON poi_poems(poem_id);
CREATE INDEX idx_poi_poems_relevance ON poi_poems(poi_id, relevance_score DESC);

COMMENT ON TABLE poi_poems IS 'POI-诗词关联表';
```

---

### 2.4 用户表 (users)

**用途**: 存储用户基础信息

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    email VARCHAR(255) UNIQUE,
    nickname VARCHAR(100),
    avatar_url VARCHAR(512),
    
    -- 用户类型
    user_type VARCHAR(20) DEFAULT 'normal' CHECK (user_type IN ('normal', 'vip', 'test')),
    
    -- 统计信息
    checkin_count INT DEFAULT 0,
    poem_view_count INT DEFAULT 0,
    audio_play_count INT DEFAULT 0,
    
    -- 状态
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1, -1)) COMMENT '1=正常,0=禁用,-1=注销',
    
    -- 安全
    password_hash VARCHAR(255),
    salt VARCHAR(64),
    last_login_at TIMESTAMP,
    last_login_ip VARCHAR(45),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT users_phone_check CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_user_type ON users(user_type);

COMMENT ON TABLE users IS '用户表';
```

---

### 2.5 打卡记录表 (checkins)

**用途**: 存储用户打卡记录

```sql
CREATE TABLE checkins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    poi_id BIGINT NOT NULL REFERENCES pois(id),
    poem_id BIGINT NOT NULL REFERENCES poems(id),
    
    -- 地理信息
    location GEOMETRY(POINT, 4326) NOT NULL COMMENT '打卡坐标',
    gps_accuracy FLOAT COMMENT 'GPS 精度 (米)',
    distance INT COMMENT '到 POI 中心的距离 (米)',
    
    -- 设备信息 (防作弊)
    device_id VARCHAR(128) NOT NULL,
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    is_emulator BOOLEAN DEFAULT FALSE,
    is_rooted BOOLEAN DEFAULT FALSE,
    
    -- 风控信息
    risk_score INT DEFAULT 0 COMMENT '风险评分 (0-100)',
    risk_reasons JSONB COMMENT '触发的风控规则',
    review_status VARCHAR(20) DEFAULT 'none' CHECK (review_status IN ('none', 'pending', 'approved', 'rejected')),
    
    -- 打卡卡片
    card_url VARCHAR(512),
    
    checkin_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT checkins_user_poi_time UNIQUE (user_id, poi_id, checkin_time)
);

CREATE INDEX idx_checkins_user ON checkins(user_id, checkin_time DESC);
CREATE INDEX idx_checkins_poi ON checkins(poi_id, checkin_time DESC);
CREATE INDEX idx_checkins_device ON checkins(device_id, checkin_time DESC);
CREATE INDEX idx_checkins_risk_score ON checkins(risk_score DESC);
CREATE INDEX idx_checkins_review_status ON checkins(review_status) WHERE review_status != 'none';

COMMENT ON TABLE checkins IS '打卡记录表';
```

---

### 2.6 视频生成任务表 (video_jobs)

**用途**: 存储 AI 视频生成任务

```sql
CREATE TABLE video_jobs (
    id BIGSERIAL PRIMARY KEY,
    job_id VARCHAR(64) UNIQUE NOT NULL COMMENT '任务 ID (UUID)',
    user_id BIGINT NOT NULL REFERENCES users(id),
    poem_id BIGINT NOT NULL REFERENCES poems(id),
    
    -- 参数
    style VARCHAR(50) DEFAULT 'watercolor' COMMENT '风格',
    duration INT DEFAULT 15 COMMENT '时长 (秒)',
    
    -- 状态
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'TIMEOUT', 'CANCELLED')),
    progress INT DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    
    -- 结果
    video_url VARCHAR(512),
    thumbnail_url VARCHAR(512),
    file_size BIGINT COMMENT '文件大小 (字节)',
    
    -- 错误信息
    error_msg TEXT,
    retry_count INT DEFAULT 0,
    
    -- 成本
    cost DECIMAL(10, 2) COMMENT '成本 (元)',
    
    -- 时间统计
    queue_time TIMESTAMP COMMENT '入队时间',
    start_time TIMESTAMP COMMENT '开始执行时间',
    finish_time TIMESTAMP COMMENT '完成时间',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_video_jobs_job_id ON video_jobs(job_id);
CREATE INDEX idx_video_jobs_user ON video_jobs(user_id, created_at DESC);
CREATE INDEX idx_video_jobs_status ON video_jobs(status, created_at);
CREATE INDEX idx_video_jobs_poem_style_duration ON video_jobs(poem_id, style, duration) WHERE status = 'SUCCESS';

COMMENT ON TABLE video_jobs IS 'AI 视频生成任务表';
```

---

### 2.7 风控审核队列表 (risk_review_queue)

**用途**: 存储需要人工审核的风险记录

```sql
CREATE TABLE risk_review_queue (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    checkin_id BIGINT REFERENCES checkins(id),
    poi_id BIGINT REFERENCES pois(id),
    
    -- 风险信息
    risk_score INT NOT NULL,
    risk_reasons JSONB COMMENT '触发的规则详情',
    
    -- 优先级
    priority VARCHAR(10) DEFAULT 'P2' CHECK (priority IN ('P0', 'P1', 'P2', 'P3')),
    
    -- 审核信息
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    reviewer_id BIGINT REFERENCES users(id),
    review_time TIMESTAMP,
    review_note TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_risk_review_status_priority ON risk_review_queue(status, priority, created_at) WHERE status = 'PENDING';
CREATE INDEX idx_risk_review_user ON risk_review_queue(user_id);

COMMENT ON TABLE risk_review_queue IS '风控审核队列';
```

---

### 2.8 旅行路线表 (routes)

**用途**: 存储城市旅行路线

```sql
CREATE TABLE routes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city_code VARCHAR(10) NOT NULL,
    
    -- 路线类型
    route_type VARCHAR(20) DEFAULT 'half_day' CHECK (route_type IN ('half_day', 'full_day', 'multi_day')),
    
    -- 统计信息
    estimated_duration INT COMMENT '预计时长 (分钟)',
    distance INT COMMENT '总距离 (米)',
    pois_count INT DEFAULT 0,
    
    -- 路线点位 (有序)
    pois JSONB NOT NULL COMMENT '[{"poi_id":123,"order":1},{"poi_id":456,"order":2}]',
    
    -- 描述
    description TEXT,
    cover_image_url VARCHAR(512),
    
    -- 状态
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1)),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_routes_city ON routes(city_code, status);
CREATE INDEX idx_routes_type ON routes(route_type);

COMMENT ON TABLE routes IS '旅行路线表';
```

---

### 2.9 用户路线进度表 (user_route_progress)

**用途**: 记录用户在路线上的打卡进度

```sql
CREATE TABLE user_route_progress (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    route_id BIGINT NOT NULL REFERENCES routes(id),
    
    -- 进度
    completed_pois JSONB DEFAULT '[]' COMMENT '已完成的 POI ID 列表',
    progress_percent INT DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    
    -- 时间
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT user_route_progress_unique UNIQUE (user_id, route_id)
);

CREATE INDEX idx_user_route_progress_user ON user_route_progress(user_id);
CREATE INDEX idx_user_route_progress_route ON user_route_progress(route_id);

COMMENT ON TABLE user_route_progress IS '用户路线进度表';
```

---

## 3. 辅助表

### 3.1 用户行为日志表 (user_events)

**用途**: 存储埋点事件 (用于分析和 ABtest)

```sql
CREATE TABLE user_events (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    event_id VARCHAR(100) NOT NULL COMMENT '事件 ID (如 poem_detail_enter)',
    
    -- 事件属性
    properties JSONB COMMENT '事件属性',
    
    -- 上下文
    session_id VARCHAR(64),
    device_id VARCHAR(128),
    ip_address VARCHAR(45),
    
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 分区表 (按月分区)
CREATE TABLE user_events_202603 PARTITION OF user_events
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE INDEX idx_user_events_user_time ON user_events(user_id, event_time DESC);
CREATE INDEX idx_user_events_event_id ON user_events(event_id, event_time DESC);

COMMENT ON TABLE user_events IS '用户行为日志表';
```

---

### 3.2 系统配置表 (system_config)

**用途**: 存储系统配置 (限额、开关等)

```sql
CREATE TABLE system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    value_type VARCHAR(20) DEFAULT 'string' CHECK (value_type IN ('string', 'int', 'float', 'bool', 'json')),
    description TEXT,
    
    updated_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 初始化配置
INSERT INTO system_config (config_key, config_value, value_type, description) VALUES
('video.quota.normal', '3', 'int', '普通用户每日视频生成限额'),
('video.quota.vip', '10', 'int', 'VIP 用户每日视频生成限额'),
('checkin.cooldown_seconds', '3600', 'int', '打卡冷却时间 (秒)'),
('ai.cost.circuit_breaker', 'false', 'bool', 'AI 成本熔断开关');

COMMENT ON TABLE system_config IS '系统配置表';
```

---

## 4. 数据库优化策略

### 4.1 分区策略

**user_events 表**: 按月分区 (减少单表数据量)

```sql
-- 自动创建未来 3 个月的分区
CREATE OR REPLACE FUNCTION create_monthly_partitions()
RETURNS VOID AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..2 LOOP
        start_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month' * i);
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'user_events_' || TO_CHAR(start_date, 'YYYYMM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF user_events FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 定时任务: 每月 1 号执行
SELECT cron.schedule('create-partitions', '0 0 1 * *', 'SELECT create_monthly_partitions()');
```

---

### 4.2 索引优化

**复合索引**:

```sql
-- 推荐服务: 按城市 + 浏览量查询热门诗词
CREATE INDEX idx_poi_poems_city_popularity ON poi_poems(poi_id, relevance_score DESC)
    INCLUDE (poem_id);

-- 打卡历史: 按用户 + 时间倒序
CREATE INDEX idx_checkins_user_time_desc ON checkins(user_id, checkin_time DESC)
    INCLUDE (poi_id, poem_id);
```

**部分索引** (减少索引大小):

```sql
-- 仅索引未完成的任务
CREATE INDEX idx_video_jobs_pending ON video_jobs(created_at)
    WHERE status IN ('PENDING', 'RUNNING');

-- 仅索引待审核的风控记录
CREATE INDEX idx_risk_review_pending ON risk_review_queue(created_at)
    WHERE status = 'PENDING';
```

---

### 4.3 数据清理策略

**定期清理过期数据**:

```sql
-- 清理 90 天前的用户事件日志
DELETE FROM user_events WHERE event_time < NOW() - INTERVAL '90 days';

-- 清理 30 天前的成功视频任务 (保留失败记录)
DELETE FROM video_jobs WHERE status = 'SUCCESS' AND finish_time < NOW() - INTERVAL '30 days';

-- 归档 1 年前的打卡记录到历史表
INSERT INTO checkins_archive SELECT * FROM checkins WHERE checkin_time < NOW() - INTERVAL '1 year';
DELETE FROM checkins WHERE checkin_time < NOW() - INTERVAL '1 year';
```

---

## 5. 数据初始化

### 5.1 初始化脚本

```sql
-- 1. 创建数据库
CREATE DATABASE mishi ENCODING 'UTF8';

-- 2. 启用扩展
\c mishi
CREATE EXTENSION postgis;
CREATE EXTENSION pg_trgm;  -- 模糊搜索
CREATE EXTENSION pg_cron;  -- 定时任务

-- 3. 执行建表脚本
\i schema.sql

-- 4. 导入初始数据
\i data/poems_init.sql
\i data/pois_init.sql
\i data/poi_poems_init.sql
```

---

## 6. 备份与恢复

### 6.1 备份策略

**全量备份**: 每日凌晨 2:00

```bash
pg_dump -h localhost -U postgres -d mishi -F c -f /backup/mishi_$(date +%Y%m%d).dump
```

**增量备份**: 启用 WAL 归档

```conf
# postgresql.conf
archive_mode = on
archive_command = 'cp %p /archive/%f'
```

---

## 7. 交付物清单

- [x] 数据库表结构设计文档 (本文档)
- [ ] schema.sql (DDL 脚本)
- [ ] migration 脚本 (后续版本升级)
- [ ] 初始化数据 SQL
- [ ] 数据字典 (自动生成)

---

**文档状态**: ✅ 已交付  
**输出时间**: 2026-03-14 18:52  
**责任人**: Arch Agent  
**审核状态**: 待 Coordinator 评审
