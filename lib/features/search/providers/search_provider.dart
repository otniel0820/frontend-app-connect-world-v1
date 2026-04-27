import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/catalog.dart';
import '../../../services/xtream_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Searches across the full raw catalog (not just the home-screen subset).
final searchResultsProvider = Provider<AsyncValue<Catalog>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return const AsyncData(Catalog());

  final moviesAsync = ref.watch(rawMoviesProvider);
  final seriesAsync = ref.watch(rawSeriesProvider);
  final channelsAsync = ref.watch(rawLiveStreamsProvider);

  // If any data is still loading, propagate loading
  if (moviesAsync.isLoading ||
      seriesAsync.isLoading ||
      channelsAsync.isLoading) {
    return const AsyncLoading();
  }

  // If any error, propagate it
  final error =
      moviesAsync.error ?? seriesAsync.error ?? channelsAsync.error;
  if (error != null) {
    return AsyncError(error, StackTrace.empty);
  }

  final movies = moviesAsync.value ?? [];
  final series = seriesAsync.value ?? [];
  final channels = channelsAsync.value ?? [];

  return AsyncData(Catalog(
    movies: movies
        .where((m) => m.title.toLowerCase().contains(query))
        .toList(),
    series: series
        .where((s) => s.title.toLowerCase().contains(query))
        .toList(),
    channels: channels
        .where((c) => c.name.toLowerCase().contains(query))
        .toList(),
  ));
});
