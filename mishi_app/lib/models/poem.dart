import 'package:freezed_annotation/freezed_annotation.dart';

part 'poem.freezed.dart';
part 'poem.g.dart';

@freezed
class Poem with _$Poem {
  const factory Poem({
    required String id,
    required String title,
    required String author,
    required String dynasty,
    required List<String> content,
    String? relatedPoiId,
    String? relatedPoiName,
    List<String>? interpretations,
    List<String>? bestSeasons,
    @Default(false) bool hasAudio,
    String? audioUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Poem;

  factory Poem.fromJson(Map<String, dynamic> json) => _$PoemFromJson(json);
}
