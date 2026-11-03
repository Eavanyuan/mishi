import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../models/poem.dart';
import '../../shared/constants/app_constants.dart';

final poemServiceProvider = Provider<PoemService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PoemService(dio);
});

class PoemService {
  final Dio _dio;

  PoemService(this._dio);

  /// 获取推荐诗词列表
  /// [latitude] 纬度（可选，用于地理位置推荐）
  /// [longitude] 经度（可选）
  /// [season] 季节（可选）
  /// [limit] 每页数量，默认20
  /// [offset] 偏移量，默认0
  Future<List<Poem>> fetchRecommendations({
    double? latitude,
    double? longitude,
    String? season,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'lat': latitude ?? AppConstants.defaultRecommendationLatitude,
        'lon': longitude ?? AppConstants.defaultRecommendationLongitude,
      };
      if (season != null) queryParams['season'] = season;

      final response = await _dio.get(
        '/poems/recommend',
        queryParameters: queryParams,
      );
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '推荐加载失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      final poemsRaw = data['poems'] as List<dynamic>? ?? const [];
      return poemsRaw
          .map((item) => _mapRecommendationToPoem(_asMap(item)))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 搜索诗词
  Future<List<Poem>> searchPoems({
    required String keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/poems/search',
        queryParameters: {'q': keyword, 'limit': limit, 'offset': offset},
      );
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(envelope, fallbackMessage: '搜索失败，请稍后重试');
      }
      final data = _asMap(envelope['data']);
      final poemsRaw = data['poems'] as List<dynamic>? ?? const [];
      return poemsRaw
          .map((item) => _mapRecommendationToPoem(_asMap(item)))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取诗词详情
  /// [poemId] 诗词ID
  Future<Poem> fetchPoemDetail(String poemId) async {
    try {
      final response = await _dio.get('/poems/$poemId');
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '详情加载失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      return _mapDetailToPoem(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 统一错误处理
  Exception _handleError(DioException e) {
    return apiExceptionFromDio(e, fallbackMessage: '诗词请求失败，请稍后重试');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  Poem _mapRecommendationToPoem(Map<String, dynamic> item) {
    final content = (item['content'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final relatedPoi =
        (item['related_poi'] as Map<String, dynamic>?) ?? const {};

    return Poem(
      id: (item['poem_id'] ?? '').toString(),
      title: item['title']?.toString() ?? '',
      author: item['author']?.toString() ?? '',
      dynasty: item['dynasty']?.toString() ?? '',
      content: content,
      relatedPoiId: relatedPoi['poi_id']?.toString(),
      relatedPoiName: relatedPoi['name']?.toString(),
      bestSeasons: item['season_tag'] != null
          ? [item['season_tag'].toString()]
          : null,
      hasAudio: false,
      audioUrl: item['audio_url']?.toString(),
    );
  }

  Poem _mapDetailToPoem(Map<String, dynamic> data) {
    final content = (data['content'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final bestSeasons = (data['best_seasons'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    final interpretations = <String>[];
    final interpretationsMap = data['interpretations'] as Map<String, dynamic>?;
    if (interpretationsMap != null) {
      for (final key in ['basic', 'textbook', 'academic']) {
        final section = interpretationsMap[key] as Map<String, dynamic>?;
        final contentText = section?['content']?.toString();
        if (contentText != null && contentText.isNotEmpty) {
          interpretations.add(contentText);
        }
      }
    }

    final media = data['media'] as Map<String, dynamic>? ?? const {};
    final hasAudio = media['has_audio'] == true;
    final audioUrl =
        media['audio_url']?.toString() ?? data['audio_url']?.toString();
    final relatedPois = data['related_pois'] as List<dynamic>? ?? const [];
    final primaryPoi = relatedPois.isNotEmpty
        ? (relatedPois.first as Map<String, dynamic>?) ?? const {}
        : const {};

    return Poem(
      id: (data['poem_id'] ?? data['id'] ?? '').toString(),
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      dynasty: data['dynasty']?.toString() ?? '',
      content: content,
      relatedPoiId: primaryPoi['poi_id']?.toString(),
      relatedPoiName: primaryPoi['name']?.toString(),
      interpretations: interpretations.isEmpty ? null : interpretations,
      bestSeasons: bestSeasons.isEmpty ? null : bestSeasons,
      hasAudio: hasAudio,
      audioUrl: audioUrl,
    );
  }
}
