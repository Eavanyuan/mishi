// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoemImpl _$$PoemImplFromJson(Map<String, dynamic> json) => _$PoemImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  author: json['author'] as String,
  dynasty: json['dynasty'] as String,
  content: (json['content'] as List<dynamic>).map((e) => e as String).toList(),
  relatedPoiId: json['relatedPoiId'] as String?,
  relatedPoiName: json['relatedPoiName'] as String?,
  interpretations: (json['interpretations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  bestSeasons: (json['bestSeasons'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  hasAudio: json['hasAudio'] as bool? ?? false,
  audioUrl: json['audioUrl'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$PoemImplToJson(_$PoemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'dynasty': instance.dynasty,
      'content': instance.content,
      'relatedPoiId': instance.relatedPoiId,
      'relatedPoiName': instance.relatedPoiName,
      'interpretations': instance.interpretations,
      'bestSeasons': instance.bestSeasons,
      'hasAudio': instance.hasAudio,
      'audioUrl': instance.audioUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
