import 'package:freezed_annotation/freezed_annotation.dart';
import 'checkin.dart';

part 'checkin_response.freezed.dart';
part 'checkin_response.g.dart';

@freezed
class CheckinResponse with _$CheckinResponse {
  const factory CheckinResponse({
    required Checkin data,
  }) = _CheckinResponse;

  factory CheckinResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckinResponseFromJson(json);
}