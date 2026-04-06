import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

class LocalStorage {
  Box get _auth => Hive.box('auth');
  Box get _favorites => Hive.box('favorites');
  Box get _continueWatching => Hive.box('continue_watching');
  Box get _seriesProgress => Hive.box('series_progress');

  // Auth
  String? getAuthToken() => _auth.get(StorageKeys.authToken) as String?;
  Future<void> saveAuthToken(String token) => _auth.put(StorageKeys.authToken, token);
  String? getUsername() => _auth.get(StorageKeys.username) as String?;
  Future<void> saveUsername(String username) => _auth.put(StorageKeys.username, username);
  String? getServerUrl() => _auth.get(StorageKeys.serverUrl) as String?;
  Future<void> saveServerUrl(String url) => _auth.put(StorageKeys.serverUrl, url);

  // Subscription
  String? getSubscriptionType() => _auth.get(StorageKeys.subscriptionType) as String?;
  Future<void> saveSubscriptionType(String type) =>
      _auth.put(StorageKeys.subscriptionType, type);
  String? getExpiresAt() => _auth.get(StorageKeys.expiresAt) as String?;
  Future<void> saveExpiresAt(String? isoDate) =>
      isoDate != null ? _auth.put(StorageKeys.expiresAt, isoDate) : _auth.delete(StorageKeys.expiresAt);

  bool get isSubscriptionExpired {
    final raw = getExpiresAt();
    if (raw == null) return false;
    return DateTime.now().isAfter(DateTime.parse(raw));
  }

  bool get wasMarkedExpired => (_auth.get(StorageKeys.subscriptionExpired) as bool?) ?? false;
  Future<void> markSubscriptionExpired() =>
      _auth.put(StorageKeys.subscriptionExpired, true);

  Future<void> clearAuth() async {
    await _auth.clear();
  }

  bool get isAuthenticated => getAuthToken() != null;

  // Parental controls
  bool get hideAdultContent =>
      (_auth.get(StorageKeys.hideAdultContent) as bool?) ?? false;
  Future<void> saveHideAdultContent(bool value) =>
      _auth.put(StorageKeys.hideAdultContent, value);

  // Favorites
  List<String> getFavoriteIds() {
    final raw = _favorites.get(StorageKeys.favorites);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  Future<void> toggleFavorite(String id) async {
    final ids = getFavoriteIds();
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await _favorites.put(StorageKeys.favorites, ids);
  }

  bool isFavorite(String id) => getFavoriteIds().contains(id);

  // Continue Watching — stores [positionMs, durationMs] per id
  Map<String, dynamic> _rawContinueWatching() {
    final raw = _continueWatching.get(StorageKeys.continueWatching);
    if (raw == null) return {};
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Returns positionMs for each id (backward-compatible).
  Map<String, int> getContinueWatching() {
    return _rawContinueWatching().map((k, v) {
      final pos = v is List ? (v[0] as num).toInt() : (v as num).toInt();
      return MapEntry(k, pos);
    });
  }

  /// Returns [positionMs, durationMs] for the given id, or null if not found.
  List<int>? getContinueWatchingEntry(String id) {
    final raw = _rawContinueWatching()[id];
    if (raw == null) return null;
    if (raw is List) {
      return [(raw[0] as num).toInt(), (raw[1] as num).toInt()];
    }
    return [(raw as num).toInt(), 0];
  }

  Future<void> saveContinueWatching(
      String id, int positionMs, int durationMs) async {
    final map = _rawContinueWatching();
    map[id] = [positionMs, durationMs];
    await _continueWatching.put(StorageKeys.continueWatching, map);
  }

  // Series progress — remembers the last episode watched per series
  Future<void> saveSeriesLastEpisode(
      String seriesId, int season, String episodeId) async {
    await _seriesProgress.put(seriesId, {'season': season, 'episodeId': episodeId});
  }

  /// Returns {season, episodeId} for the given series, or null if never watched.
  Map<String, dynamic>? getSeriesLastEpisode(String seriesId) {
    final raw = _seriesProgress.get(seriesId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }
}
