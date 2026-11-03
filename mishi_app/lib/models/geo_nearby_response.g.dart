// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_nearby_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GeoNearbyResponseImpl _$$GeoNearbyResponseImplFromJson(
  Map<String, dynamic> json,
) => _$GeoNearbyResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => POI.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['total_count'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
);

Map<String, dynamic> _$$GeoNearbyResponseImplToJson(
  _$GeoNearbyResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total_count': instance.totalCount,
  'limit': instance.limit,
  'offset': instance.offset,
};
