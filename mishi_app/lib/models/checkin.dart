import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin.freezed.dart';
part 'checkin.g.dart';

@freezed
class Checkin with _$Checkin {
  const factory Checkin({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'poi_id') required String poiId,
    @JsonKey(name: 'poem_id') required String poemId,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'checkin_time') required DateTime checkinTime,
    @JsonKey(name: 'device_info') Map<String, dynamic>? deviceInfo,
    @JsonKey(name: 'risk_score') @Default(0.0) double riskScore,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Checkin;

  factory Checkin.fromJson(Map<String, dynamic> json) => _$CheckinFromJson(json);
}