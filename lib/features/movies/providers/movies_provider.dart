import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import '../../../services/xtream_service.dart';
import '../../../core/constants/app_constants.dart';

const _kPageSize = AppConstants.catalogPageSize;

// ── State ──────────────────────────────────────────────────────────────────

class MoviesCatalogState {
  final List<Movie> items;
  final Map<String, int> genres;
  final String? selectedGenre;
  final String search;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const MoviesCatalogState({
    this.items = const [],
    this.genres = const {},
    this.selectedGenre,
    this.search = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  MoviesCatalogState copyWith({
    List<Movie>? items,
    Map<String, int>? genres,
    String? selectedGenre,
    bool clearGenre = false,
    String? search,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return MoviesCatalogState(
      items: items ?? this.items,
      genres: genres ?? this.genres,
      selectedGenre:
          clearGenre ? null : (selectedGenre ?? this.selectedGenre),
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class MoviesCatalogNotifier extends StateNotifier<MoviesCatalogState> {
  final Ref _ref;
  List<Movie> _allMovies = [];
  Timer? _debounce;

  MoviesCatalogNotifier(this._ref) : super(const MoviesCatalogState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _allMovies = await _ref.read(rawMoviesProvider.future);

      final genres = <String, int>{};
      for (final m in _allMovies) {
        if (m.genre?.isNotEmpty == true) {
          genres[m.genre!] = (genres[m.genre!] ?? 0) + 1;
        }
      }

      state = state.copyWith(genres: genres, isLoading: false);
      _applyFilter(reset: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<Movie> _filteredItems() {
    var items = _allMovies;
    if (state.selectedGenre != null) {
      items = items.where((m) => m.genre == state.selectedGenre).toList();
    }
    if (state.search.isNotEmpty) {
      final q = state.search.toLowerCase();
      items = items.where((m) => m.title.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  void _applyFilter({bool reset = false}) {
    final filtered = _filteredItems();
    final startIndex = reset ? 0 : state.items.length;
    final page = reset ? 1 : state.page + 1;
    final nextBatch =
        filtered.skip(startIndex).take(_kPageSize).toList();

    state = state.copyWith(
      items: reset ? nextBatch : [...state.items, ...nextBatch],
      page: page,
      hasMore: startIndex + nextBatch.length < filtered.length,
      isLoading: false,
      isLoadingMore: false,
    );
  }

  void loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    _applyFilter();
  }

  void onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
          search: query, items: [], page: 1, hasMore: true);
      _applyFilter(reset: true);
    });
  }

  void filterByGenre(String? genre) {
    if (genre == null) {
      state = state.copyWith(
          clearGenre: true, items: [], page: 1, hasMore: true);
    } else {
      state = state.copyWith(
          selectedGenre: genre, items: [], page: 1, hasMore: true);
    }
    _applyFilter(reset: true);
  }

  void retry() => _init();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final moviesCatalogProvider =
    StateNotifierProvider<MoviesCatalogNotifier, MoviesCatalogState>((ref) {
  return MoviesCatalogNotifier(ref);
});
