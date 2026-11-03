# Flutter API 契约对接修复检查清单

**生成时间**: 2026-03-17 10:15  
**负责人**: 架构指导Agent D017  
**目标**: 确保 Flutter 项目与 API 契约 v1.1 完全一致

## 1. 当前状态检查

### ✅ 已完成
- [x] Base URL 已修正为 `https://api.mishi.app/v1`
- [x] 基础项目结构已建立
- [x] 部分模型类已创建
- [x] GeoService 和 PoemService 骨架已创建

### ❌ 待修复问题

## 2. 模型层修复清单

### 2.1 Poem 模型修复
**当前问题**: 字段不匹配 API 契约

**API 契约要求** (GET /poems/{poem_id}):
```json
{
  "poem_id": 456,
  "title": "黄鹤楼送孟浩然之广陵",
  "author": "李白",
  "dynasty": "唐",
  "content": ["故人西辞黄鹤楼", "烟花三月下扬州", ...],
  "tags": ["送别", "友情", "春"],
  "best_seasons": ["春"],
  "solar_terms": ["清明", "谷雨"],
  "interpretations": {
    "textbook": { "source": "...", "content": "..." },
    "academic": { "source": "...", "content": "..." },
    "basic": { "source": "...", "content": "..." }
  },
  "related_pois": [...],
  "media": { "has_audio": true, ... },
  "stats": { "view_count": 12543, ... }
}
```

**修复要求**:
1. `id` 字段应改为 `poem_id` 且类型为 `int`
2. 添加 `tags`, `solar_terms` 字段 (`List<String>?`)
3. `interpretations` 应为 `Map<String, Interpretation>` 而非 `List<String>?`
4. 添加 `related_pois` (`List<RelatedPoi>?`)
5. 添加 `media` (`MediaInfo?`)
6. 添加 `stats` (`PoemStats?`)

**修正后的 Poem 模型**:
```dart
@freezed
class Poem with _$Poem {
  const factory Poem({
    @JsonKey(name: 'poem_id') required int poemId,
    required String title,
    required String author,
    required String dynasty,
    required List<String> content,
    List<String>? tags,
    @JsonKey(name: 'best_seasons') List<String>? bestSeasons,
    @JsonKey(name: 'solar_terms') List<String>? solarTerms,
    Map<String, Interpretation>? interpretations,
    @JsonKey(name: 'related_pois') List<RelatedPoi>? relatedPois,
    MediaInfo? media,
    PoemStats? stats,
  }) = _Poem;

  factory Poem.fromJson(Map<String, dynamic> json) => _$PoemFromJson(json);
}

// 需要补充的子模型
@freezed
class Interpretation with _$Interpretation {
  const factory Interpretation({
    required String source,
    required String content,
  }) = _Interpretation;
  
  factory Interpretation.fromJson(Map<String, dynamic> json) => _$InterpretationFromJson(json);
}

@freezed
class RelatedPoi with _$RelatedPoi {
  const factory RelatedPoi({
    @JsonKey(name: 'poi_id') required int poiId,
    required String name,
    @JsonKey(name: 'relevance_score') double relevanceScore,
  }) = _RelatedPoi;
  
  factory RelatedPoi.fromJson(Map<String, dynamic> json) => _$RelatedPoiFromJson(json);
}

@freezed
class MediaInfo with _$MediaInfo {
  const factory MediaInfo({
    @JsonKey(name: 'has_audio') bool hasAudio,
    @JsonKey(name: 'audio_duration') int? audioDuration,
    @JsonKey(name: 'has_video') bool hasVideo,
  }) = _MediaInfo;
  
  factory MediaInfo.fromJson(Map<String, dynamic> json) => _$MediaInfoFromJson(json);
}

@freezed
class PoemStats with _$PoemStats {
  const factory PoemStats({
    @JsonKey(name: 'view_count') int viewCount,
    @JsonKey(name: 'like_count') int likeCount,
    @JsonKey(name: 'checkin_count') int checkinCount,
  }) = _PoemStats;
  
  factory PoemStats.fromJson(Map<String, dynamic> json) => _$PoemStatsFromJson(json);
}
```

### 2.2 Poi 模型修复
**检查文件**: `lib/models/poi.dart`

**API 契约要求** (GET /geo/nearby):
```json
{
  "poi_id": 123,
  "name": "黄鹤楼",
  "ancient_name": "黄鹤楼",
  "modern_name": "黄鹤楼景区",
  "location": { "lat": 30.5447, "lon": 114.2969 },
  "distance": 50,
  "category": "景点",
  "description": "江南三大名楼之一",
  "poems_count": 15
}
```

**修复要求**:
1. 字段名匹配: `poi_id`, `ancient_name`, `modern_name`, `poems_count`
2. `location` 应为 `{"lat": double, "lon": double}` 对象
3. 所有字段类型与 API 一致

### 2.3 Recommendation 模型修复
**检查文件**: `lib/models/poem_recommendation_response.dart`

**API 契约要求** (GET /poems/recommend):
```json
{
  "poem_id": 456,
  "title": "...",
  "author": "...",
  "dynasty": "...",
  "content": [...],
  "distance": 50,
  "season_tag": "春",
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
```

**修复要求**:
1. 包含 `score_breakdown` 和 `related_poi` 子对象
2. 字段名: `season_tag`, `score_breakdown`

## 3. 服务层修复清单

### 3.1 GeoService 修复
**当前问题**: 参数名不匹配 API 契约

**API 契约**: `GET /geo/nearby` 参数为 `lat`, `lon`, `radius`, `limit`

**修复要求**:
```dart
Future<GeoNearbyResponse> fetchNearbyPOIs({
  required double lat,      // 不是 latitude
  required double lon,      // 不是 longitude
  int radius = 5000,        // 默认值 5000 米 (API 默认)
  int limit = 10,           // 默认值 10 (API 默认)
}) async {
  final response = await _dio.get(
    '/geo/nearby',
    queryParameters: {
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'limit': limit,
    },
  );
  return GeoNearbyResponse.fromJson(response.data['data']); // 注意 data 包装
}
```

### 3.2 PoemService 修复
**检查文件**: `lib/services/api/poem_service.dart`

**需要实现的接口**:
1. `GET /poems/recommend` - 推荐诗词
2. `GET /poems/{poem_id}` - 诗词详情
3. `GET /audio/{poem_id}` - 获取音频 (可选)

**参数要求**:
- `/poems/recommend`: `lat`, `lon`, `limit`, `season` (可选)
- `/poems/{poem_id}`: 路径参数 `poem_id`
- 响应数据在 `data` 字段内

### 3.3 CheckinService 创建
**需要创建的新服务**:
```dart
class CheckinService {
  Future<CheckinResult> submitCheckin(CheckinRequest request) async {
    // POST /checkins
    // 请求体格式需符合 API 契约
  }
  
  Future<PaginatedResponse<CheckinHistory>> getCheckinHistory({
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    // GET /checkins/history
    // 支持分页参数
  }
}
```

### 3.4 MediaService & AIService 创建 (可选)
根据优先级决定是否立即实现。

## 4. 网络层修复清单

### 4.1 认证头实现
**API 契约要求**:
```http
Authorization: Bearer <access_token>
X-Device-Id: <device_id>
X-App-Version: <app_version>
```

**修复要求**:
在 `api_client.dart` 的拦截器中添加:
```dart
onRequest: (options, handler) async {
  // 获取 token
  final token = await storage.read('access_token');
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  
  // 设备ID (使用 uuid 生成并持久化)
  final deviceId = await getDeviceId();
  options.headers['X-Device-Id'] = deviceId;
  
  // 应用版本
  final packageInfo = await PackageInfo.fromPlatform();
  options.headers['X-App-Version'] = packageInfo.version;
  
  handler.next(options);
},
```

### 4.2 错误处理统一
**API 错误响应格式**:
```json
{
  "code": 40001,
  "message": "参数错误: lat 字段缺失",
  "error_detail": { ... },
  "timestamp": 1710394800
}
```

**修复要求**:
创建统一的错误处理类:
```dart
class ApiError implements Exception {
  final int code;
  final String message;
  final Map<String, dynamic>? errorDetail;
  
  ApiError({required this.code, required this.message, this.errorDetail});
  
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'],
      message: json['message'],
      errorDetail: json['error_detail'],
    );
  }
  
  String get userFriendlyMessage {
    switch (code) {
      case 40101: return '登录已过期，请重新登录';
      case 40303: return '冷却期内无法重复打卡';
      case 42901: return '操作过于频繁，请稍后再试';
      default: return message;
    }
  }
}
```

## 5. 分页处理清单

### 5.1 分页参数标准化
所有列表接口使用统一分页参数:
- `limit`: 每页数量 (默认 20，最大 100)
- `offset`: 偏移量 (默认 0)

### 5.2 分页响应包装
**API 响应格式**:
```json
{
  "data": {
    "items": [...],
    "total": 150,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

**创建分页模型**:
```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
  
  PaginatedResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });
  
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List).map((item) => fromJson(item)).toList(),
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['has_more'],
    );
  }
}
```

## 6. 实施优先级

### P0 (今日必须完成)
1. [ ] Poem 模型修正 (字段匹配 API 契约)
2. [ ] GeoService 参数名修正 (lat/lon)
3. [ ] 认证头实现 (Authorization, X-Device-Id, X-App-Version)
4. [ ] 错误处理统一 (ApiError 类)

### P1 (明日完成)
5. [ ] 创建 CheckinService
6. [ ] 实现分页处理模型
7. [ ] 完善 PoemService (推荐和详情接口)
8. [ ] 创建缺失的子模型 (Interpretation, RelatedPoi, MediaInfo, PoemStats)

### P2 (本周完成)
9. [ ] 状态管理 Provider 实现
10. [ ] 页面层集成 API 调用
11. [ ] 测试验证

## 7. 验证方法

### 7.1 模型验证
```bash
# 生成 freezed 代码
flutter pub run build_runner build --delete-conflicting-outputs

# 分析代码
flutter analyze
```

### 7.2 接口验证
1. 使用 Mock 数据测试模型解析
2. 使用实际 API 测试 (如果后端可用)
3. 验证错误处理场景

### 7.3 集成验证
1. 首页能加载推荐诗词
2. 详情页能展示完整诗词信息
3. 打卡功能可正常提交

## 8. 相关文档

1. [API 契约 v1.1](../70_api_contracts/2026-03-16-api-contract-v1.1.md)
2. [技术实施指导文档](../20_architecture/2026-03-17-implementation-guidance.md)
3. [Flutter 验收报告](2026-03-17-flutter-acceptance-report.md)

---

**负责人**: App Agent D019  
**截止时间**: 今日完成 P0 项，明日完成 P1 项  
**状态**: 🔄 进行中  
**最后检查**: 2026-03-17 10:15