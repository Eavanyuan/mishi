import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/session_events.dart';
import '../../shared/constants/app_constants.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final refreshCoordinator = _RefreshCoordinator();

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 添加拦截器
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加认证 token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // 添加设备ID和应用版本头
        final deviceId = prefs.getString('device_id');
        if (deviceId != null) {
          options.headers['X-Device-Id'] = deviceId;
        }

        final packageInfo = await PackageInfo.fromPlatform();
        options.headers['X-App-Version'] = packageInfo.version;
        options.headers['X-Platform'] = 'flutter';

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 可在此处理响应统一格式
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        // Token 刷新逻辑（401 时尝试刷新）
        final requestPath = error.requestOptions.path;
        final isAuthRequest = requestPath.contains('/auth/login') || requestPath.contains('/auth/refresh');
        final hasRetried = error.requestOptions.extra['retried'] == true;

        if (error.response?.statusCode == 401 && !isAuthRequest && !hasRetried) {
          final refreshedToken = await refreshCoordinator.refreshToken();
          if (refreshedToken != null) {
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $refreshedToken';
            retryOptions.extra['retried'] = true;
            final retryResponse = await dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(AppConstants.authTokenKey);
          await prefs.remove('refresh_token');
          await prefs.remove(AppConstants.userDataKey);
          notifyAuthSessionInvalidated();
        }
        // 统一错误处理
        return handler.next(error);
      },
    ),
  );

  // 添加设备ID初始化逻辑
  _initDeviceId();

  return dio;
});

class _RefreshCoordinator {
  Completer<String?>? _refreshCompleter;

  Future<String?> refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
      } else {
        final refreshClient = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final response = await refreshClient.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic> &&
            response.data['code'] == 0) {
          final data = response.data['data'] as Map<String, dynamic>? ?? {};
          final newAccessToken = data['access_token']?.toString();
          final newRefreshToken = data['refresh_token']?.toString();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await prefs.setString(AppConstants.authTokenKey, newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await prefs.setString('refresh_token', newRefreshToken);
            }
            _refreshCompleter!.complete(newAccessToken);
          } else {
            _refreshCompleter!.complete(null);
          }
        } else {
          _refreshCompleter!.complete(null);
        }
      }
    } catch (_) {
      _refreshCompleter?.complete(null);
    }

    final future = _refreshCompleter!.future;
    _refreshCompleter = null;
    return future;
  }
}

Future<void> _initDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('device_id')) {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      // 如果获取失败，生成一个UUID
      deviceId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    }
    await prefs.setString('device_id', deviceId ?? 'unknown');
  }
}
