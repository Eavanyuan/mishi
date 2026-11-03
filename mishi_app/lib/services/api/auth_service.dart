import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../shared/constants/app_constants.dart';
import '../../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// 用户登录
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      final data = _extractData(response.data);
      final userData = (data['user'] as Map<String, dynamic>?) ?? {};

      return LoginResponse(
        accessToken:
            data['access_token']?.toString() ?? data['token']?.toString() ?? '',
        refreshToken: data['refresh_token']?.toString() ?? '',
        user: _mapUser(userData, fallbackEmail: email),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 用户注册
  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: {'email': email, 'password': password, 'username': username},
      );
      final data = _extractData(response.data);
      final userData = (data['user'] as Map<String, dynamic>?) ?? {};

      return RegisterResponse(
        accessToken:
            data['access_token']?.toString() ?? data['token']?.toString() ?? '',
        refreshToken: data['refresh_token']?.toString() ?? '',
        user: _mapUser(
          userData,
          fallbackEmail: email,
          fallbackUsername: username,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送手机号验证码
  Future<SMSCodeResponse> sendSMSCode(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/sms/send-code',
        data: {'phone': phone},
      );
      final data = _extractData(response.data);
      return SMSCodeResponse(
        sent: data['sent'] == true,
        devMode: data['dev_mode'] == true,
        code: data['code']?.toString(),
        expiresIn: (data['expires_in'] as num?)?.toInt() ?? 300,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 手机号验证码登录/注册
  Future<LoginResponse> loginWithSMSCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/sms/login',
        data: {'phone': phone, 'code': code},
      );
      final data = _extractData(response.data);
      final userData = (data['user'] as Map<String, dynamic>?) ?? {};

      return LoginResponse(
        accessToken:
            data['access_token']?.toString() ?? data['token']?.toString() ?? '',
        refreshToken: data['refresh_token']?.toString() ?? '',
        user: _mapUser(
          userData,
          fallbackEmail: '',
          fallbackUsername:
              '诗友${phone.length >= 4 ? phone.substring(phone.length - 4) : ''}',
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 刷新Token
  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = _extractData(response.data);
      return RefreshTokenResponse(
        accessToken: data['access_token']?.toString() ?? '',
        refreshToken: data['refresh_token']?.toString() ?? refreshToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // 登出失败不影响本地状态清除
      debugPrint('登出请求失败: ${e.message}');
    }
  }

  /// 忘记密码：发送重置邮件
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 重置密码：使用邮件中的token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 统一错误处理
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data as Map<String, dynamic>?;
      final errorCode = data?['code'] ?? statusCode ?? 0;
      final errorMessage = data?['message'] ?? '未知错误';

      // 根据错误码返回具体异常
      switch (errorCode) {
        case 40101:
          return AuthException('认证失败，请重新登录', errorCode);
        case 40001:
          return AuthException('邮箱或密码错误', errorCode);
        case 40901:
          return AuthException('邮箱已被注册', errorCode);
        case 404:
        case 40401:
          return AuthException('接口不存在或用户不存在', errorCode);
        default:
          return AuthException('认证错误 ($errorCode): $errorMessage', errorCode);
      }
    } else {
      return AuthException('网络错误: ${e.message}', 0);
    }
  }

  Map<String, dynamic> _extractData(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw AuthException('响应格式错误', 50001);
    }
    if (payload['code'] != 0) {
      throw AuthException(
        payload['message']?.toString() ?? '请求失败',
        payload['code'] is int ? payload['code'] as int : 50001,
      );
    }
    return (payload['data'] as Map<String, dynamic>?) ?? {};
  }

  User _mapUser(
    Map<String, dynamic> userData, {
    required String fallbackEmail,
    String? fallbackUsername,
  }) {
    return User(
      id: (userData['id'] ?? '').toString(),
      username:
          userData['nickname']?.toString() ??
          userData['username']?.toString() ??
          fallbackUsername ??
          '用户',
      email: userData['email']?.toString() ?? fallbackEmail,
      avatarUrl:
          userData['avatar_url']?.toString() ??
          userData['avatarUrl']?.toString(),
    );
  }
}

/// 登录响应
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// 注册响应
class RegisterResponse extends LoginResponse {
  RegisterResponse({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });
}

/// 刷新Token响应
class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({required this.accessToken, required this.refreshToken});
}

/// 短信验证码响应
class SMSCodeResponse {
  final bool sent;
  final bool devMode;
  final String? code;
  final int expiresIn;

  SMSCodeResponse({
    required this.sent,
    required this.devMode,
    required this.code,
    required this.expiresIn,
  });
}

/// 认证异常
class AuthException implements Exception {
  final String message;
  final int code;

  AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException(code: $code): $message';
}
