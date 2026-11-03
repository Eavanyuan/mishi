import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? code;
  final int? statusCode;

  const ApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

ApiException apiExceptionFromEnvelope(
  Map<String, dynamic> envelope, {
  String fallbackMessage = '请求失败，请稍后重试',
}) {
  final code = _toInt(envelope['code']);
  final serverMessage = envelope['message']?.toString();
  return ApiException(
    _friendlyMessage(
      businessCode: code,
      serverMessage: serverMessage,
      fallbackMessage: fallbackMessage,
    ),
    code: code,
  );
}

ApiException apiExceptionFromDio(
  DioException e, {
  String fallbackMessage = '请求失败，请稍后重试',
}) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final code = _toInt(data['code']);
    final serverMessage = data['message']?.toString();
    return ApiException(
      _friendlyMessage(
        businessCode: code,
        statusCode: statusCode,
        serverMessage: serverMessage,
        fallbackMessage: fallbackMessage,
      ),
      code: code,
      statusCode: statusCode,
    );
  }

  if (statusCode != null) {
    return ApiException(
      _friendlyMessage(
        statusCode: statusCode,
        fallbackMessage: fallbackMessage,
      ),
      statusCode: statusCode,
    );
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiException('网络超时，请检查网络后重试');
    case DioExceptionType.connectionError:
      return const ApiException('网络连接失败，请检查网络后重试');
    case DioExceptionType.cancel:
      return const ApiException('请求已取消');
    default:
      return ApiException(fallbackMessage);
  }
}

String errorMessageOf(Object error, {String fallbackMessage = '请求失败，请稍后重试'}) {
  if (error is ApiException) {
    return error.message;
  }

  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    final message = raw.substring('Exception: '.length).trim();
    return message.isEmpty ? fallbackMessage : message;
  }

  return raw.isEmpty ? fallbackMessage : raw;
}

String _friendlyMessage({
  int? businessCode,
  int? statusCode,
  String? serverMessage,
  String fallbackMessage = '请求失败，请稍后重试',
}) {
  switch (businessCode) {
    case 40101:
      return '登录状态已失效，请重新登录';
    case 40301:
      return '暂无权限访问该内容';
    case 40302:
      return '当前位置偏差较大，请靠近目标地点后重试';
    case 40303:
      return '今天已在该地点打过卡了';
    case 40401:
      return '请求资源不存在';
    case 42901:
      return '操作太频繁，请稍后再试';
  }

  switch (statusCode) {
    case 401:
      return '登录状态已失效，请重新登录';
    case 403:
      return '暂无权限访问该内容';
    case 404:
      return '请求资源不存在';
    case 429:
      return '操作太频繁，请稍后再试';
    case 500:
    case 503:
      return '服务暂时不可用，请稍后再试';
  }

  final msg = serverMessage?.trim();
  if (msg != null && msg.isNotEmpty) {
    return msg;
  }

  return fallbackMessage;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
