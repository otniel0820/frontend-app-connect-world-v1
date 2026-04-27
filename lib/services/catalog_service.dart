import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/series_episode.dart';
import '../core/constants/app_constants.dart';
import 'xtream_service.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(ref.watch(xtreamServiceProvider));
});

class CatalogService {
  final XtreamService _xtream;

  CatalogService(this._xtream);

  Future<Catalog> getCatalog() async {
    return _xtream.getHomeCatalog(limit: AppConstants.homeRowLimit);
  }

  Future<List<Channel>> getChannels() async {
    return _xtream.getLiveStreams();
  }

  Future<List<Movie>> getMovies({
    String? genre,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    // Movies are loaded all at once from Xtream; filtering is done client-side
    // in MoviesCatalogNotifier. This method is kept for API compatibility.
    final all = await _xtream.getVodStreams();
    return all;
  }

  Future<Map<String, int>> getMovieGenres() async {
    final movies = await _xtream.getVodStreams();
    final genres = <String, int>{};
    for (final m in movies) {
      if (m.genre?.isNotEmpty == true) {
        genres[m.genre!] = (genres[m.genre!] ?? 0) + 1;
      }
    }
    return genres;
  }

  Future<List<Series>> getSeries({
    String? genre,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final all = await _xtream.getSeriesList();
    return all;
  }

  Future<Map<String, int>> getSeriesGenres() async {
    final series = await _xtream.getSeriesList();
    final genres = <String, int>{};
    for (final s in series) {
      if (s.genre?.isNotEmpty == true) {
        genres[s.genre!] = (genres[s.genre!] ?? 0) + 1;
      }
    }
    return genres;
  }

  Future<List<SeriesEpisode>> getSeriesEpisodes(String seriesId) async {
    return _xtream.getSeriesEpisodes(seriesId);
  }
}
