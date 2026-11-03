import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/poem_detail/pages/poem_detail_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/profile/pages/checkin_history_page.dart';
import '../../providers/auth_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../auth/session_events.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/poem/:id',
        name: 'poem_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PoemDetailPage(poemId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/checkins',
        name: 'checkin_history',
        builder: (context, state) => const CheckinHistoryPage(),
      ),
    ],
    redirect: (context, state) {
      // 认证重定向逻辑（优先根据本地 token 判断会话有效性）
      final currentPath = state.matchedLocation;
      final isAuthRoute =
          currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password';

      return SharedPreferences.getInstance().then((prefs) {
        final token = prefs.getString(AppConstants.authTokenKey);
        final hasToken = token != null && token.isNotEmpty;
        final authState = ref.read(authProvider);

        // 持久化 token 优先于 provider 冷启动状态，避免启动阶段在 /home 与 /login 间来回抖动。
        if (hasToken) {
          return isAuthRoute ? '/home' : null;
        }

        if (!isAuthRoute) {
          return '/login';
        }

        // 兜底：当 token 尚未落盘但 provider 已切换为已登录时，允许从认证页进入首页。
        if (authState.isAuthenticated && isAuthRoute) {
          return '/home';
        }
        return null;
      });
    },
    refreshListenable: authSessionVersionNotifier,
  );
});

// 辅助类，用于将Stream转换为GoRouter的RefreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
