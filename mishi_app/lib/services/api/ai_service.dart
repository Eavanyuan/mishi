import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../models/ai_job.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AIService(dio);
});

class AIService {
  final Dio _dio;

  AIService(this._dio);

  Future<String> createJob({
    required String jobType,
    required String poemId,
    String? style,
    String? voice,
    String? text,
    int? seconds,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/jobs',
        data: {
          'job_type': jobType,
          'poem_id': int.tryParse(poemId) ?? 0,
          'style': style,
          'voice': voice,
          'text': text,
          'seconds': seconds,
        },
      );
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '创建 AI 任务失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      final jobId = data['job_id']?.toString() ?? '';
      if (jobId.isEmpty) {
        throw const ApiException('AI 任务创建失败：job_id 为空');
      }
      return jobId;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e, fallbackMessage: '创建 AI 任务失败，请稍后重试');
    }
  }

  Future<AIJob> getJob(String jobId) async {
    try {
      final response = await _dio.get('/ai/jobs/$jobId');
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '查询 AI 任务失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      return AIJob.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e, fallbackMessage: '查询 AI 任务失败，请稍后重试');
    }
  }

  Future<AILatestInterpretationSnapshot?> getLatestInterpretation(
    String poemId,
  ) async {
    try {
      final response = await _dio.get('/poems/$poemId/interpretation/ai');
      final envelope = _asMap(response.data);
      if (envelope['code'] != 0) {
        throw apiExceptionFromEnvelope(
          envelope,
          fallbackMessage: '查询 AI 解读失败，请稍后重试',
        );
      }
      final data = _asMap(envelope['data']);
      return AILatestInterpretationSnapshot.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return null;
      }
      throw apiExceptionFromDio(e, fallbackMessage: '查询 AI 解读失败，请稍后重试');
    }
  }

  Future<AIJob> waitForJob(
    String jobId, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    AIJob? latest;
    for (var i = 0; i < maxAttempts; i++) {
      latest = await getJob(jobId);
      if (!latest.isRunning) {
        return latest;
      }
      await Future.delayed(interval);
    }
    throw ApiException('AI 任务执行超时（job_id=$jobId）');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }
}
