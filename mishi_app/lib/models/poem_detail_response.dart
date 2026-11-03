import 'package:freezed_annotation/freezed_annotation.dart';
import 'poem.dart';

part 'poem_detail_response.freezed.dart';
part 'poem_detail_response.g.dart';

@freezed
class PoemDetailResponse with _$PoemDetailResponse {
  const factory PoemDetailResponse({
    required Poem data,
  }) = _PoemDetailResponse;

  factory PoemDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PoemDetailResponseFromJson(json);
}