import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/auth_service.dart';
import '../core/auth/session_events.dart';
import '../models/user.dart';
import 'auth_state.dart';
import '../shared/constants/app_constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  late final AuthService _authService;
  late final SharedPreferences _prefs;
  late final Future<void> _prefsReady;

  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _authService = _ref.read(authServiceProvider);
    _prefsReady = _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _persistSession(LoginResponse response) async {
    await _prefs.setString(AppConstants.authTokenKey, response.accessToken);
    await _prefs.setString('refresh_token', response.refreshToken);
    await _prefs.setString(
      AppConstants.userDataKey,
      json.encode(response.user.toJson()),
    );

    state = AuthState.authenticated(response.user, response.accessToken);
    notifyAuthSessionInvalidated();
  }

  /// 用户登录
  Future<void> login(String email, String password) async {
    await _prefsReady;
    state = const AuthState.loading();
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      await _persistSession(response);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('登录失败: ${e.toString()}');
    }
  }

  /// 用户注册
  Future<void> register(String email, String password, String username) async {
    await _prefsReady;
    state = const AuthState.loading();
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        username: username,
      );
      await _persistSession(response);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('注册失败: ${e.toString()}');
    }
  }

  /// 用户登出
  Future<void> logout() async {
    await _prefsReady;
    try {
      await _authService.logout();
    } catch (e) {
      // 登出API失败不影响本地清理
    }
    // 清除本地存储
    await _prefs.remove(AppConstants.authTokenKey);
    await _prefs.remove('refresh_token');
    await _prefs.remove(AppConstants.userDataKey);

    state = const AuthState.unauthenticated();
    notifyAuthSessionInvalidated();
  }

  /// 发送手机号验证码
  Future<SMSCodeResponse> sendSMSCode(String phone) async {
    try {
      return await _authService.sendSMSCode(phone.trim());
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('验证码发送失败: ${e.toString()}', 0);
    }
  }

  /// 手机号验证码登录/注册
  Future<void> loginWithSMSCode(String phone, String code) async {
    await _prefsReady;
    state = const AuthState.loading();
    try {
      final response = await _authService.loginWithSMSCode(
        phone: phone.trim(),
        code: code.trim(),
      );
      await _persistSession(response);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('手机号登录失败: ${e.toString()}');
    }
  }

  /// 刷新Token
  Future<void> refreshToken() async {
    await _prefsReady;
    final refreshToken = _prefs.getString('refresh_token');
    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final response = await _authService.refreshToken(refreshToken);
      await _prefs.setString(AppConstants.authTokenKey, response.accessToken);
      await _prefs.setString('refresh_token', response.refreshToken);
      // 刷新成功，状态不变
    } on AuthException catch (_) {
      // 刷新失败，登出
      await logout();
      state = const AuthState.error('会话已过期，请重新登录');
    } catch (e) {
      // 其他错误，保持当前状态
      debugPrint('刷新Token失败: $e');
    }
  }

  /// 检查认证状态
  Future<void> checkAuthStatus() async {
    try {
      await _prefsReady; // 确保_prefs已初始化
      final token = _prefs.getString(AppConstants.authTokenKey);
      final userJsonString = _prefs.getString(AppConstants.userDataKey);

      if (token != null && userJsonString != null) {
        try {
          final userJson = json.decode(userJsonString) as Map<String, dynamic>;
          final user = User.fromJson(userJson);
          state = AuthState.authenticated(user, token);
          notifyAuthSessionInvalidated();
        } catch (e) {
          // JSON解析失败，清除无效数据
          await _prefs.remove(AppConstants.authTokenKey);
          await _prefs.remove(AppConstants.userDataKey);
          state = const AuthState.unauthenticated();
          notifyAuthSessionInvalidated();
        }
      } else {
        state = const AuthState.unauthenticated();
        notifyAuthSessionInvalidated();
      }
    } catch (e) {
      state = AuthState.error('检查认证状态失败: ${e.toString()}');
    }
  }

  /// 发送忘记密码邮件
  Future<String?> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '发送重置邮件失败: $e';
    }
  }

  /// 提交重置密码
  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword(
        token: token.trim(),
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '重置密码失败: $e';
    }
  }
}
