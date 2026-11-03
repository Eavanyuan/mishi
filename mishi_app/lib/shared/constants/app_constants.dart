class AppConstants {
  // API 端点
  static const String apiBaseUrl = String.fromEnvironment(
    'MISHI_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/v1',
  );
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String poemsEndpoint = '/poems';
  static const String poemDetailEndpoint = '/poems/{id}';
  static const String profileEndpoint = '/profile';

  // 存储键名
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // 页面路由名称
  static const String routeHome = 'home';
  static const String routeLogin = 'login';
  static const String routeRegister = 'register';
  static const String routePoemDetail = 'poem_detail';
  static const String routeProfile = 'profile';

  // 应用设置
  static const int maxRetryCount = 3;
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // 默认推荐位置：扬州文昌阁附近。未获得定位权限时，用它保证首页仍可展示诗词。
  static const double defaultRecommendationLatitude = 32.3947;
  static const double defaultRecommendationLongitude = 119.4217;
}
