DateTime? _parseDateTime(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}

String? _firstNonEmptyString(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

bool _containsAny(String? value, Iterable<String> keywords) {
  final text = value?.trim().toLowerCase();
  if (text == null || text.isEmpty) return false;
  for (final keyword in keywords) {
    if (text.contains(keyword.toLowerCase())) return true;
  }
  return false;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class AIJob {
  final String jobId;
  final String jobType;
  final String status;
  final String provider;
  final int errorCode;
  final String? errorMessage;
  final Map<String, dynamic> output;

  const AIJob({
    required this.jobId,
    required this.jobType,
    required this.status,
    required this.provider,
    required this.output,
    required this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isRunning => status == 'running' || status == 'pending';

  Map<String, dynamic> get result => _asMap(output['result']);

  Map<String, dynamic> get artifacts => _asMap(output['artifacts']);

  String? get text => _firstNonEmptyString([
        output['text'],
        result['text'],
        output['interpretation'],
        result['interpretation'],
      ]);

  String? get audioUrl => _firstNonEmptyString([
        output['audio_url'],
        result['audio_url'],
        artifacts['audio_url'],
      ]);

  String? get videoUrl => _firstNonEmptyString([
        output['video_url'],
        result['video_url'],
        artifacts['video_url'],
      ]);

  String? get thumbnailUrl => _firstNonEmptyString([
        output['thumbnail_url'],
        result['thumbnail_url'],
        artifacts['thumbnail_url'],
      ]);

  bool get isProviderNotConfigured =>
      errorCode == 50102 ||
      _containsAny(errorMessage, ['provider not configured', 'not configured', '未配置']);

  bool get isCapabilityUnsupported =>
      errorCode == 50101 ||
      _containsAny(errorMessage, [
        'capability not supported',
        'not supported',
        'unsupported',
        '不支持',
      ]);

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'running':
        return '生成中';
      case 'success':
        return '已完成';
      case 'failed':
        return '已失败';
      default:
        return status;
    }
  }

  String get userFacingFailureMessage {
    if (isProviderNotConfigured) {
      return '当前 AI 提供方未配置密钥，请先检查后端配置后重试';
    }
    if (isCapabilityUnsupported) {
      return '当前 AI 提供方暂不支持该能力，请切换 provider 后重试';
    }
    final message = errorMessage?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'AI 任务执行失败，请稍后重试';
  }

  factory AIJob.fromJson(Map<String, dynamic> json) {
    return AIJob(
      jobId: json['job_id']?.toString() ?? '',
      jobType: json['job_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      errorCode: _toInt(json['error_code']),
      errorMessage: json['error_message']?.toString(),
      output: _asMap(json['output'] ?? json['output_payload']),
    );
  }
}

class AILatestInterpretationSnapshot {
  final String poemId;
  final String? provider;
  final String? interpretation;
  final String? jobId;
  final DateTime? finishedAt;

  const AILatestInterpretationSnapshot({
    required this.poemId,
    this.provider,
    this.interpretation,
    this.jobId,
    this.finishedAt,
  });

  bool get hasInterpretation {
    final text = interpretation?.trim();
    return text != null && text.isNotEmpty;
  }

  factory AILatestInterpretationSnapshot.fromJson(Map<String, dynamic> json) {
    return AILatestInterpretationSnapshot(
      poemId: json['poem_id']?.toString() ?? '',
      provider: json['provider']?.toString(),
      interpretation: json['interpretation']?.toString(),
      jobId: json['job_id']?.toString(),
      finishedAt: _parseDateTime(json['finished_at']),
    );
  }
}
