import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/catalog.dart';
import '../../../services/xtream_service.dart';
import '../../../core/constants/app_constants.dart';

/// Home catalog — a limited subset of each content type for the home screen.
/// Uses the cached raw providers so the full catalog isn't fetched again
/// when visiting the Movies / Series / Live TV screens.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  // Depend on raw providers so this refreshes when they do (on login/logout)
  final channels = await ref.watch(rawLiveStreamsProvider.future);
  final movies = await ref.watch(rawMoviesProvider.future);
  final series = await ref.watch(rawSeriesProvider.future);

  const limit = AppConstants.homeRowLimit;

  return Catalog(
    channels: channels.take(limit).toList(),
    movies: movies.take(limit).toList(),
    series: series.take(limit).toList(),
    featured: movies.take(5).toList(),
  );
});
