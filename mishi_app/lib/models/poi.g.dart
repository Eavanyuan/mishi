// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$POIImpl _$$POIImplFromJson(Map<String, dynamic> json) => _$POIImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  ancientName: json['ancient_name'] as String?,
  modernName: json['modern_name'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
  cityCode: json['city_code'] as String?,
  description: json['description'] as String?,
  categories: (json['categories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$POIImplToJson(_$POIImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'ancient_name': instance.ancientName,
  'modern_name': instance.modernName,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'radius': instance.radius,
  'city_code': instance.cityCode,
  'description': instance.description,
  'categories': instance.categories,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
