import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/catalog.dart';
import '../../../models/channel.dart';
import '../../../models/movie.dart';
import '../../../models/series.dart';
import '../../../services/xtream_service.dart';
import '../../../core/constants/app_constants.dart';

/// Home catalog — a limited subset of each content type for the home screen.
/// Uses the cached raw providers so the full catalog isn't fetched again
/// when visiting the Movies / Series / Live TV screens.
///
/// Carga resiliente: si una sección falla (p.ej. el proveedor tarda demasiado
/// con un catálogo enorme), las demás secciones igual se muestran. Solo si
/// TODAS fallan se propaga el error real a la UI para poder diagnosticar.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  // Depend on raw providers so this refreshes when they do (on login/logout)
  Object? firstError;

  List<Channel> channels = const [];
  List<Movie> movies = const [];
  List<Series> series = const [];

  try {
    channels = await ref.watch(rawLiveStreamsProvider.future);
  } catch (e) {
    firstError ??= e;
  }
  try {
    movies = await ref.watch(rawMoviesProvider.future);
  } catch (e) {
    firstError ??= e;
  }
  try {
    series = await ref.watch(rawSeriesProvider.future);
  } catch (e) {
    firstError ??= e;
  }

  // Si nada cargó, mostramos el error real (no el genérico).
  if (channels.isEmpty && movies.isEmpty && series.isEmpty && firstError != null) {
    throw firstError;
  }

  const limit = AppConstants.homeRowLimit;

  return Catalog(
    channels: channels.take(limit).toList(),
    movies: movies.take(limit).toList(),
    series: series.take(limit).toList(),
    featured: movies.take(5).toList(),
  );
});
