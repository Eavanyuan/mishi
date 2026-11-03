# 季节推荐算法技术方案

**文档版本**: v1.0  
**输出时间**: 2026-03-14 12:26  
**责任人**: Arch Agent  
**依赖方**: Backend Agent (Recommend Service)  
**前置依赖**: D001 核心功能拆解需求 ✅  
**状态**: 待 Coordinator 评审

---

## 1. 问题定义

### 1.1 需求来源

基于 **D001 核心功能拆解需求 - 用户故事 4.1**:

> 用户希望系统根据当前季节推荐最契合的诗词,实现"诗中有景、景中有诗"的时令共鸣。

**核心挑战**:
- 如何量化"季节匹配度"?
- 如何在保证推荐相关性的同时突出季节因素?
- 如何平衡多个排序因子 (距离/热度/季节/时段)?

### 1.2 业务目标

| 目标 | 指标 | 目标值 |
|-----|------|--------|
| 季节推荐点击率 | 季节匹配推荐点击率 | >= 30% |
| 推荐相关性 | 用户满意度 | >= 4.0/5.0 |
| 性能 | P95 推荐接口延迟 | < 300ms |

---

## 2. 方案设计

### 2.1 排序算法总览

采用**多因子加权排序**模型:

```
推荐得分 = 距离因子 × 0.4 
         + 热度因子 × 0.3 
         + 季节因子 × 0.2 
         + 时段因子 × 0.1
```

**权重设计理由**:
- **距离因子 (40%)**: 地理相关性是核心,权重最高
- **热度因子 (30%)**: 保证推荐内容质量,避免冷门诗词
- **季节因子 (20%)**: 差异化亮点,但不能过度影响相关性
- **时段因子 (10%)**: 微调项,增强体验细节

---

### 2.2 距离因子计算

**公式**:

```python
distance_score = max(0, 1 - (distance / max_distance))

其中:
- distance: 用户到 POI 的实际距离 (米)
- max_distance: 最大有效距离 = 5000 米 (超过视为不相关)
```

**示例**:

| 距离 | 得分 |
|-----|------|
| 0m | 1.0 |
| 500m | 0.9 |
| 1000m | 0.8 |
| 2500m | 0.5 |
| 5000m | 0.0 |

**特殊处理**:
- 距离 < 100m: 得分 = 1.0 (完美匹配)
- 距离 > 5000m: 直接过滤,不参与推荐

---

### 2.3 热度因子计算

**公式**:

```python
热度得分 = log(view_count + 1) / log(max_view_count + 1)

其中:
- view_count: 诗词累计浏览次数
- max_view_count: 库中最热门诗词浏览次数
```

**归一化**: 使用对数函数压缩热度差异,避免头部诗词过度占优

**冷启动策略** (新增 ✨):

```python
def calculate_popularity_score(view_count, max_view_count):
    """计算热度得分,支持冷启动"""
    if view_count == 0:
        # 冷启动: 新诗词默认热度 = 平均值的 50%
        return 0.5
    
    return math.log(view_count + 1) / math.log(max_view_count + 1)
```

**理由**: 
- 新诗词 (view_count=0) 如果得分为 0, 将永远无法被推荐
- 给予 0.5 的基础分,保证新内容有曝光机会
- 随着浏览次数增加,得分自然上升

**示例**:

| 浏览次数 | 得分 (假设 max=100000) | 说明 |
|---------|---------------------|------|
| 0 | 0.5 | 🆕 冷启动默认值 |
| 100 | 0.4 | 自然得分 |
| 1000 | 0.6 | 自然得分 |
| 10000 | 0.8 | 自然得分 |
| 100000 | 1.0 | 最热门 |

---

### 2.4 季节因子计算 (核心)

#### 2.4.1 季节定义

采用**二十四节气**作为季节标准:

| 季节 | 节气 | 时间范围 (大致) |
|-----|------|--------------|
| 春 | 立春、雨水、惊蛰、春分、清明、谷雨 | 2月初 - 5月初 |
| 夏 | 立夏、小满、芒种、夏至、小暑、大暑 | 5月初 - 8月初 |
| 秋 | 立秋、处暑、白露、秋分、寒露、霜降 | 8月初 - 11月初 |
| 冬 | 立冬、小雪、大雪、冬至、小寒、大寒 | 11月初 - 2月初 |

**数据来源**: 天文历法算法库 (如 `chinese-calendar` Python 库)

#### 2.4.2 诗词季节标注

**数据字段**: `poems` 表增加字段

```sql
ALTER TABLE poems ADD COLUMN best_seasons JSON;
ALTER TABLE poems ADD COLUMN solar_terms JSON;

-- 示例数据
{
  "poem_id": 1,
  "best_seasons": ["春"],  -- 最佳季节
  "solar_terms": ["清明", "谷雨"]  -- 相关节气
}
```

**标注规则**:
- 单季节诗词: `["春"]` (如《春晓》)
- 多季节诗词: `["春", "夏"]` (如《钱塘湖春行》描绘早春)
- 无明显季节: `[]` (如《静夜思》)

**内容审核**: 人工审核 + AI 辅助标注

#### 2.4.3 季节匹配度计算

**公式**:

```python
def season_score(poem_seasons, current_season):
    if not poem_seasons:  # 无季节标注
        return 0.5  # 中性分数
    
    if current_season in poem_seasons:
        if len(poem_seasons) == 1:
            return 1.0  # 完全匹配
        else:
            return 0.8  # 部分匹配 (多季节诗词)
    else:
        return 0.3  # 跨季阅读 (不完全排除)
```

**示例**:

| 诗词季节标注 | 当前季节 | 匹配度得分 |
|------------|---------|----------|
| `["春"]` | 春 | 1.0 (完美) |
| `["春", "夏"]` | 春 | 0.8 (部分) |
| `["秋"]` | 春 | 0.3 (跨季) |
| `[]` | 春 | 0.5 (中性) |

**设计理由**:
- 完全匹配得分高 (1.0),强化季节体验
- 跨季不完全排除 (0.3),保留内容多样性
- 无标注给中性分 (0.5),避免过度惩罚

---

### 2.5 时段因子计算

**目标**: 细化推荐,如清晨推荐《春晓》,傍晚推荐《登鹳雀楼》

**公式**:

```python
def time_period_score(poem_time_tags, current_hour):
    """
    poem_time_tags: ["清晨", "日出"] 或 ["傍晚", "日落"]
    current_hour: 0-23
    """
    time_mapping = {
        "清晨": (5, 7),
        "上午": (8, 11),
        "正午": (12, 13),
        "下午": (14, 17),
        "傍晚": (18, 19),
        "夜晚": (20, 23),
        "深夜": (0, 4)
    }
    
    if not poem_time_tags:
        return 0.5  # 中性
    
    for tag in poem_time_tags:
        start, end = time_mapping[tag]
        if start <= current_hour <= end:
            return 1.0  # 匹配
    
    return 0.3  # 不匹配
```

**数据字段**: `poems` 表增加 `time_period_tags JSON`

**示例**:

| 诗词 | 时段标签 | 当前时间 | 得分 |
|-----|---------|---------|------|
| 《春晓》 | `["清晨"]` | 06:00 | 1.0 |
| 《静夜思》 | `["夜晚"]` | 06:00 | 0.3 |
| 《登鹳雀楼》 | `["傍晚"]` | 18:30 | 1.0 |

**优先级**: P1 (V1 可选,V2 实现)

---

### 2.6 综合排序示例

**场景**: 用户在"黄鹤楼"附近 (春季,清晨 06:30)

| 诗词 | 距离得分 | 热度得分 | 季节得分 | 时段得分 | **最终得分** |
|-----|---------|---------|---------|---------|-----------|
| 《黄鹤楼送孟浩然之广陵》 | 1.0 | 0.9 | 1.0 (春) | 0.5 | **0.91** ✅ |
| 《登黄鹤楼》 | 1.0 | 0.8 | 0.3 (秋) | 0.5 | **0.75** |
| 《春晓》 | 0.5 | 0.7 | 1.0 (春) | 1.0 (清晨) | **0.69** |

**推荐顺序**: 《黄鹤楼送孟浩然之广陵》> 《登黄鹤楼》> 《春晓》

**分析**:
- 距离 + 季节双重加持 → 第一名
- 距离高但季节不匹配 → 第二名
- 季节 + 时段匹配但距离远 → 第三名

---

## 3. 备选方案对比

### 方案 A: 基于规则的加权排序 (推荐) ✅

**优点**:
- 逻辑透明,可解释性强
- 权重可灵活调整,快速迭代
- 性能开销低 (< 100ms)
- 无需训练数据和模型维护

**缺点**:
- 权重需人工调优
- 无法捕捉复杂的用户偏好

**适用场景**: MVP 阶段,快速验证产品假设

---

### 方案 B: 基于机器学习的排序模型

**技术栈**: LambdaMART / XGBoost

**特征**:
- 距离、热度、季节、时段 (同方案 A)
- 用户历史行为 (点击率、完读率)
- 诗词语义相似度 (Embedding)

**优点**:
- 排序效果更优 (理论上)
- 可学习用户个性化偏好

**缺点**:
- 需要大量标注数据 (点击日志)
- 模型训练和维护成本高
- 冷启动问题 (新用户/新诗词)
- 推理延迟较高 (50-100ms)

**适用场景**: V2 阶段,积累足够数据后迭代

---

### 方案 C: 纯季节优先排序

**算法**: 仅按季节匹配度排序,忽略距离和热度

**优点**:
- 季节特征突出

**缺点**:
- 地理相关性丧失 (用户在黄鹤楼却推荐西湖诗词)
- 用户体验差

**结论**: ❌ 不可行

---

### 方案对比总结

| 维度 | 方案 A (规则) | 方案 B (ML) | 方案 C (纯季节) |
|-----|-------------|-----------|--------------|
| 开发成本 | 低 | 高 | 极低 |
| 性能 | < 100ms | 50-100ms | < 50ms |
| 可解释性 | ✅ 高 | ❌ 低 | ✅ 高 |
| 个性化 | ❌ 无 | ✅ 有 | ❌ 无 |
| 冷启动 | ✅ 无问题 | ❌ 需要数据 | ✅ 无问题 |
| 适用阶段 | MVP | V2 | ❌ 不推荐 |

**推荐**: 方案 A (V1) → 方案 B (V2 迭代)

---

## 4. 技术实现

### 4.1 数据库表设计

#### 4.1.1 诗词表扩展

```sql
ALTER TABLE poems ADD COLUMN best_seasons JSON COMMENT '最佳季节 ["春","夏"]';
ALTER TABLE poems ADD COLUMN solar_terms JSON COMMENT '相关节气 ["清明","谷雨"]';
ALTER TABLE poems ADD COLUMN time_period_tags JSON COMMENT '时段标签 ["清晨","傍晚"]';
ALTER TABLE poems ADD COLUMN view_count INT DEFAULT 0 COMMENT '累计浏览次数';
ALTER TABLE poems ADD INDEX idx_view_count (view_count);
```

#### 4.1.2 POI 诗词关联表

```sql
CREATE TABLE poi_poems (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    poi_id BIGINT NOT NULL COMMENT 'POI ID',
    poem_id BIGINT NOT NULL COMMENT '诗词 ID',
    distance INT NOT NULL COMMENT '诗词描述地点到 POI 的距离 (米)',
    relevance_score FLOAT DEFAULT 1.0 COMMENT '人工标注的相关性 (0-1)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_poi (poi_id),
    INDEX idx_poem (poem_id)
);
```

**说明**: `relevance_score` 用于人工调整特殊关联,默认 1.0

---

### 4.2 推荐接口设计

#### 接口规格

```http
GET /poems/recommend

Query Parameters:
- lat: float (必填) 用户纬度
- lon: float (必填) 用户经度
- limit: int (可选,默认 10) 返回数量
- season: string (可选) 强制季节 (调试用)
```

#### 响应示例

```json
{
  "code": 0,
  "data": {
    "poems": [
      {
        "poem_id": 123,
        "title": "黄鹤楼送孟浩然之广陵",
        "author": "李白",
        "dynasty": "唐",
        "distance": 50,
        "season_tag": "春",
        "solar_term": "清明",
        "score": 0.91,
        "score_breakdown": {
          "distance": 0.40,
          "popularity": 0.27,
          "season": 0.20,
          "time_period": 0.04
        }
      }
    ],
    "current_season": "春",
    "current_solar_term": "清明",
    "nearby_poi": {
      "poi_id": 456,
      "name": "黄鹤楼",
      "distance": 50
    }
  }
}
```

**说明**: `score_breakdown` 用于调试和 ABtest

---

### 4.3 推荐服务伪代码

```python
def recommend_poems(lat, lon, limit=10):
    # 1. 获取当前季节和时段
    current_season = get_current_season()  # "春"
    current_hour = get_current_hour()  # 6
    
    # 2. 查询附近 POI (5km 内)
    nearby_pois = geo_service.get_nearby_pois(lat, lon, radius=5000)
    if not nearby_pois:
        return []  # 附近无 POI
    
    # 3. 查询关联诗词
    candidate_poems = []
    for poi in nearby_pois:
        poems = db.query("""
            SELECT p.*, pp.distance, pp.relevance_score
            FROM poems p
            JOIN poi_poems pp ON p.id = pp.poem_id
            WHERE pp.poi_id = %s
        """, poi.id)
        candidate_poems.extend(poems)
    
    # 4. 计算推荐得分
    for poem in candidate_poems:
        # 距离得分
        distance_score = max(0, 1 - poem.distance / 5000) * 0.4
        
        # 热度得分
        max_views = get_max_view_count()
        popularity_score = log(poem.view_count + 1) / log(max_views + 1) * 0.3
        
        # 季节得分
        season_score = calculate_season_score(poem.best_seasons, current_season) * 0.2
        
        # 时段得分
        time_score = calculate_time_score(poem.time_period_tags, current_hour) * 0.1
        
        # 综合得分
        poem.final_score = distance_score + popularity_score + season_score + time_score
        poem.final_score *= poem.relevance_score  # 人工调整因子
    
    # 5. 排序并返回 Top N
    candidate_poems.sort(key=lambda x: x.final_score, reverse=True)
    return candidate_poems[:limit]
```

---

### 4.4 季节计算服务

**技术选型**: 使用 Python `chinese-calendar` 库

```python
import datetime
from chinese_calendar import is_in_lieu, get_holiday_detail

def get_current_season():
    """获取当前季节"""
    today = datetime.date.today()
    month = today.month
    
    if 2 <= month <= 4:
        return "春"
    elif 5 <= month <= 7:
        return "夏"
    elif 8 <= month <= 10:
        return "秋"
    else:
        return "冬"

def get_current_solar_term():
    """获取当前节气 (需要精确天文历法库)"""
    # 使用 jieqi 库或调用第三方 API
    # 返回如: "清明"
    pass
```

**缓存策略**: 季节和节气每天计算一次,Redis 缓存

```redis
season:2026-03-14 = "春"
solar_term:2026-03-14 = "清明"
TTL: 86400 秒
```

---

## 5. 性能优化

### 5.1 性能目标

| 指标 | 目标值 |
|-----|--------|
| P95 延迟 | < 300ms |
| P99 延迟 | < 500ms |
| QPS | >= 1000 |

### 5.2 优化策略

#### 5.2.1 数据库查询优化

**索引**:

```sql
-- POI 诗词关联表索引
CREATE INDEX idx_poi_distance ON poi_poems(poi_id, distance);

-- 诗词表索引
CREATE INDEX idx_view_count ON poems(view_count DESC);
```

**查询优化**:
- 使用 `LIMIT` 减少返回行数
- 避免 `SELECT *`,仅查询必要字段

#### 5.2.2 缓存策略

**热门诗词缓存** (Redis):

```python
# 缓存 Top 100 热门诗词的元数据
cache_key = f"poem:{poem_id}"
redis.setex(cache_key, 3600, json.dumps(poem_data))
```

**POI 附近诗词缓存**:

```python
# 缓存每个 POI 关联的诗词列表
cache_key = f"poi_poems:{poi_id}"
redis.setex(cache_key, 3600, json.dumps(poem_ids))
```

**缓存命中率目标**: >= 70%

#### 5.2.3 预计算

**每日凌晨任务**:
- 更新 `poems.view_count` (从埋点日志聚合)
- 预计算热门诗词排行榜
- 更新季节/节气缓存

---

### 5.3 性能评估

**假设**:
- 附近 POI: 5 个
- 每个 POI 关联诗词: 20 首
- 候选诗词总数: 100 首

**时间分解**:

| 步骤 | 耗时 |
|-----|------|
| 查询附近 POI | 20ms (PostGIS 索引) |
| 查询关联诗词 | 50ms (索引 + 缓存) |
| 计算推荐得分 | 10ms (内存计算) |
| 排序并返回 | 5ms |
| **总计** | **85ms** ✅ |

**结论**: 满足 P95 < 300ms 目标

---

## 6. ABtest 方案

### 6.1 实验设计

**对照组** (Baseline):
```
推荐得分 = 距离因子 × 0.5 + 热度因子 × 0.5
(无季节因子)
```

**实验组** (Treatment):
```
推荐得分 = 距离因子 × 0.4 + 热度因子 × 0.3 + 季节因子 × 0.2 + 时段因子 × 0.1
```

**流量分配**: 50% vs 50%

**实验周期**: 2 周

### 6.2 评估指标

| 指标 | 定义 | 目标 |
|-----|------|------|
| 点击率 (CTR) | 推荐卡点击数 / 曝光数 | 提升 >= 10% |
| 详情页完读率 | 滚动到底部数 / 详情页进入数 | 提升 >= 5% |
| 朗读播放率 | 点击朗读数 / 详情页进入数 | 提升 >= 5% |
| 用户满意度 | 问卷调研 | >= 4.0/5.0 |

### 6.3 回滚策略

**触发条件**:
- CTR 下降 > 10%
- P95 延迟 > 500ms
- 用户投诉增加 > 20%

**回滚操作**:
- 配置中心关闭季节因子权重 (设为 0)
- 恢复为纯距离+热度排序

---

## 7. 风险与应对

| 风险 | 概率 | 影响 | 应对策略 |
|-----|------|------|---------|
| 季节标注错误 | 中 | 高 | 内容审核双审流程 + 用户反馈纠错 |
| 权重调优困难 | 中 | 中 | ABtest 多组实验,数据驱动决策 |
| 性能不达标 | 低 | 高 | 缓存优化 + 数据库索引 + 降级策略 |
| 用户不买账 (季节推荐点击率低) | 中 | 中 | 降低季节权重或回滚到 Baseline |

---

## 8. 里程碑计划

| 阶段 | 任务 | 责任人 | 截止时间 |
|-----|------|--------|---------|
| **Week 3** | 数据库表结构设计 | Backend | 2026-03-17 |
| **Week 4** | 季节标注工具开发 | Backend | 2026-03-24 |
| **Week 5** | 推荐接口实现 (V1) | Backend | 2026-03-31 |
| **Week 6** | 性能测试与优化 | Backend | 2026-04-07 |
| **Week 7** | ABtest 上线 | Product | 2026-04-14 |
| **Week 9** | ABtest 结果评估 | Product | 2026-04-28 |

---

## 9. 可观测性

### 9.1 监控指标

| 指标 | 告警阈值 |
|-----|---------|
| 推荐接口 P95 延迟 | > 300ms |
| 推荐接口 P99 延迟 | > 500ms |
| 推荐接口错误率 | > 1% |
| 缓存命中率 | < 60% |

### 9.2 日志记录

**推荐请求日志**:

```json
{
  "user_id": 12345,
  "lat": 39.9047,
  "lon": 116.4074,
  "season": "春",
  "solar_term": "清明",
  "nearby_pois": [456, 789],
  "candidate_count": 50,
  "recommended_poems": [123, 456, 789],
  "latency_ms": 85,
  "cache_hit": true
}
```

---

## 10. 交付物清单

- [x] 排序算法设计文档 (本文档)
- [ ] 数据库表 DDL
- [ ] 推荐服务 API 接口文档
- [ ] 季节标注工具设计
- [ ] ABtest 实验方案
- [ ] 性能测试报告

---

**文档状态**: ✅ 已交付  
**输出时间**: 2026-03-14 12:26  
**责任人**: Arch Agent  
**审核状态**: 待 Coordinator 评审
