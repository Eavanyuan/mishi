class Profile {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String userType;
  final int checkinCount;
  final int poemViewCount;
  final int audioPlayCount;
  final int status;

  Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.userType,
    required this.checkinCount,
    required this.poemViewCount,
    required this.audioPlayCount,
    required this.status,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Profile(
      id: (json['id'] ?? '').toString(),
      nickname: json['nickname']?.toString() ?? '用户',
      avatarUrl: json['avatar_url']?.toString(),
      userType: json['user_type']?.toString() ?? 'normal',
      checkinCount: asInt(json['checkin_count']),
      poemViewCount: asInt(json['poem_view_count']),
      audioPlayCount: asInt(json['audio_play_count']),
      status: asInt(json['status']),
    );
  }
}
