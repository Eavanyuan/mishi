import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_error.dart';
import '../services/api/poem_service.dart';
import 'poem_state.dart';

final poemProvider = StateNotifierProvider<PoemNotifier, PoemState>(
  (ref) => PoemNotifier(ref.watch(poemServiceProvider)),
);

class PoemNotifier extends StateNotifier<PoemState> {
  final PoemService _poemService;

  PoemNotifier(this._poemService) : super(const PoemState.initial());

  Future<void> fetchRecommendations({
    double? latitude,
    double? longitude,
    String? season,
    int limit = 20,
    int offset = 0,
    bool loadMore = false,
  }) async {
    if (state.isLoading) return;
    final previousPoems = state.poems;
    final previousRecommendations = state.recommendations;
    state = const PoemState.loading();
    try {
      final poems = await _poemService.fetchRecommendations(
        latitude: latitude,
        longitude: longitude,
        season: season,
        limit: limit,
        offset: offset,
      );
      state = PoemState.loaded(
        poems: loadMore ? [...previousPoems, ...poems] : poems,
        recommendations: poems,
        hasMore: poems.length >= limit,
        totalCount: loadMore
            ? previousPoems.length + poems.length
            : poems.length,
      );
    } catch (e) {
      if (previousPoems.isNotEmpty || previousRecommendations.isNotEmpty) {
        state = PoemState.loaded(
          poems: previousPoems,
          recommendations: previousRecommendations,
          hasMore: false,
          totalCount: previousPoems.length,
        );
      } else {
        state = PoemState.error(errorMessageOf(e));
      }
    }
  }

  Future<void> fetchPoemDetail(String poemId) async {
    try {
      final poem = await _poemService.fetchPoemDetail(poemId);
      final currentPoems = state.poems;
      final exists = currentPoems.any((p) => p.id == poem.id);
      final updatedPoems = exists
          ? currentPoems.map((p) => p.id == poem.id ? poem : p).toList()
          : [...currentPoems, poem];

      state = PoemState.loaded(
        poems: updatedPoems,
        recommendations: state.recommendations,
        hasMore: false,
        totalCount: updatedPoems.length,
      );
    } catch (e) {
      state = PoemState.error(errorMessageOf(e));
    }
  }

  Future<void> searchPoems(String query) async {
    if (state.isLoading) return;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await fetchRecommendations();
      return;
    }
    state = const PoemState.loading();
    try {
      final poems = await _poemService.searchPoems(keyword: trimmed);
      state = PoemState.loaded(
        poems: poems,
        recommendations: poems,
        hasMore: false,
        totalCount: poems.length,
      );
    } catch (e) {
      state = PoemState.error(errorMessageOf(e));
    }
  }
}
