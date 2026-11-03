# 觅诗 API 契约 v1.1

**文档版本**: v1.1  
**输出时间**: 2026-03-14 18:47  
**责任人**: Arch Agent  
**状态**: 🔒 **已冻结** - 仅允许新增可选字段,不允许破坏性变更  
**生效时间**: 2026-03-16 18:00

---

## 1. 版本管理规则

### 1.1 冻结规则

**v1.1 冻结后允许**:
- ✅ 新增可选字段 (optional)
- ✅ 新增新接口
- ✅ 错误码新增

**v1.1 冻结后禁止**:
- ❌ 删除已有字段
- ❌ 修改字段类型
- ❌ 修改字段语义
- ❌ 修改必填/可选属性 (required → optional 允许, optional → required 禁止)

### 1.2 版本演进

- **v1.0**: 初版 (2026-03-10)
- **v1.1**: 增加季节推荐、防作弊、AI 成本控制 (2026-03-16 冻结)
- **v1.2**: 计划增加社交功能 (2026-05-01)

---

## 2. 通用规范

### 2.1 基础信息

**Base URL**: `https://api.mishi.app/v1`

**协议**: HTTPS  
**编码**: UTF-8  
**内容类型**: `application/json`

### 2.2 认证

**Header**:

```http
Authorization: Bearer <access_token>
X-Device-Id: <device_id>
X-App-Version: <app_version>
```

**Token 获取**: 
- 用户登录后获取 JWT Token
- Token 有效期: 30 天
- 刷新机制: `POST /auth/refresh`

### 2.3 分页规范 (新增 ✨)

**适用接口**: 所有列表查询接口

**请求参数**:

| 参数 | 类型 | 必填 | 说明 | 默认值 | 最大值 |
|-----|------|-----|------|--------|--------|
| limit | int | 否 | 每页数量 | 20 | 100 |
| offset | int | 否 | 偏移量 (从 0 开始) | 0 | - |

**响应格式**:

```json
{
  "code": 0,
  "data": {
    "items": [...],
    "total": 150,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

**示例**:
- 第 1 页: `?limit=20&offset=0`
- 第 2 页: `?limit=20&offset=20`
- 第 3 页: `?limit=20&offset=40`

---

### 2.4 限流规范 (新增 ✨)

**限流规则**:

| 维度 | 限制 | 窗口 | 超限响应 |
|-----|------|------|---------|
| 单用户 | 100 次/秒 | 1 秒滑动窗口 | 429 Too Many Requests |
| 单 IP | 1000 次/秒 | 1 秒滑动窗口 | 429 Too Many Requests |
| 单接口 | 见接口定义 | - | - |

**特殊接口限流**:

| 接口 | 限流规则 |
|-----|---------|
| POST /video/jobs | 单用户 3 次/天 (配额控制) |
| POST /checkins | 单用户 20 次/天 |
| GET /poems/recommend | 单用户 100 次/分钟 |

**限流响应**:

```json
{
  "code": 42901,
  "message": "请求过于频繁,请稍后再试",
  "error_detail": {
    "retry_after": 60,
    "limit": 100,
    "window": "1s"
  },
  "timestamp": 1710394800
}
```

**Header 提示**:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1710394860
```

---

### 2.5 通用响应格式

**成功响应**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    // 业务数据
  },
  "timestamp": 1710394800
}
```

**错误响应**:

```json
{
  "code": 40001,
  "message": "参数错误: lat 字段缺失",
  "error_detail": {
    "field": "lat",
    "reason": "required field missing"
  },
  "timestamp": 1710394800
}
```

### 2.4 通用错误码

| Code | 说明 | HTTP 状态码 |
|------|------|------------|
| 0 | 成功 | 200 |
| 40001 | 参数错误 | 400 |
| 40101 | 未授权 | 401 |
| 40301 | 禁止访问 | 403 |
| 40401 | 资源不存在 | 404 |
| 40901 | 冲突 (如重复提交) | 409 |
| 42901 | 请求过于频繁 | 429 |
| 50001 | 服务器内部错误 | 500 |
| 50301 | 服务不可用 | 503 |

---

## 3. Geo Service - 地理服务

### 3.1 查询附近 POI

**接口**: `GET /geo/nearby`

**用途**: 查询用户附近的诗词地点,用于触发推荐

**请求参数**:

| 参数 | 类型 | 必填 | 说明 | 示例 |
|-----|------|-----|------|------|
| lat | float | 是 | 纬度 | 39.9186 |
| lon | float | 是 | 经度 | 116.4074 |
| radius | int | 否 | 查询半径 (米), 默认 5000 | 1000 |
| limit | int | 否 | 返回数量, 默认 10 | 5 |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "pois": [
      {
        "poi_id": 123,
        "name": "黄鹤楼",
        "ancient_name": "黄鹤楼",
        "modern_name": "黄鹤楼景区",
        "location": {
          "lat": 30.5447,
          "lon": 114.2969
        },
        "distance": 50,
        "category": "景点",
        "description": "江南三大名楼之一",
        "poems_count": 15
      }
    ],
    "total": 1
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40001 | lat/lon 参数缺失或格式错误 |
| 40301 | 定位精度不足 |

**性能指标**: P95 < 100ms

---

### 3.2 检查地理围栏 (内部接口)

**接口**: `POST /geo/geofence/check`

**用途**: 检查用户是否在指定 POI 的地理围栏内

**请求体**:

```json
{
  "user_lat": 39.9186,
  "user_lon": 116.4074,
  "poi_id": 123
}
```

**响应**:

```json
{
  "code": 0,
  "data": {
    "in_geofence": true,
    "distance": 45,
    "match_type": "circle",
    "poi_name": "黄鹤楼"
  }
}
```

---

## 4. Recommend Service - 推荐服务

### 4.1 推荐诗词 (含季节因子)

**接口**: `GET /poems/recommend`

**用途**: 基于用户位置、季节、时段推荐诗词

**请求参数**:

| 参数 | 类型 | 必填 | 说明 | 示例 |
|-----|------|-----|------|------|
| lat | float | 是 | 纬度 | 39.9186 |
| lon | float | 是 | 经度 | 116.4074 |
| limit | int | 否 | 返回数量, 默认 10 | 5 |
| season | string | 否 | 强制季节 (调试用) | "春" |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "poems": [
      {
        "poem_id": 456,
        "title": "黄鹤楼送孟浩然之广陵",
        "author": "李白",
        "dynasty": "唐",
        "content": [
          "故人西辞黄鹤楼，",
          "烟花三月下扬州。",
          "孤帆远影碧空尽，",
          "唯见长江天际流。"
        ],
        "preview_line": "故人西辞黄鹤楼",
        "distance": 50,
        "season_tag": "春",
        "solar_term": "清明",
        "score": 0.91,
        "score_breakdown": {
          "distance": 0.40,
          "popularity": 0.27,
          "season": 0.20,
          "time_period": 0.04
        },
        "related_poi": {
          "poi_id": 123,
          "name": "黄鹤楼",
          "distance": 50
        }
      }
    ],
    "current_season": "春",
    "current_solar_term": "清明",
    "current_hour": 14
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40001 | lat/lon 参数错误 |
| 40401 | 附近无 POI |

**性能指标**: P95 < 300ms

---

## 5. Content Service - 内容服务

### 5.1 诗词详情

**接口**: `GET /poems/{poem_id}`

**用途**: 获取诗词完整内容、解读、标签

**路径参数**:

| 参数 | 类型 | 说明 |
|-----|------|------|
| poem_id | int | 诗词 ID |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "poem_id": 456,
    "title": "黄鹤楼送孟浩然之广陵",
    "author": "李白",
    "dynasty": "唐",
    "content": [
      "故人西辞黄鹤楼，",
      "烟花三月下扬州。",
      "孤帆远影碧空尽，",
      "唯见长江天际流。"
    ],
    "tags": ["送别", "友情", "春"],
    
    "best_seasons": ["春"],
    "solar_terms": ["清明", "谷雨"],
    "time_period_tags": [],
    
    "interpretations": {
      "textbook": {
        "source": "人教版初中语文",
        "content": "这首诗描写了诗人在黄鹤楼送别友人孟浩然前往扬州的情景..."
      },
      "academic": {
        "source": "唐诗鉴赏辞典",
        "content": "李白以清新飘逸的笔触..."
      },
      "basic": {
        "source": "AI 生成",
        "content": "李白在黄鹤楼送别好友孟浩然..."
      }
    },
    
    "related_pois": [
      {
        "poi_id": 123,
        "name": "黄鹤楼",
        "relevance_score": 1.0
      }
    ],
    
    "media": {
      "has_audio": true,
      "audio_duration": 25,
      "has_video": false
    },
    
    "stats": {
      "view_count": 12543,
      "like_count": 892,
      "checkin_count": 156
    }
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40401 | 诗词不存在 |

**性能指标**: P95 < 200ms

---

## 6. Media Service - 媒体服务

### 6.1 获取音频 URL

**接口**: `GET /audio/{poem_id}`

**用途**: 获取诗词朗读音频的播放 URL

**路径参数**:

| 参数 | 类型 | 说明 |
|-----|------|------|
| poem_id | int | 诗词 ID |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "audio_url": "https://cdn.mishi.app/audio/456.mp3",
    "duration": 25,
    "format": "mp3",
    "bitrate": 128,
    "narrator": "AI 女声",
    "ambience_available": true,
    "ambience_url": "https://cdn.mishi.app/audio/456_ambience.mp3"
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40401 | 音频不存在 |

**性能指标**: P95 < 100ms (CDN 加速)

---

## 7. Checkin Service - 打卡服务

### 7.1 提交打卡

**接口**: `POST /checkins`

**用途**: 用户在诗词地点打卡

**请求体**:

```json
{
  "poi_id": 123,
  "poem_id": 456,
  "lat": 30.5447,
  "lon": 114.2969,
  "gps_accuracy": 20,
  "device_info": {
    "device_id": "abc123",
    "device_model": "iPhone 14 Pro",
    "os_version": "iOS 17.0",
    "is_emulator": false,
    "is_rooted": false
  }
}
```

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "checkin_id": 789,
    "poi_name": "黄鹤楼",
    "poem_title": "黄鹤楼送孟浩然之广陵",
    "checkin_time": "2026-03-14T18:00:00+08:00",
    "badge_unlocked": {
      "badge_id": 1,
      "badge_name": "黄鹤楼探访者",
      "badge_icon": "https://cdn.mishi.app/badges/1.png"
    },
    "card_url": "https://cdn.mishi.app/cards/789.png"
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40001 | 参数错误 |
| 40301 | 距离过远 (> 100 米) |
| 40302 | 定位精度不足 (> 50 米) |
| 40303 | 重复打卡 (冷却期内) |
| 40304 | 检测到虚拟定位 |
| 40305 | 速度异常 |
| 40901 | 重复请求 (幂等拦截) |

**性能指标**: P95 < 200ms (含风控)

---

### 7.2 查询打卡历史

**接口**: `GET /checkins/history`

**请求参数**:

| 参数 | 类型 | 必填 | 说明 | 示例 |
|-----|------|-----|------|------|
| user_id | int | 否 | 用户 ID (不传则查询当前用户) | 12345 |
| limit | int | 否 | 返回数量, 默认 20 | 10 |
| offset | int | 否 | 偏移量, 默认 0 | 0 |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "checkins": [
      {
        "checkin_id": 789,
        "poi_name": "黄鹤楼",
        "poem_title": "黄鹤楼送孟浩然之广陵",
        "checkin_time": "2026-03-14T18:00:00+08:00",
        "location": {
          "lat": 30.5447,
          "lon": 114.2969
        },
        "card_url": "https://cdn.mishi.app/cards/789.png"
      }
    ],
    "total": 15,
    "stats": {
      "total_checkins": 15,
      "total_pois": 8,
      "total_cities": 3
    }
  }
}
```

---

## 8. AI Orchestrator - AI 编排服务

### 8.1 提交视频生成任务

**接口**: `POST /video/jobs`

**用途**: 提交 AI 场景动画生成任务

**请求体**:

```json
{
  "poem_id": 456,
  "style": "watercolor",
  "duration": 15
}
```

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "job_id": "abc-123-def",
    "status": "PENDING",
    "estimated_time": 120,
    "message": "任务已提交,预计 2 分钟内完成"
  }
}
```

**缓存命中响应**:

```json
{
  "code": 0,
  "data": {
    "job_id": null,
    "status": "CACHE_HIT",
    "video_url": "https://cdn.mishi.app/videos/456_watercolor_15.mp4",
    "cache_age_hours": 12,
    "message": "缓存命中,秒级返回"
  }
}
```

**错误码**:

| Code | 说明 |
|------|------|
| 40301 | 配额不足 (今日生成次数已用完) |
| 40901 | 重复提交 (已有进行中的任务) |
| 50301 | 服务繁忙 (熔断中) |

**性能指标**: P95 < 500ms (任务提交)

---

### 8.2 查询任务状态

**接口**: `GET /video/jobs/{job_id}`

**路径参数**:

| 参数 | 类型 | 说明 |
|-----|------|------|
| job_id | string | 任务 ID |

**响应示例 (进行中)**:

```json
{
  "code": 0,
  "data": {
    "job_id": "abc-123-def",
    "status": "RUNNING",
    "progress": 45,
    "estimated_remaining_time": 60,
    "message": "正在生成中..."
  }
}
```

**响应示例 (已完成)**:

```json
{
  "code": 0,
  "data": {
    "job_id": "abc-123-def",
    "status": "SUCCESS",
    "video_url": "https://cdn.mishi.app/videos/abc-123-def.mp4",
    "duration": 15,
    "file_size": 2048000,
    "thumbnail_url": "https://cdn.mishi.app/videos/abc-123-def_thumb.jpg",
    "finished_at": "2026-03-14T18:02:30+08:00"
  }
}
```

**任务状态枚举**:

| 状态 | 说明 |
|-----|------|
| PENDING | 排队中 |
| RUNNING | 执行中 |
| SUCCESS | 成功 |
| FAILED | 失败 |
| TIMEOUT | 超时 |
| CANCELLED | 已取消 |

**错误码**:

| Code | 说明 |
|------|------|
| 40401 | 任务不存在 |

---

## 9. Route Service - 路线服务 (P1)

### 9.1 获取城市旅行路线

**接口**: `GET /routes/{city_code}`

**用途**: 获取指定城市的诗词旅行路线推荐

**路径参数**:

| 参数 | 类型 | 说明 |
|-----|------|------|
| city_code | string | 城市编码 (如 110000=北京) |

**请求参数**:

| 参数 | 类型 | 必填 | 说明 | 示例 |
|-----|------|-----|------|------|
| route_type | string | 否 | 路线类型: half_day/full_day | half_day |

**响应示例**:

```json
{
  "code": 0,
  "data": {
    "routes": [
      {
        "route_id": 1,
        "name": "北京故宫-天坛半日游",
        "type": "half_day",
        "estimated_duration": 180,
        "distance": 5000,
        "pois": [
          {
            "poi_id": 123,
            "name": "故宫",
            "poems_count": 10,
            "order": 1
          },
          {
            "poi_id": 456,
            "name": "天坛",
            "poems_count": 5,
            "order": 2
          }
        ],
        "user_progress": {
          "completed_pois": 1,
          "total_pois": 2,
          "progress_percent": 50
        }
      }
    ]
  }
}
```

---

## 10. 接口依赖关系图

```
用户打开 App
  ↓
GET /geo/nearby  →  附近 POI 列表
  ↓
GET /poems/recommend  →  推荐诗词列表
  ↓
GET /poems/{id}  →  诗词详情
  ↓
GET /audio/{poem_id}  →  音频播放
  ↓
POST /checkins  →  打卡记录
  ↓
POST /video/jobs  →  生成 AI 动画 (可选)
  ↓
GET /video/jobs/{id}  →  轮询任务状态
```

---

## 11. 性能指标汇总

| 接口 | P95 延迟目标 | QPS 目标 |
|-----|------------|---------|
| GET /geo/nearby | < 100ms | 1000 |
| GET /poems/recommend | < 300ms | 1000 |
| GET /poems/{id} | < 200ms | 2000 |
| GET /audio/{poem_id} | < 100ms | 1000 |
| POST /checkins | < 200ms | 500 |
| POST /video/jobs | < 500ms | 100 |
| GET /video/jobs/{id} | < 100ms | 200 |

---

## 12. 变更日志

### v1.1 (2026-03-16)

**新增**:
- `GET /poems/recommend` 增加 `score_breakdown` 字段 (季节因子)
- `POST /checkins` 增加 `device_info` 字段 (防作弊)
- `POST /video/jobs` 支持缓存命中快速返回
- 新增错误码 40302-40305 (打卡风控)

**修改**:
- `GET /poems/{id}` 增加 `interpretations` 多版本解读
- `GET /geo/nearby` 增加 `poems_count` 字段

### v1.0 (2026-03-10)

- 初版发布

---

**文档状态**: 🔒 **已冻结**  
**输出时间**: 2026-03-14 18:47  
**责任人**: Arch Agent  
**审核状态**: 待 Coordinator 评审