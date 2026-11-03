import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../models/checkin_history.dart';

final checkinServiceProvider = Provider<CheckinService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CheckinService(dio);
});

class CheckinService {
  final Dio _dio;

  CheckinService(this._dio);

  /// 提交打卡记录
  /// [poiId] POI ID
  /// [poemId] 诗词 ID
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [deviceInfo] 设备信息（可选）
  Future<CheckinSubmitResult> submitCheckin({
    required String poiId,
    required String poemId,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final payload = {
        'poi_id': poiId,
        'poem_id': poemId,
        'latitude': latitude,
        'longitude': longitude,
        'device_info': deviceInfo,
      };
      final response = await _dio.post('/checkins', data: payload);
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(envelope, fallbackMessage: '打卡失败，请稍后重试');
      }
      final data = _asMap(envelope['data']);
      return CheckinSubmitResult(
        checkinId: (data['checkin_id'] ?? '').toString(),
        poiName: data['poi_name']?.toString() ?? '',
        poemTitle: data['poem_title']?.toString() ?? '',
        checkinTime:
            DateTime.tryParse(data['checkin_time']?.toString() ?? '') ??
            DateTime.now(),
        cardUrl: data['card_url']?.toString(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CheckinHistoryResponse> fetchHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/checkins/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '获取打卡历史失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      final checkinsRaw = data['checkins'] as List<dynamic>? ?? const [];
      final stats = _asMap(data['stats']);
      final checkins = checkinsRaw
          .map((e) => CheckinHistoryItem.fromJson(_asMap(e)))
          .toList();
      return CheckinHistoryResponse(
        checkins: checkins,
        total: _asInt(data['total']),
        totalPois: _asInt(stats['total_pois']),
        totalCities: _asInt(stats['total_cities']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 统一错误处理
  Exception _handleError(DioException e) {
    return apiExceptionFromDio(e, fallbackMessage: '打卡请求失败，请稍后重试');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
