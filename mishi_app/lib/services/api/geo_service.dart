import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../models/geo_nearby_response.dart';

final geoServiceProvider = Provider<GeoService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return GeoService(dio);
});

class GeoService {
  final Dio _dio;

  GeoService(this._dio);

  /// 查询附近POI
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [radius] 搜索半径（米），默认1000
  /// [limit] 每页数量，默认20
  /// [offset] 偏移量，默认0
  Future<GeoNearbyResponse> fetchNearbyPOIs({
    required double latitude,
    required double longitude,
    double radius = 1000.0,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/geo/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'limit': limit,
          'offset': offset,
        },
      );
      return GeoNearbyResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 统一错误处理
  Exception _handleError(DioException e) {
    return apiExceptionFromDio(e, fallbackMessage: '附近地点加载失败，请稍后重试');
  }
}
