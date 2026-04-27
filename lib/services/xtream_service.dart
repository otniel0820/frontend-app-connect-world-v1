import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/storage/local_storage.dart';
import '../features/auth/providers/auth_provider.dart';
import '../models/catalog.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/series_episode.dart';
import '../models/stream_info.dart';

// ── Version counter — increment on login/logout to invalidate all data ──────
final providerVersionProvider = StateProvider<int>((ref) => 0);

// ── Main service provider ────────────────────────────────────────────────────
final xtreamServiceProvider = Provider<XtreamService>((ref) {
  ref.watch(providerVersionProvider); // Re-create when credentials change
  final storage = ref.read(localStorageProvider);
  return XtreamService(storage);
});

// ── Raw data providers (cached until invalidated) ────────────────────────────
final rawLiveStreamsProvider = FutureProvider<List<Channel>>((ref) async {
  ref.watch(providerVersionProvider);
  if (ref.read(demoModeProvider)) return _demoChannels;
  return ref.read(xtreamServiceProvider).getLiveStreams();
});

final rawMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  ref.watch(providerVersionProvider);
  if (ref.read(demoModeProvider)) return _demoMovies;
  return ref.read(xtreamServiceProvider).getVodStreams();
});

final rawSeriesProvider = FutureProvider<List<Series>>((ref) async {
  ref.watch(providerVersionProvider);
  if (ref.read(demoModeProvider)) return _demoSeries;
  return ref.read(xtreamServiceProvider).getSeriesList();
});

// ── Demo data ────────────────────────────────────────────────────────────────
const _demoChannels = [
  Channel(id: 'live:1', name: 'Canal 1', groupTitle: 'General'),
  Channel(id: 'live:2', name: 'Canal 2', groupTitle: 'General'),
  Channel(id: 'live:3', name: 'Noticias 24', groupTitle: 'Noticias'),
  Channel(id: 'live:4', name: 'Deportes HD', groupTitle: 'Deportes'),
  Channel(id: 'live:5', name: 'Cine Clásico', groupTitle: 'Cine'),
  Channel(id: 'live:6', name: 'Infantil', groupTitle: 'Entretenimiento'),
];

const _demoMovies = [
  Movie(id: 'vod:1:mp4', title: 'Aventura en el Espacio', genre: 'Ciencia Ficción', releaseYear: '2023', rating: 8.2, durationMinutes: 124),
  Movie(id: 'vod:2:mp4', title: 'La Gran Escapada', genre: 'Acción', releaseYear: '2022', rating: 7.5, durationMinutes: 108),
  Movie(id: 'vod:3:mp4', title: 'Corazón Valiente', genre: 'Drama', releaseYear: '2023', rating: 7.9, durationMinutes: 135),
  Movie(id: 'vod:4:mp4', title: 'La Última Misión', genre: 'Acción', releaseYear: '2021', rating: 6.8, durationMinutes: 98),
  Movie(id: 'vod:5:mp4', title: 'Entre Dos Mundos', genre: 'Drama', releaseYear: '2022', rating: 8.0, durationMinutes: 115),
  Movie(id: 'vod:6:mp4', title: 'Noche Sin Fin', genre: 'Thriller', releaseYear: '2023', rating: 7.3, durationMinutes: 102),
  Movie(id: 'vod:7:mp4', title: 'El Tiempo Perdido', genre: 'Romance', releaseYear: '2021', rating: 7.1, durationMinutes: 118),
  Movie(id: 'vod:8:mp4', title: 'Sombras del Pasado', genre: 'Thriller', releaseYear: '2022', rating: 7.6, durationMinutes: 127),
];

const _demoSeries = [
  Series(id: '101', title: 'El Detective', genre: 'Crimen', releaseYear: '2022', rating: 8.5, seasons: 3),
  Series(id: '102', title: 'Familias', genre: 'Drama', releaseYear: '2021', rating: 7.8, seasons: 2),
  Series(id: '103', title: 'Código Rojo', genre: 'Acción', releaseYear: '2023', rating: 8.1, seasons: 1),
  Series(id: '104', title: 'El Mundo de Ana', genre: 'Comedia', releaseYear: '2022', rating: 7.4, seasons: 4),
  Series(id: '105', title: 'Fronteras', genre: 'Thriller', releaseYear: '2023', rating: 8.3, seasons: 2),
  Series(id: '106', title: 'Historia Viva', genre: 'Documental', releaseYear: '2021', rating: 9.0, seasons: 1),
];

// ── Account info model ───────────────────────────────────────────────────────
class XtreamAccount {
  final String username;
  final String status;
  final DateTime? expiresAt;

  const XtreamAccount({
    required this.username,
    required this.status,
    this.expiresAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
}

// ── Service ──────────────────────────────────────────────────────────────────
class XtreamService {
  final LocalStorage _storage;
  late final Dio _dio;

  XtreamService(this._storage) {
    _dio = Dio(BaseOptions(
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
    }
  }

  String get _serverUrl => _storage.getXtreamUrl() ?? '';
  String get _username => _storage.getXtreamUsername() ?? '';
  String get _password => _storage.getXtreamPassword() ?? '';

  String get _apiUrl => '$_serverUrl/player_api.php';

  Map<String, String> get _baseParams => {
        'username': _username,
        'password': _password,
      };

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Validates credentials against Xtream server. Accepts explicit params
  /// so it can be called before credentials are stored in Hive.
  Future<XtreamAccount> authenticate(
    String serverUrl,
    String username,
    String password,
  ) async {
    final url = '$serverUrl/player_api.php';
    final response = await _dio.get<dynamic>(url, queryParameters: {
      'username': username,
      'password': password,
    });

    final data = response.data;
    if (data is! Map) throw Exception('Respuesta inesperada del servidor');

    final userInfo = data['user_info'];
    if (userInfo is! Map) throw Exception('Credenciales inválidas');

    final auth = userInfo['auth'];
    if (auth == 0 || auth == '0' || auth == false) {
      throw Exception('Usuario o contraseña incorrectos');
    }

    final status = userInfo['status']?.toString() ?? 'Unknown';
    final expDate = userInfo['exp_date'];
    DateTime? expiresAt;
    if (expDate != null && expDate != '0' && expDate != '') {
      final ts = int.tryParse(expDate.toString());
      if (ts != null && ts > 0) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      }
    }

    return XtreamAccount(
      username: username,
      status: status,
      expiresAt: expiresAt,
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<Map<String, String>> _fetchCategories(String action) async {
    try {
      final response = await _dio.get<dynamic>(
        _apiUrl,
        queryParameters: {..._baseParams, 'action': action},
      );
      final data = response.data;
      if (data is! List) return {};
      final map = <String, String>{};
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['category_id']?.toString();
        final name = item['category_name']?.toString();
        if (id != null && name != null) map[id] = name;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  // ── Live streams ──────────────────────────────────────────────────────────

  Future<List<Channel>> getLiveStreams() async {
    final results = await Future.wait([
      _fetchCategories('get_live_categories'),
      _dio.get<dynamic>(_apiUrl,
          queryParameters: {..._baseParams, 'action': 'get_live_streams'}),
    ]);

    final categories = results[0] as Map<String, String>;
    final response = results[1] as Response;
    final data = response.data;
    if (data is! List) return [];

    return data.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final streamId = m['stream_id']?.toString() ?? '';
      final catId = m['category_id']?.toString() ?? '';
      return Channel(
        id: 'live:$streamId',
        name: m['name']?.toString() ?? '',
        logoUrl: _normalizeUrl(m['stream_icon']?.toString()),
        groupTitle: categories[catId] ?? catId,
        epgId: m['epg_channel_id']?.toString(),
      );
    }).toList();
  }

  // ── VOD streams ───────────────────────────────────────────────────────────

  Future<List<Movie>> getVodStreams() async {
    final results = await Future.wait([
      _fetchCategories('get_vod_categories'),
      _dio.get<dynamic>(_apiUrl,
          queryParameters: {..._baseParams, 'action': 'get_vod_streams'}),
    ]);

    final categories = results[0] as Map<String, String>;
    final response = results[1] as Response;
    final data = response.data;
    if (data is! List) return [];

    return data.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final streamId = m['stream_id']?.toString() ?? '';
      final ext = m['container_extension']?.toString() ?? 'mp4';
      final catId = m['category_id']?.toString() ?? '';
      final rawRating = m['rating'];
      final rating = rawRating != null ? double.tryParse(rawRating.toString()) : null;
      return Movie(
        id: 'vod:$streamId:$ext',
        title: m['name']?.toString() ?? '',
        posterUrl: _normalizeUrl(m['stream_icon']?.toString()),
        genre: categories[catId] ?? catId,
        rating: rating,
      );
    }).toList();
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<List<Series>> getSeriesList() async {
    final results = await Future.wait([
      _fetchCategories('get_series_categories'),
      _dio.get<dynamic>(_apiUrl,
          queryParameters: {..._baseParams, 'action': 'get_series'}),
    ]);

    final categories = results[0] as Map<String, String>;
    final response = results[1] as Response;
    final data = response.data;
    if (data is! List) return [];

    return data.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final seriesId = m['series_id']?.toString() ?? '';
      final catId = m['category_id']?.toString() ?? '';

      String? backdropUrl;
      final backdropPaths = m['backdrop_path'];
      if (backdropPaths is List && backdropPaths.isNotEmpty) {
        backdropUrl = _normalizeUrl(backdropPaths.first?.toString());
      }

      final rawRating = m['rating'];
      final rating = rawRating != null ? double.tryParse(rawRating.toString()) : null;

      return Series(
        id: seriesId,
        title: m['name']?.toString() ?? '',
        posterUrl: _normalizeUrl(m['cover']?.toString()),
        backdropUrl: backdropUrl,
        overview: m['plot']?.toString(),
        genre: m['genre']?.toString().isNotEmpty == true
            ? m['genre']!.toString()
            : (categories[catId] ?? catId),
        releaseYear: m['releaseDate']?.toString(),
        rating: rating,
      );
    }).toList();
  }

  // ── Series episodes ───────────────────────────────────────────────────────

  Future<List<SeriesEpisode>> getSeriesEpisodes(String seriesId) async {
    try {
      final response = await _dio.get<dynamic>(
        _apiUrl,
        queryParameters: {
          ..._baseParams,
          'action': 'get_series_info',
          'series_id': seriesId,
        },
      );
      final data = response.data;
      if (data is! Map) return [];

      final episodesMap = data['episodes'];
      if (episodesMap is! Map) return [];

      final episodes = <SeriesEpisode>[];
      for (final entry in episodesMap.entries) {
        final seasonEps = entry.value;
        if (seasonEps is! List) continue;
        for (final ep in seasonEps) {
          if (ep is! Map) continue;
          final m = Map<String, dynamic>.from(ep);
          final streamId = m['id']?.toString() ?? '';
          final ext = m['container_extension']?.toString() ?? 'mkv';
          final infoRaw = m['info'];
          final info = infoRaw is Map
              ? Map<String, dynamic>.from(infoRaw)
              : <String, dynamic>{};

          int? durationSecs;
          final durRaw = info['duration_secs'];
          if (durRaw != null) {
            durationSecs = (durRaw is num)
                ? durRaw.toInt()
                : int.tryParse(durRaw.toString());
          }

          episodes.add(SeriesEpisode(
            id: 'ep:$streamId:$ext',
            title: m['title']?.toString() ??
                'Episodio ${m['episode_num']?.toString() ?? ''}',
            season: (m['season'] as num?)?.toInt() ?? 1,
            episode: (m['episode_num'] as num?)?.toInt() ?? 1,
            overview: info['plot']?.toString(),
            coverUrl: _normalizeUrl(info['movie_image']?.toString()),
            durationSecs: durationSecs,
          ));
        }
      }

      episodes.sort((a, b) {
        final sc = a.season.compareTo(b.season);
        if (sc != 0) return sc;
        return a.episode.compareTo(b.episode);
      });
      return episodes;
    } catch (_) {
      return [];
    }
  }

  // ── Stream URL builder ────────────────────────────────────────────────────

  /// Builds a playable URL from the encoded stream ID.
  /// ID format:
  ///   live:{stream_id}           → /live/{user}/{pass}/{id}.m3u8
  ///   vod:{stream_id}:{ext}      → /movie/{user}/{pass}/{id}.{ext}
  ///   ep:{stream_id}:{ext}       → /series/{user}/{pass}/{id}.{ext}
  StreamInfo buildStreamInfo(String encodedId) {
    final parts = encodedId.split(':');
    final type = parts.isNotEmpty ? parts[0] : '';
    String url;

    switch (type) {
      case 'live':
        final sid = parts.length >= 2 ? parts[1] : '';
        url = '$_serverUrl/live/$_username/$_password/$sid.m3u8';
        break;
      case 'vod':
        final sid = parts.length >= 2 ? parts[1] : '';
        final ext = parts.length >= 3 ? parts[2] : 'mp4';
        url = '$_serverUrl/movie/$_username/$_password/$sid.$ext';
        break;
      case 'ep':
        final sid = parts.length >= 2 ? parts[1] : '';
        final ext = parts.length >= 3 ? parts[2] : 'mkv';
        url = '$_serverUrl/series/$_username/$_password/$sid.$ext';
        break;
      default:
        url = encodedId; // Fallback: treat as raw URL
    }

    return StreamInfo(id: encodedId, url: url);
  }

  // ── Home catalog (subset) ─────────────────────────────────────────────────

  Future<Catalog> getHomeCatalog({int limit = AppConstants.homeRowLimit}) async {
    final results = await Future.wait([
      getLiveStreams(),
      getVodStreams(),
      getSeriesList(),
    ]);
    final channels = results[0] as List<Channel>;
    final movies = results[1] as List<Movie>;
    final series = results[2] as List<Series>;

    return Catalog(
      channels: channels.take(limit).toList(),
      movies: movies.take(limit).toList(),
      series: series.take(limit).toList(),
      featured: movies.take(5).toList(),
    );
  }

  // ── EPG (short) ───────────────────────────────────────────────────────────

  /// Returns short EPG for a live channel (stream_id without 'live:' prefix).
  Future<List<Map<String, dynamic>>> getShortEpg(String streamId, {int limit = 4}) async {
    try {
      final response = await _dio.get<dynamic>(
        _apiUrl,
        queryParameters: {
          ..._baseParams,
          'action': 'get_short_epg',
          'stream_id': streamId,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is! Map) return [];
      final listings = data['epg_listings'];
      if (listings is! List) return [];
      return listings.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url;
  }
}
