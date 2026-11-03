import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

@freezed
class POI with _$POI {
  const factory POI({
    required String id,
    required String name,
    @JsonKey(name: 'ancient_name') String? ancientName,
    @JsonKey(name: 'modern_name') String? modernName,
    required double latitude,
    required double longitude,
    @Default(100.0) double radius,
    @JsonKey(name: 'city_code') String? cityCode,
    String? description,
    List<String>? categories,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _POI;

  factory POI.fromJson(Map<String, dynamic> json) => _$POIFromJson(json);
}