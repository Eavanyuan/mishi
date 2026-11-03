import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user, String token) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
  const AuthState._();
  
  // 辅助方法
  bool get isLoading => this is _Loading;
  bool get isError => this is _Error;
  bool get isAuthenticated => this is _Authenticated;
  bool get isUnauthenticated => this is _Unauthenticated;
  bool get isInitial => this is _Initial;
  
  // 获取错误消息（如果不是错误状态则返回null）
  String? get errorMessage {
    return maybeWhen(
      error: (message) => message,
      orElse: () => null,
    );
  }
  
  // 获取用户信息（如果已认证）
  User? get user {
    return maybeWhen(
      authenticated: (user, _) => user,
      orElse: () => null,
    );
  }
}
