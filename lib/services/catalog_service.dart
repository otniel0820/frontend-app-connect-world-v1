import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/networking/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/catalog.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/series_episode.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(ref.watch(apiClientProvider));
});

class CatalogService {
  final ApiClient _client;

  CatalogService(this._client);

  Future<Catalog> getCatalog() async {
    final response = await _client.get<Map<String, dynamic>>(ApiConstants.catalog);
    final json = Map<String, dynamic>.from(response.data!);
    // Normalize series IDs and titles to strings before hitting generated fromJson.
    if (json['series'] is List) {
      json['series'] = (json['series'] as List).map((e) {
        if (e is! Map) return e;
        final m = Map<String, dynamic>.from(e);
        m['id'] = m['id']?.toString() ?? '';
        m['title'] = m['title']?.toString() ?? m['name']?.toString() ?? '';
        return m;
      }).toList();
    }
    return Catalog.fromJson(json);
  }

  Future<List<Channel>> getChannels() async {
    final response = await _client.get<List<dynamic>>(ApiConstants.channels);
    return (response.data as List)
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> getMovieGenres() async {
    final response = await _client.get<List<dynamic>>('${ApiConstants.movies}/genres');
    final map = <String, int>{};
    for (final e in response.data as List) {
      final m = e as Map<String, dynamic>;
      map[m['genre'] as String] = m['count'] as int;
    }
    return map;
  }

  Future<List<Movie>> getMovies({String? genre, String? search, int page = 1, int limit = 100}) async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.movies,
      queryParameters: {
        if (genre != null) 'genre': genre,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> getSeriesGenres() async {
    final response = await _client.get<List<dynamic>>('${ApiConstants.series}/genres');
    final map = <String, int>{};
    for (final e in response.data as List) {
      final m = e as Map<String, dynamic>;
      map[m['genre'] as String] = m['count'] as int;
    }
    return map;
  }

  Future<List<Series>> getSeries({String? genre, String? search, int page = 1, int limit = 100}) async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.series,
      queryParameters: {
        if (genre != null) 'genre': genre,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data as List).map((e) {
      final map = e as Map<String, dynamic>;
      final normalized = Map<String, dynamic>.from(map);
      normalized['id'] = map['id']?.toString() ?? '';
      normalized['title'] =
          map['title']?.toString() ?? map['name']?.toString() ?? '';
      return Series.fromJson(normalized);
    }).toList();
  }

  Future<List<SeriesEpisode>> getSeriesEpisodes(String seriesId) async {
    final dynamic response;
    try {
      response = await _client.get<dynamic>(
        ApiConstants.seriesEpisodes(seriesId),
      );
    } catch (e) {
      // 404 or any network error → no episodes available
      return [];
    }

    List<dynamic> rawEpisodes;

    if (response.data is List) {
      // Flat list format: [{...}, {...}, ...]
      rawEpisodes = response.data as List<dynamic>;
    } else if (response.data is Map) {
      // Nested object format: {"info": {...}, "episodes": {"1": [...], "2": [...]}}
      final dataMap = response.data as Map<String, dynamic>;

      // Try common top-level keys that hold episode collections.
      final episodesValue = dataMap['episodes'] ??
          dataMap['data'] ??
          dataMap['items'] ??
          dataMap['seasons'];

      if (episodesValue is List) {
        rawEpisodes = episodesValue;
      } else if (episodesValue is Map) {
        // Season-keyed map: {"1": [...], "2": [...]}
        rawEpisodes = episodesValue.values
            .expand((v) => v is List ? v : [v])
            .toList();
      } else {
        // No recognised episode container — return empty list.
        rawEpisodes = [];
      }
    } else {
      rawEpisodes = [];
    }

    return rawEpisodes
        .whereType<Map>()
        .map((e) => SeriesEpisode.fromJson(
            Map<String, dynamic>.from(e)))
        .toList();
  }
}
