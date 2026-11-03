import 'package:freezed_annotation/freezed_annotation.dart';
import 'poi.dart';

part 'geo_nearby_response.freezed.dart';
part 'geo_nearby_response.g.dart';

@freezed
class GeoNearbyResponse with _$GeoNearbyResponse {
  const factory GeoNearbyResponse({
    required List<POI> items,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'limit') required int limit,
    @JsonKey(name: 'offset') required int offset,
  }) = _GeoNearbyResponse;

  factory GeoNearbyResponse.fromJson(Map<String, dynamic> json) =>
      _$GeoNearbyResponseFromJson(json);
}