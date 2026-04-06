import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import '../../../services/catalog_service.dart';

// ── Pagination page size ───────────────────────────────────────────────────
const _kPageSize = 100;

// ── State ──────────────────────────────────────────────────────────────────

class MoviesCatalogState {
  final List<Movie> items;
  final Map<String, int> genres; // genre name → count
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
      selectedGenre: clearGenre ? null : (selectedGenre ?? this.selectedGenre),
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
  final CatalogService _service;
  Timer? _debounce;

  MoviesCatalogNotifier(this._service) : super(const MoviesCatalogState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final genres = await _service.getMovieGenres();
      state = state.copyWith(genres: genres);
      await _fetchPage(1, reset: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchPage(int page, {bool reset = false}) async {
    // Solo mostrar spinner full-screen en la carga inicial (sin items aún)
    if (page == 1 && state.items.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    try {
      final items = await _service.getMovies(
        genre: state.selectedGenre,
        search: state.search.isEmpty ? null : state.search,
        page: page,
        limit: _kPageSize,
      );
      state = state.copyWith(
        items: reset ? items : [...state.items, ...items],
        page: page,
        hasMore: items.length == _kPageSize,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    _fetchPage(state.page + 1);
  }

  void onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      // No borrar items todavía — los items actuales se mantienen visibles
      // mientras llegan los nuevos, así el árbol de widgets no se destruye
      state = state.copyWith(search: query, page: 1, hasMore: true);
      _fetchPage(1, reset: true);
    });
  }

  void filterByGenre(String? genre) {
    if (genre == null) {
      state = state.copyWith(clearGenre: true, items: [], page: 1, hasMore: true);
    } else {
      state = state.copyWith(selectedGenre: genre, items: [], page: 1, hasMore: true);
    }
    _fetchPage(1, reset: true);
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
  return MoviesCatalogNotifier(ref.watch(catalogServiceProvider));
});
