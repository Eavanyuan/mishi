import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../models/profile.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ProfileService(dio);
});

class ProfileService {
  final Dio _dio;

  ProfileService(this._dio);

  Future<Profile> fetchProfile(String userId) async {
    try {
      final response = await _dio.get('/profile/$userId');
      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const ApiException('响应格式错误，请稍后重试');
      }
      if (payload['code'] != 0) {
        throw apiExceptionFromEnvelope(
          payload,
          fallbackMessage: '获取个人信息失败，请稍后重试',
        );
      }
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>? ?? {};
      return Profile.fromJson(user);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e, fallbackMessage: '获取个人信息失败，请稍后重试');
    }
  }
}
