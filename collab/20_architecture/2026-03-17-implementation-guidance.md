# 觅诗项目技术实施指导文档

**文档版本**: v1.0  
**生成时间**: 2026-03-17 09:30  
**负责人**: 架构指导Agent D017  
**目标读者**: Backend Agent D012, App Agent D019, Frontend Agent D011  
**状态**: ✅ **生效中**

---

## 1. 数据库修复实施指南 (Backend Agent D012)

### 1.1 高优先级问题修复脚本

**前提**: 已安装 PostgreSQL 15 + PostGIS 3.3 + pg_cron 扩展

#### 1.1.1 外键约束一致性修复
```sql
-- 检查当前外键约束
SELECT conname, confdeltype 
FROM pg_constraint 
WHERE conrelid = 'checkins'::regclass 
  AND contype = 'f';

-- 修复 checkins 表外键约束
ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poi_id_fkey,
  ADD CONSTRAINT checkins_poi_id_fkey 
    FOREIGN KEY (poi_id) REFERENCES pois(id) ON DELETE CASCADE;

ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_poem_id_fkey,
  ADD CONSTRAINT checkins_poem_id_fkey 
    FOREIGN KEY (poem_id) REFERENCES poems(id) ON DELETE CASCADE;

-- 验证所有外键已统一为 CASCADE
SELECT 
  conname AS constraint_name,
  confrelid::regclass AS referenced_table,
  confdeltype AS delete_action
FROM pg_constraint 
WHERE conrelid = 'checkins'::regclass 
  AND contype = 'f';
```

#### 1.1.2 唯一约束合理性调整
```sql
-- 移除精确到秒的唯一约束
ALTER TABLE checkins 
  DROP CONSTRAINT IF EXISTS checkins_user_poi_time;

-- 添加按小时去重的唯一约束（与业务冷却期 3600 秒对齐）
ALTER TABLE checkins 
  ADD CONSTRAINT checkins_user_poi_hour_unique 
    UNIQUE (user_id, poi_id, date_trunc('hour', checkin_time));

-- 添加冷却期检查的触发器（可选，增强业务逻辑）
CREATE OR REPLACE FUNCTION check_checkin_cooldown()
RETURNS TRIGGER AS $$
DECLARE
  last_checkin TIMESTAMP;
  cooldown_seconds INT;
BEGIN
  -- 获取冷却期配置（默认 3600 秒）
  SELECT config_value::INT INTO cooldown_seconds
  FROM system_config 
  WHERE config_key = 'checkin.cooldown_seconds';
  
  IF cooldown_seconds IS NULL THEN
    cooldown_seconds := 3600;
  END IF;
  
  -- 检查最近一次打卡
  SELECT MAX(checkin_time) INTO last_checkin
  FROM checkins
  WHERE user_id = NEW.user_id 
    AND poi_id = NEW.poi_id
    AND checkin_time > NOW() - INTERVAL '1 day';
    
  IF last_checkin IS NOT NULL AND 
     (EXTRACT(EPOCH FROM (NEW.checkin_time - last_checkin)) < cooldown_seconds) THEN
    RAISE EXCEPTION '冷却期内禁止重复打卡 (距离上次打卡 % 秒)', 
      EXTRACT(EPOCH FROM (NEW.checkin_time - last_checkin));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_checkin_cooldown
  BEFORE INSERT ON checkins
  FOR EACH ROW EXECUTE FUNCTION check_checkin_cooldown();
```

#### 1.1.3 空间索引优化
```sql
-- 为 checkins 表添加空间索引
CREATE INDEX IF NOT EXISTS idx_checkins_location ON checkins USING GIST(location);

-- 验证索引创建成功
SELECT 
  indexname, 
  indexdef 
FROM pg_indexes 
WHERE tablename = 'checkins' 
  AND indexdef LIKE '%GIST%';

-- 性能测试查询示例
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM checkins 
WHERE ST_DWithin(
  location,
  ST_SetSRID(ST_MakePoint(116.4074, 39.9186), 4326),
  1000  -- 1公里范围内
);
```

#### 1.1.4 分区策略统一实施

**步骤1: 确认扩展可用性**
```sql
-- 检查 postgis 和 pg_cron 扩展
SELECT name, installed_version 
FROM pg_available_extensions 
WHERE name IN ('postgis', 'pg_cron');

-- 如果未安装则安装
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

**步骤2: 统一分区方案**
```sql
-- 创建 checkins 表的分区表结构
CREATE TABLE checkins_partitioned (
    LIKE checkins INCLUDING ALL
) PARTITION BY RANGE (checkin_time);

-- 创建当前月份分区
CREATE TABLE checkins_202603 PARTITION OF checkins_partitioned
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

-- 创建未来月份分区函数
CREATE OR REPLACE FUNCTION create_checkins_partitions()
RETURNS VOID AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..2 LOOP
        start_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month' * i);
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'checkins_' || TO_CHAR(start_date, 'YYYYMM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF checkins_partitioned FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 每月1号凌晨2点执行分区创建
SELECT cron.schedule(
    'create-checkins-partitions',
    '0 2 1 * *', 
    'SELECT create_checkins_partitions()'
);

-- 数据迁移（需在维护窗口执行）
BEGIN;
-- 1. 暂停应用写入
-- 2. 重命名原表
ALTER TABLE checkins RENAME TO checkins_old;
-- 3. 创建分区表
SELECT create_checkins_partitions();
-- 4. 迁移数据
INSERT INTO checkins_partitioned SELECT * FROM checkins_old;
-- 5. 重命名分区表
ALTER TABLE checkins_partitioned RENAME TO checkins;
-- 6. 重建外键和索引（自动继承）
COMMIT;
```

**步骤3: 统一 user_events 分区策略**
```sql
-- 确保 user_events 表已分区
CREATE TABLE user_events_partitioned (
    LIKE user_events INCLUDING ALL
) PARTITION BY RANGE (event_time);

-- 同步分区维护任务
SELECT cron.schedule(
    'create-all-partitions',
    '0 2 1 * *',
    $$
    BEGIN
        PERFORM create_checkins_partitions();
        PERFORM create_monthly_partitions(); -- 原 user_events 分区函数
    END;
    $$
);
```

#### 1.1.5 自动更新机制统一实现
```sql
-- 创建通用的 updated_at 触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有包含 updated_at 字段的表创建触发器
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'public'
          AND table_name NOT LIKE '%partition%'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%s_updated_at ON %I;
            CREATE TRIGGER update_%s_updated_at
                BEFORE UPDATE ON %I
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column();
        ', tbl.table_name, tbl.table_name, tbl.table_name, tbl.table_name);
    END LOOP;
END;
$$;

-- 验证触发器创建
SELECT 
    event_object_table AS table_name,
    trigger_name,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_name LIKE '%updated_at%'
ORDER BY table_name;
```

### 1.2 性能优化指导

#### 1.2.1 关键复合索引设计
```sql
-- 1. 诗词推荐查询复合索引
CREATE INDEX idx_poems_poi_status_view ON poems(poi_id, status, view_count DESC) 
WHERE poi_id IS NOT NULL;

-- 2. POI-诗词关联查询优化
CREATE INDEX idx_poi_poems_poem_relevance ON poi_poems(poem_id, relevance_score DESC);

-- 3. 推荐算法分析索引
CREATE INDEX idx_recommendations_user_trigger_time ON recommendations(user_id, trigger_type, shown_at DESC);

-- 4. 打卡历史查询优化
CREATE INDEX idx_checkins_user_time_include ON checkins(user_id, checkin_time DESC)
    INCLUDE (poi_id, poem_id, location);

-- 5. 视频任务状态查询
CREATE INDEX idx_video_jobs_user_status_time ON video_jobs(user_id, status, created_at DESC);

-- 6. 风控审核队列优先级索引
CREATE INDEX idx_risk_review_priority_time ON risk_review_queue(priority, created_at)
    WHERE status = 'PENDING';
```

#### 1.2.2 JSONB 字段优化建议
```sql
-- 1. 对于固定结构的数组，考虑使用原生数组类型
-- 当前: tags JSONB -> 建议: tags TEXT[]
-- 迁移示例:
ALTER TABLE poems ADD COLUMN tags_array TEXT[];
UPDATE poems SET tags_array = ARRAY(SELECT jsonb_array_elements_text(tags));
CREATE INDEX idx_poems_tags_array ON poems USING GIN(tags_array);

-- 2. 添加 JSONB 验证约束
ALTER TABLE poems 
  ADD CONSTRAINT check_tags_format 
  CHECK (jsonb_typeof(tags) = 'array' OR tags IS NULL);

-- 3. 为 JSONB 字段添加 GIN 索引（如已使用 JSONB）
CREATE INDEX IF NOT EXISTS idx_poems_tags_gin ON poems USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_poems_seasons_gin ON poems USING GIN(best_seasons);
```

#### 1.2.3 查询性能基准与优化建议

**场景1: 附近 POI 查询 (GET /geo/nearby)**
```sql
-- 预期 P95 < 100ms
EXPLAIN ANALYZE
SELECT 
    p.id AS poi_id,
    p.name,
    p.ancient_name,
    p.modern_name,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(116.4074, 39.9186), 4326)) AS distance,
    p.category,
    p.description,
    COUNT(DISTINCT pp.poem_id) AS poems_count
FROM pois p
LEFT JOIN poi_poems pp ON p.id = pp.poi_id
WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(116.4074, 39.9186), 4326), 5000)
  AND p.status = 1
GROUP BY p.id
ORDER BY distance
LIMIT 10;

-- 优化建议:
-- 1. 确保 idx_pois_location GIST 索引存在
-- 2. 考虑添加复合索引: CREATE INDEX idx_pois_location_status ON pois USING GIST(location) WHERE status = 1;
-- 3. 预计算 poems_count 并定期更新
```

**场景2: 诗词推荐查询 (GET /poems/recommend)**
```sql
-- 预期 P95 < 300ms
EXPLAIN ANALYZE
WITH nearby_pois AS (
    SELECT id, distance
    FROM pois
    WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(116.4074, 39.9186), 4326), 5000)
      AND status = 1
)
SELECT 
    p.id AS poem_id,
    p.title,
    p.author,
    p.dynasty,
    p.content,
    np.distance,
    -- 季节因子计算（简化示例）
    CASE 
        WHEN '春' = ANY(SELECT jsonb_array_elements_text(p.best_seasons)) THEN 0.2
        ELSE 0.0
    END AS season_score,
    pp.relevance_score
FROM poems p
JOIN poi_poems pp ON p.id = pp.poem_id
JOIN nearby_pois np ON pp.poi_id = np.id
WHERE p.status = 'published'
ORDER BY (0.4 * (1 - np.distance / 5000.0) + 0.3 * pp.relevance_score + 0.2 * season_score + 0.1 * (p.view_count / 10000.0)) DESC
LIMIT 10;

-- 优化建议:
-- 1. 创建 idx_poems_status 索引
-- 2. 考虑物化视图缓存热门推荐结果
-- 3. 使用 Redis 缓存推荐结果，有效期 5 分钟
```

**场景3: 打卡历史查询 (GET /checkins/history)**
```sql
-- 预期 P95 < 200ms
EXPLAIN ANALYZE
SELECT 
    c.id AS checkin_id,
    p.name AS poi_name,
    pm.title AS poem_title,
    c.checkin_time,
    ST_X(c.location) AS lat,
    ST_Y(c.location) AS lon,
    c.card_url
FROM checkins c
JOIN pois p ON c.poi_id = p.id
JOIN poems pm ON c.poem_id = pm.id
WHERE c.user_id = 12345
ORDER BY c.checkin_time DESC
LIMIT 20 OFFSET 0;

-- 优化建议:
-- 1. 确保 idx_checkins_user_time_include 索引存在
-- 2. 分区表能显著提升历史查询性能
-- 3. 考虑添加覆盖索引: (user_id, checkin_time DESC) INCLUDE (poi_id, poem_id, card_url)
```

### 1.3 数据库运维监控指标

| 指标 | 预警阈值 | 监控频率 | 负责人 |
|------|----------|----------|--------|
| 连接数使用率 | > 80% | 5分钟 | DBA |
| 查询响应时间 P95 | > 300ms | 1分钟 | Backend |
| 索引命中率 | < 95% | 15分钟 | DBA |
| 表膨胀率 | > 20% | 每日 | DBA |
| 分区表数量 | 与实际月份不符 | 每日 | DBA |
| 长事务数量 | > 10 | 5分钟 | Backend |

---

## 2. API 契约对接规范 (App Agent D019)

### 2.1 基础配置规范

#### 2.1.1 Base URL 配置
```dart
// lib/shared/constants/app_constants.dart
abstract class AppConstants {
  static const String apiBaseUrl = 'https://api.mishi.app/v1';
  static const String cdnBaseUrl = 'https://cdn.mishi.app';
  
  // 环境区分（可选）
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: true);
  static String get effectiveBaseUrl => isProduction ? apiBaseUrl : 'https://staging-api.mishi.app/v1';
}
```

#### 2.1.2 认证头实现
```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;
  final SharedPreferences _prefs;
  
  ApiClient(this._dio, this._prefs) {
    _dio.options.baseUrl = AppConstants.effectiveBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // 添加认证拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 获取 token
        final token = _prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // 设备ID
        final deviceId = await _getDeviceId();
        options.headers['X-Device-Id'] = deviceId;
        
        // 应用版本
        final packageInfo = await PackageInfo.fromPlatform();
        options.headers['X-App-Version'] = packageInfo.version;
        
        handler.next(options);
      },
      onError: (error, handler) {
        // 统一错误处理
        if (error.response?.statusCode == 401) {
          // Token 过期，尝试刷新
          _refreshTokenAndRetry(error, handler);
        } else {
          handler.next(error);
        }
      },
    ));
  }
  
  Future<String> _getDeviceId() async {
    // 实现设备ID获取逻辑
  }
  
  Future<void> _refreshTokenAndRetry(DioException error, ErrorInterceptorHandler handler) async {
    // 实现token刷新逻辑
  }
}
```

#### 2.1.3 分页参数标准化
```dart
// lib/shared/models/pagination.dart
class PaginationParams {
  final int limit;
  final int offset;
  
  const PaginationParams({
    this.limit = 20,
    this.offset = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'limit': limit,
    'offset': offset,
  };
  
  PaginationParams nextPage() => PaginationParams(
    limit: limit,
    offset: offset + limit,
  );
}

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
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
}
```

### 2.2 核心服务层架构

#### 2.2.1 GeoService 实现模板
```dart
// lib/services/api/geo_service.dart
import 'package:dio/dio.dart';
import '../models/poi.dart';
import '../models/pagination.dart';

class GeoService {
  final Dio _dio;
  
  GeoService(this._dio);
  
  Future<List<Poi>> getNearbyPois({
    required double lat,
    required double lon,
    int? radius,
    int? limit,
  }) async {
    final response = await _dio.get('/geo/nearby', queryParameters: {
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'limit': limit,
    });
    
    final data = response.data['data'];
    return (data['pois'] as List).map((json) => Poi.fromJson(json)).toList();
  }
  
  Future<bool> checkGeofence({
    required double userLat,
    required double userLon,
    required int poiId,
  }) async {
    final response = await _dio.post('/geo/geofence/check', data: {
      'user_lat': userLat,
      'user_lon': userLon,
      'poi_id': poiId,
    });
    
    final data = response.data['data'];
    return data['in_geofence'] as bool;
  }
}
```

#### 2.2.2 PoemService 实现模板
```dart
// lib/services/api/poem_service.dart
import 'package:dio/dio.dart';
import '../models/poem.dart';
import '../models/pagination.dart';
import '../models/recommendation.dart';

class PoemService {
  final Dio _dio;
  
  PoemService(this._dio);
  
  Future<List<Recommendation>> recommendPoems({
    required double lat,
    required double lon,
    int? limit,
    String? season,
  }) async {
    final response = await _dio.get('/poems/recommend', queryParameters: {
      'lat': lat,
      'lon': lon,
      'limit': limit,
      'season': season,
    });
    
    final data = response.data['data'];
    return (data['poems'] as List).map((json) => Recommendation.fromJson(json)).toList();
  }
  
  Future<PoemDetail> getPoemDetail(int poemId) async {
    final response = await _dio.get('/poems/$poemId');
    return PoemDetail.fromJson(response.data['data']);
  }
}
```

#### 2.2.3 CheckinService 实现模板
```dart
// lib/services/api/checkin_service.dart
import 'package:dio/dio.dart';
import '../models/checkin.dart';
import '../models/pagination.dart';

class CheckinService {
  final Dio _dio;
  
  CheckinService(this._dio);
  
  Future<CheckinResult> submitCheckin(CheckinRequest request) async {
    final response = await _dio.post('/checkins', data: request.toJson());
    return CheckinResult.fromJson(response.data['data']);
  }
  
  Future<PaginatedResponse<CheckinHistory>> getCheckinHistory({
    int? userId,
    PaginationParams? pagination,
  }) async {
    final params = {...?pagination?.toJson()};
    if (userId != null) params['user_id'] = userId;
    
    final response = await _dio.get('/checkins/history', queryParameters: params);
    return PaginatedResponse.fromJson(
      response.data['data'],
      (json) => CheckinHistory.fromJson(json),
    );
  }
}
```

#### 2.2.4 MediaService & AIService 模板
```dart
// lib/services/api/media_service.dart
class MediaService {
  Future<AudioInfo> getAudioInfo(int poemId) { ... }
}

// lib/services/api/ai_service.dart
class AIService {
  Future<VideoJob> submitVideoJob(VideoJobRequest request) { ... }
  Future<VideoJobStatus> getVideoJobStatus(String jobId) { ... }
}
```

### 2.3 数据模型映射规范

#### 2.3.1 模型类定义（使用 freezed）
```dart
// lib/models/poem.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'poem.freezed.dart';
part 'poem.g.dart';

@freezed
class Poem with _$Poem {
  const factory Poem({
    required int poemId,
    required String title,
    required String author,
    required String dynasty,
    required List<String> content,
    List<String>? tags,
    List<String>? bestSeasons,
    List<String>? solarTerms,
    // ... 其他字段
  }) = _Poem;
  
  factory Poem.fromJson(Map<String, dynamic> json) => _$PoemFromJson(json);
}

// 生成命令: flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2.3.2 字段映射表（数据库 ↔ API ↔ Flutter）

| 数据库字段 | API 字段 | Flutter 模型字段 | 类型转换 |
|-----------|----------|------------------|----------|
| poems.id | poem_id | poemId | int |
| poems.content | content | content | JSONB → List<String> |
| poems.best_seasons | season_tag (推荐接口) | bestSeasons | JSONB → List<String> |
| pois.location | location.lat/lon | location.lat/lon | GEOMETRY → double |
| checkins.checkin_time | checkin_time | checkinTime | TIMESTAMP → DateTime |

**转换函数示例**:
```dart
extension PoemModelExtension on Poem {
  static Poem fromDatabaseJson(Map<String, dynamic> dbJson) {
    // 处理 JSONB 到 List 的转换
    final contentJson = dbJson['content'] as List<dynamic>;
    final content = contentJson.map((line) => line['text'] as String).toList();
    
    return Poem(
      poemId: dbJson['id'] as int,
      title: dbJson['title'] as String,
      author: dbJson['author'] as String,
      dynasty: dbJson['dynasty'] as String,
      content: content,
      bestSeasons: _parseJsonbArray(dbJson['best_seasons']),
    );
  }
  
  static List<String>? _parseJsonbArray(dynamic jsonb) {
    if (jsonb == null) return null;
    if (jsonb is List) return jsonb.cast<String>();
    // JSONB 字符串解析
    return List<String>.from(json.decode(jsonb as String));
  }
}
```

### 2.4 状态管理最佳实践

#### 2.4.1 Riverpod Provider 架构模式
```dart
// lib/providers/auth_provider.dart
import 'package:riverpod/riverpod.dart';
import '../services/api/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(AuthState.initial());
  
  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _authService.login(phone, password);
      state = AuthState.authenticated(token);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(String token) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
  
  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}
```

#### 2.4.2 业务 Provider 分类
```dart
// 1. 认证状态
final authProvider = StateProvider<AuthState>((ref) => AuthState.initial());

// 2. 地理位置
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

// 3. 诗词数据（使用 FutureProvider 缓存）
final recommendedPoemsProvider = FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  final location = ref.watch(locationProvider);
  final poemService = ref.watch(poemServiceProvider);
  
  if (location is LocationLoaded) {
    return poemService.recommendPoems(
      lat: location.lat,
      lon: location.lon,
    );
  }
  return [];
});

// 4. 打卡状态（使用 StateNotifierProvider）
final checkinProvider = StateNotifierProvider<CheckinNotifier, CheckinState>((ref) {
  return CheckinNotifier(ref.watch(checkinServiceProvider));
});
```

### 2.5 错误处理策略

#### 2.5.1 统一错误处理拦截器
```dart
// lib/core/network/error_handler.dart
class ApiError {
  final int code;
  final String message;
  final Map<String, dynamic>? errorDetail;
  
  ApiError({
    required this.code,
    required this.message,
    this.errorDetail,
  });
  
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as int,
      message: json['message'] as String,
      errorDetail: json['error_detail'] as Map<String, dynamic>?,
    );
  }
  
  // 业务错误判断
  bool get isNetworkError => code >= 50000;
  bool get isAuthError => code >= 40100 && code < 40200;
  bool get isRateLimit => code == 42901;
  
  String get userFriendlyMessage {
    switch (code) {
      case 40101:
        return '登录已过期，请重新登录';
      case 40303:
        return '冷却期内无法重复打卡';
      case 42901:
        return '操作过于频繁，请稍后再试';
      default:
        return message;
    }
  }
}

// 错误拦截器
_dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    if (error.response != null) {
      final apiError = ApiError.fromJson(error.response!.data);
      // 转换为统一的业务异常
      handler.reject(DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: DioExceptionType.badResponse,
        error: apiError.userFriendlyMessage,
      ));
    } else {
      handler.next(error);
    }
  },
));
```

#### 2.5.2 UI 层错误展示
```dart
// lib/shared/widgets/error_view.dart
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  
  const ErrorView({super.key, required this.error, this.onRetry});
  
  @override
  Widget build(BuildContext context) {
    String message = '发生未知错误';
    
    if (error is DioException) {
      message = error.error?.toString() ?? '网络请求失败';
    } else if (error is ApiError) {
      message = error.userFriendlyMessage;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          if (onRetry != null) 
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

// 使用示例
Consumer(builder: (context, ref, child) {
  final poemsAsync = ref.watch(recommendedPoemsProvider);
  
  return poemsAsync.when(
    data: (poems) => PoemListView(poems: poems),
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => ErrorView(
      error: error,
      onRetry: () => ref.invalidate(recommendedPoemsProvider),
    ),
  );
});
```

---

## 3. 前端项目技术指导 (Frontend Agent D011)

### 3.1 技术选型验证

**当前选型**: React + TypeScript + Vite + Tailwind CSS ✅

**合理性评估**:
- ✅ React: 生态成熟，团队熟悉度高
- ✅ TypeScript: 类型安全，与 API 契约匹配度高
- ✅ Vite: 开发体验优秀，构建速度快
- ✅ Tailwind CSS: 样式开发效率高，设计系统统一

**建议补充**:
- ✅ TanStack Query (React Query): 数据获取、缓存、同步
- ✅ Zustand: 轻量级状态管理，替代 Redux Toolkit
- ✅ React Hook Form: 表单处理
- ✅ Axios: HTTP 客户端

### 3.2 项目结构设计

```
src/
├── api/                    # API 客户端
│   ├── client.ts          # Axios 实例配置
│   ├── services/          # 业务服务
│   │   ├── geoService.ts
│   │   ├── poemService.ts
│   │   └── checkinService.ts
│   └── models/            # TypeScript 类型定义
│       ├── poem.ts
│       ├── poi.ts
│       └── checkin.ts
├── components/            # 通用组件
│   ├── ui/               # 基础 UI 组件
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Input.tsx
│   └── shared/           # 业务共享组件
│       ├── PoemCard.tsx
│       └── LocationPicker.tsx
├── features/              # 功能模块
│   ├── auth/             # 认证模块
│   │   ├── components/
│   │   ├── hooks/
│   │   └── pages/
│   ├── home/             # 首页模块
│   └── poem/             # 诗词模块
├── hooks/                 # 自定义 Hook
│   ├── useAuth.ts
│   ├── useLocation.ts
│   └── useCheckin.ts
├── stores/                # 状态管理
│   ├── authStore.ts
│   ├── poemStore.ts
│   └── checkinStore.ts
├── utils/                 # 工具函数
│   ├── format.ts
│   ├── validation.ts
│   └── constants.ts
└── App.tsx
```

### 3.3 状态管理方案

#### 3.3.1 Zustand + TanStack Query 集成
```typescript
// src/stores/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  login: (token: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      login: (token, user) => set({ token, user, isAuthenticated: true }),
      logout: () => set({ token: null, user: null, isAuthenticated: false }),
    }),
    { name: 'auth-storage' }
  )
);

// src/api/client.ts
import axios from 'axios';
import { useAuthStore } from '../stores/authStore';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
});

// 请求拦截器
apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  config.headers['X-Device-Id'] = localStorage.getItem('deviceId') || '';
  config.headers['X-App-Version'] = import.meta.env.VITE_APP_VERSION;
  return config;
});

// 响应拦截器
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

#### 3.3.2 TanStack Query 配置
```typescript
// src/providers/QueryProvider.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5分钟
      gcTime: 10 * 60 * 1000,   // 10分钟
      retry: 1,
    },
  },
});

export function QueryProvider({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}

// src/features/poem/hooks/usePoems.ts
import { useQuery } from '@tanstack/react-query';
import { poemService } from '../../../api/services/poemService';

export const useRecommendedPoems = (lat: number, lon: number) => {
  return useQuery({
    queryKey: ['poems', 'recommended', lat, lon],
    queryFn: () => poemService.recommend({ lat, lon }),
    enabled: !!lat && !!lon,
  });
};
```

### 3.4 API 客户端设计

#### 3.4.1 服务层架构
```typescript
// src/api/services/geoService.ts
import { apiClient } from '../client';
import type { Poi, GeofenceCheck } from '../models';

export const geoService = {
  getNearby: async (params: { lat: number; lon: number; radius?: number }) => {
    const response = await apiClient.get('/geo/nearby', { params });
    return response.data.data as { pois: Poi[] };
  },
  
  checkGeofence: async (data: { userLat: number; userLon: number; poiId: number }) => {
    const response = await apiClient.post('/geo/geofence/check', data);
    return response.data.data as GeofenceCheck;
  },
};

// src/api/services/poemService.ts
export const poemService = {
  recommend: async (params: { lat: number; lon: number; limit?: number }) => {
    const response = await apiClient.get('/poems/recommend', { params });
    return response.data.data as { poems: Recommendation[] };
  },
  
  getDetail: async (poemId: number) => {
    const response = await apiClient.get(`/poems/${poemId}`);
    return response.data.data as PoemDetail;
  },
};
```

#### 3.4.2 TypeScript 类型定义
```typescript
// src/api/models/poem.ts
export interface Poem {
  poem_id: number;
  title: string;
  author: string;
  dynasty: string;
  content: string[];
  tags?: string[];
  best_seasons?: string[];
  solar_terms?: string[];
}

export interface Recommendation extends Poem {
  distance: number;
  season_tag: string;
  score: number;
  score_breakdown: {
    distance: number;
    popularity: number;
    season: number;
    time_period: number;
  };
  related_poi: {
    poi_id: number;
    name: string;
    distance: number;
  };
}

// 与数据库模型转换
export function mapPoemFromDb(dbPoem: DbPoem): Poem {
  return {
    poem_id: dbPoem.id,
    title: dbPoem.title,
    author: dbPoem.author,
    dynasty: dbPoem.dynasty,
    content: JSON.parse(dbPoem.content) as string[],
    tags: dbPoem.tags ? JSON.parse(dbPoem.tags) : undefined,
    best_seasons: dbPoem.best_seasons ? JSON.parse(dbPoem.best_seasons) : undefined,
  };
}
```

---

## 4. 跨技术栈一致性指导

### 4.1 数据模型一致性检查清单

#### 检查项1: 诗词模型字段映射
| 字段 | 数据库 | API 契约 | Flutter | 前端 TypeScript | 状态 |
|------|--------|----------|---------|-----------------|------|
| 诗词ID | poems.id | poem_id | poemId | poem_id | ✅ |
| 标题 | title | title | title | title | ✅ |
| 作者 | author | author | author | author | ✅ |
| 朝代 | dynasty | dynasty | dynasty | dynasty | ✅ |
| 内容 | content (JSONB) | content (string[]) | content (List<String>) | content (string[]) | ⚠️ 需转换 |
| 标签 | tags (JSONB) | tags (string[]) | tags (List<String>?) | tags (string[]?) | ⚠️ 需转换 |
| 最佳季节 | best_seasons (JSONB) | season_tag (string) | bestSeasons (List<String>?) | best_seasons (string[]?) | ⚠️ 需转换 |

**转换逻辑统一**:
```typescript
// 通用 JSONB 转换函数
function parseJsonbArray<T>(jsonb: any): T[] | undefined {
  if (!jsonb) return undefined;
  if (Array.isArray(jsonb)) return jsonb as T[];
  try {
    return JSON.parse(jsonb) as T[];
  } catch {
    return undefined;
  }
}
```

#### 检查项2: 地理位置字段
| 字段 | 数据库 | API 契约 | Flutter | 前端 TypeScript |
|------|--------|----------|---------|-----------------|
| 坐标 | GEOMETRY(POINT, 4326) | { lat: number, lon: number } | LatLng | { lat: number; lon: number } |
| 距离 | distance (INT) | distance (number) | distance (double) | distance (number) |

**转换逻辑**:
```sql
-- 数据库查询转换
SELECT 
  id,
  ST_X(location) as lon,
  ST_Y(location) as lat
FROM pois;
```

```dart
// Flutter 转换
class LatLng {
  final double latitude;
  final double longitude;
  
  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      latitude: json['lat'] as double,
      longitude: json['lon'] as double,
    );
  }
}
```

### 4.2 错误处理一致性规范

#### 错误码映射表
| 错误场景 | HTTP 状态码 | 业务错误码 | 客户端处理 |
|----------|------------|-----------|-----------|
| 参数错误 | 400 | 40001 | 展示错误提示，高亮错误字段 |
| 未授权 | 401 | 40101 | 跳转登录页面，清除本地 token |
| 禁止访问 | 403 | 40301-40305 | 展示业务错误提示，提供解决方案 |
| 重复请求 | 409 | 40901 | 提示"操作已提交，请勿重复操作" |
| 限流 | 429 | 42901 | 显示冷却倒计时，禁用按钮 |
| 服务错误 | 500 | 50001 | 展示"服务异常，请稍后重试" |

#### 统一错误响应格式
```typescript
// 前端错误处理
interface ApiError {
  code: number;
  message: string;
  error_detail?: Record<string, any>;
  timestamp: number;
}

function handleApiError(error: ApiError) {
  switch (error.code) {
    case 40101:
      // 清除认证状态，跳转登录
      useAuthStore.getState().logout();
      router.push('/login');
      break;
    case 40303:
      // 打卡冷却期提示
      toast.error(`冷却期内无法重复打卡，请${formatCooldown(error.error_detail?.retry_after)}后再试`);
      break;
    case 42901:
      // 限流提示
      const retryAfter = error.error_detail?.retry_after || 60;
      startCooldownTimer(retryAfter);
      break;
    default:
      toast.error(error.message);
  }
}
```

### 4.3 安全规范一致性

#### 认证头实现规范
| 请求头 | 要求 | 示例值 | 备注 |
|--------|------|--------|------|
| Authorization | Bearer Token | `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Token 有效期 30 天 |
| X-Device-Id | 设备唯一标识 | `abc123-def456-ghi789` | 首次启动生成，本地持久化 |
| X-App-Version | 应用版本号 | `1.0.0` | 从应用元数据获取 |

**Flutter 实现**:
```dart
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }
  return deviceId;
}
```

**前端实现**:
```typescript
function getDeviceId(): string {
  let deviceId = localStorage.getItem('device_id');
  if (!deviceId) {
    deviceId = crypto.randomUUID();
    localStorage.setItem('device_id', deviceId);
  }
  return deviceId;
}
```

#### 敏感数据处理
1. **定位数据**: 仅在前端计算距离，不存储原始坐标
2. **设备信息**: 脱敏后上报，去除可识别个人信息
3. **网络传输**: 全程 HTTPS，关键接口添加请求签名
4. **本地存储**: Token 加密存储，敏感数据内存缓存

---

## 5. 技术债务评估与规划

### 5.1 短期技术债务 (V1.0 发布前必须解决)

| 债务项 | 影响度 | 解决成本 | 负责方 | 解决时限 |
|--------|--------|----------|--------|----------|
| 数据库外键约束不一致 | 高 | 低 (2小时) | Backend | 今日 |
| checkins 表唯一约束过严 | 高 | 低 (1小时) | Backend | 今日 |
| checkins 表缺少空间索引 | 中 | 低 (0.5小时) | Backend | 今日 |
| Flutter API 基础 URL 错误 | 高 | 低 (0.5小时) | App | 今日 |
| Flutter 缺少核心服务层 | 高 | 中 (8小时) | App | 明日 |
| 前端项目结构不完整 | 中 | 中 (6小时) | Frontend | 明日 |

### 5.2 中期技术债务 (V1.1 版本解决)

| 债务项 | 影响度 | 解决成本 | 负责方 | 解决时限 |
|--------|--------|----------|--------|----------|
| JSONB 字段优化 | 中 | 中 (16小时) | Backend | 下周 |
| 复合索引补充 | 中 | 低 (4小时) | Backend | 下周 |
| 审计日志表缺失 | 中 | 中 (12小时) | Backend | 下周 |
| 状态管理完善 | 中 | 中 (8小时) | App/Frontend | 下周 |
| 错误处理统一 | 中 | 中 (6小时) | 全端 | 下周 |

### 5.3 长期技术债务 (V2.0 规划)

| 债务项 | 影响度 | 解决成本 | 负责方 | 解决时限 |
|--------|--------|----------|--------|----------|
| 数据归档策略 | 低 | 高 (40小时) | Backend | 下月 |
| 实时分析分离 | 中 | 高 (60小时) | Backend | 下月 |
| 微服务拆分 | 中 | 高 (80小时) | 架构组 | 下季度 |
| 跨地域部署 | 低 | 高 (100小时) | DevOps | 下季度 |

### 5.4 技术演进路线建议

**阶段 A (本周): 基础修复**
1. 数据库高优先级问题修复
2. Flutter API 基础对接
3. 前端项目结构搭建
4. 基础 CI/CD 流水线

**阶段 B (下周): 功能完善**
1. 数据库性能优化实施
2. Flutter 业务功能实现
3. 前端核心页面开发
4. 接口联调测试

**阶段 C (下月): 体验优化**
1. 推荐算法优化
2. 性能监控完善
3. 用户体验改进
4. 技术债务清理

**阶段 D (下季度): 架构演进**
1. 微服务架构探索
2. 数据平台建设
3. AI 能力扩展
4. 国际化支持

---

## 6. 实施问题解决支持

### 6.1 常见问题解决方案

#### 问题1: 数据库分区策略实施失败
**症状**: pg_cron 扩展不可用，分区表创建失败
**解决方案**:
```sql
-- 方案A: 使用外部定时任务（如系统 crontab）
-- 在 crontab 中添加:
0 2 1 * * psql -U postgres -d mishi -c "SELECT create_monthly_partitions();"

-- 方案B: 手动执行分区管理
-- 每月手动执行分区创建脚本

-- 方案C: 使用 PostgreSQL 内置事件触发器
CREATE EVENT TRIGGER create_partitions_trigger
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE')
  EXECUTE FUNCTION create_partitions_function();
```

#### 问题2: Flutter 与 API 契约字段不匹配
**症状**: 模型解析失败，字段类型不一致
**解决方案**:
```dart
// 使用 json_serializable 自定义转换
@JsonSerializable()
class Poem {
  @JsonKey(name: 'poem_id')
  final int id;
  
  @JsonKey(fromJson: _parseContent)
  final List<String> content;
  
  Poem({required this.id, required this.content});
  
  factory Poem.fromJson(Map<String, dynamic> json) => _$PoemFromJson(json);
  
  static List<String> _parseContent(dynamic json) {
    if (json is List) return json.cast<String>();
    if (json is String) return json.split('\n');
    return [];
  }
}
```

#### 问题3: 前端 TypeScript 类型冗余
**症状**: 数据库模型、API 模型、前端模型定义重复
**解决方案**:
```typescript
// 使用类型生成工具
// 1. 从 OpenAPI/Swagger 生成 API 类型
// 2. 从数据库 schema 生成基础类型
// 3. 使用类型映射减少重复

// 基础类型
interface DbPoem {
  id: number;
  title: string;
  content: string; // JSONB 字符串
}

// API 类型 (自动生成)
interface ApiPoem {
  poem_id: number;
  title: string;
  content: string[];
}

// 前端类型 (组合扩展)
interface UIPoem extends ApiPoem {
  isFavorite?: boolean;
  isCheckedIn?: boolean;
}

// 转换函数
function mapDbPoemToApi(dbPoem: DbPoem): ApiPoem {
  return {
    poem_id: dbPoem.id,
    title: dbPoem.title,
    content: JSON.parse(dbPoem.content),
  };
}
```

#### 问题4: 跨平台位置服务差异
**症状**: iOS/Android/Web 位置获取 API 不一致
**解决方案**:
```dart
// 使用抽象位置服务
abstract class LocationService {
  Future<Location> getCurrentLocation();
  Stream<Location> getLocationUpdates();
}

// Flutter 实现
class FlutterLocationService implements LocationService {
  final Location _location = Location();
  
  @override
  Future<Location> getCurrentLocation() async {
    return await _location.getLocation();
  }
}

// Web 实现 (前端)
class WebLocationService implements LocationService {
  @override
  async getCurrentLocation(): Promise<Location> {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(
        (position) => resolve(position.coords),
        reject
      );
    });
  }
}
```

### 6.2 实时技术支持渠道

1. **紧急问题**: 在项目群中 @架构指导Agent D017
2. **技术讨论**: 使用 `collab/20_architecture/technical-discussion.md` 文档
3. **代码审查**: 提交 Pull Request 时添加 `@arch-review` 标签
4. **每日同步**: 每日 10:00 技术站会，同步进度和问题

---

## 7. 质量审查要点

### 7.1 数据库审查清单
- [ ] 所有外键约束使用 ON DELETE CASCADE
- [ ] checkins 表唯一约束使用按小时去重
- [ ] checkins 表 location 字段有 GIST 索引
- [ ] 分区策略已统一并验证
- [ ] 所有表 updated_at 字段有自动更新触发器
- [ ] 关键复合索引已创建
- [ ] JSONB 字段有适当的索引和约束

### 7.2 Flutter 审查清单
- [ ] Base URL 正确配置为 `https://api.mishi.app/v1`
- [ ] 认证头 (Authorization, X-Device-Id, X-App-Version) 正确实现
- [ ] 核心服务层 (GeoService, PoemService, CheckinService) 已实现
- [ ] 数据模型与 API 契约一致
- [ ] Riverpod Provider 架构正确
- [ ] 统一错误处理机制
- [ ] 分页参数标准化实现

### 7.3 前端审查清单
- [ ] 项目结构符合现代前端工程规范
- [ ] TypeScript 类型定义与 API 契约一致
- [ ] Zustand + TanStack Query 正确集成
- [ ] API 客户端配置正确
- [ ] 响应式设计和移动端适配
- [ ] 错误处理和加载状态

### 7.4 跨技术栈一致性审查
- [ ] 数据模型字段映射表已对齐
- [ ] 错误码处理逻辑一致
- [ ] 安全规范实现一致
- [ ] 性能指标监控对齐

---

## 8. 风险评估与应对

### 8.1 技术风险矩阵

| 风险项 | 概率 | 影响 | 应对措施 |
|--------|------|------|----------|
| 数据库性能不达预期 | 中 | 高 | 实施前性能测试，准备索引优化方案 |
| API 契约变更 | 低 | 高 | 冻结契约，变更需架构组审批 |
| 跨平台兼容性问题 | 中 | 中 | 早期真机测试，使用抽象层隔离平台差异 |
| 第三方服务依赖 | 中 | 中 | 实现降级策略，监控第三方服务状态 |
| 安全漏洞 | 低 | 高 | 代码安全扫描，定期安全审计 |

### 8.2 实施风险应对

**风险: 数据库迁移失败**
- **预案**: 准备回滚脚本，在低峰期执行，先备份全量数据
- **监控**: 迁移后立即验证数据一致性和查询性能
- **负责人**: Backend Agent + DBA

**风险: Flutter 构建问题**
- **预案**: 准备多套构建环境，固化依赖版本
- **监控**: CI/CD 流水线添加构建检查
- **负责人**: App Agent + DevOps

**风险: 前后端联调阻塞**
- **预案**: 使用 Mock Server 并行开发，定义清晰的接口契约
- **监控**: 每日接口兼容性检查
- **负责人**: 全端技术负责人

---

## 9. 下一步行动

### 9.1 立即行动 (今日)
1. **Backend Agent**: 执行数据库高优先级修复脚本
2. **App Agent**: 修正 Base URL，开始实现核心服务层
3. **Frontend Agent**: 完善项目结构，配置状态管理
4. **架构指导**: 监控各 Agent 进度，提供实时指导

### 9.2 短期计划 (本周内)
1. 完成数据库性能优化实施
2. 完成 Flutter 核心功能开发
3. 完成前端基础页面开发
4. 进行第一次跨技术栈联调

### 9.3 中期计划 (下周)
1. 性能测试和优化
2. 用户体验改进
3. 技术债务清理
4. 准备 V1.0 发布

---

**文档维护**:
- 每次架构决策变更需更新此文档
- 各 Agent 遇到技术问题可在此文档添加记录
- 每日技术站会前检查文档更新情况

**负责人**: 架构指导Agent D017  
**最后更新**: 2026-03-17 09:30  
**下次评审**: 2026-03-18 10:00