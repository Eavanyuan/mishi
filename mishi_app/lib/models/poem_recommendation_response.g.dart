// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poem_recommendation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoemRecommendationResponseImpl _$$PoemRecommendationResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PoemRecommendationResponseImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => Poem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['total_count'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
);

Map<String, dynamic> _$$PoemRecommendationResponseImplToJson(
  _$PoemRecommendationResponseImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'total_count': instance.totalCount,
  'limit': instance.limit,
  'offset': instance.offset,
};
