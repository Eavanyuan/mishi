import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/poem.dart';

part 'poem_state.freezed.dart';

@freezed
class PoemState with _$PoemState {
  const factory PoemState.initial() = _Initial;
  const factory PoemState.loading() = _Loading;
  const factory PoemState.loaded({
    required List<Poem> poems,
    required List<Poem> recommendations,
    @Default(false) bool hasMore,
    @Default(0) int totalCount,
    @Default(false) bool isLoadingMore,
  }) = _Loaded;
  const factory PoemState.error(String message) = _Error;

  const PoemState._();

  bool get isLoading => this is _Loading;
  bool get isLoaded => this is _Loaded;
  bool get isError => this is _Error;

  List<Poem> get poems => maybeMap(
        loaded: (state) => state.poems,
        orElse: () => [],
      );

  List<Poem> get recommendations => maybeMap(
        loaded: (state) => state.recommendations,
        orElse: () => [],
      );
}
