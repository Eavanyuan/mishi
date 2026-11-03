import 'package:freezed_annotation/freezed_annotation.dart';
import 'poem.dart';

part 'poem_recommendation_response.freezed.dart';
part 'poem_recommendation_response.g.dart';

@freezed
class PoemRecommendationResponse with _$PoemRecommendationResponse {
  const factory PoemRecommendationResponse({
    required List<Poem> items,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'limit') required int limit,
    @JsonKey(name: 'offset') required int offset,
  }) = _PoemRecommendationResponse;

  factory PoemRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$PoemRecommendationResponseFromJson(json);
}