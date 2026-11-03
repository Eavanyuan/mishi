// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckinImpl _$$CheckinImplFromJson(Map<String, dynamic> json) =>
    _$CheckinImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      poiId: json['poi_id'] as String,
      poemId: json['poem_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      checkinTime: DateTime.parse(json['checkin_time'] as String),
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CheckinImplToJson(_$CheckinImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'poi_id': instance.poiId,
      'poem_id': instance.poemId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'checkin_time': instance.checkinTime.toIso8601String(),
      'device_info': instance.deviceInfo,
      'risk_score': instance.riskScore,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
