import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

class LocalStorage {
  Box get _auth => Hive.box('auth');
  Box get _favorites => Hive.box('favorites');
  Box get _continueWatching => Hive.box('continue_watching');
  Box get _seriesProgress => Hive.box('series_progress');

  // ── Xtream credentials ────────────────────────────────────────────────────
  String? getXtreamUrl() => _auth.get(StorageKeys.xtreamUrl) as String?;
  Future<void> saveXtreamUrl(String url) =>
      _auth.put(StorageKeys.xtreamUrl, url);

  String? getXtreamUsername() =>
      _auth.get(StorageKeys.xtreamUsername) as String?;
  Future<void> saveXtreamUsername(String username) =>
      _auth.put(StorageKeys.xtreamUsername, username);

  String? getXtreamPassword() =>
      _auth.get(StorageKeys.xtreamPassword) as String?;
  Future<void> saveXtreamPassword(String password) =>
      _auth.put(StorageKeys.xtreamPassword, password);

  // ── Session auth ──────────────────────────────────────────────────────────
  bool get isAuthenticated =>
      getXtreamUrl() != null &&
      getXtreamUsername() != null &&
      getXtreamPassword() != null;

  // ── User profile ──────────────────────────────────────────────────────────
  String? getUsername() => _auth.get(StorageKeys.username) as String?;
  Future<void> saveUsername(String username) =>
      _auth.put(StorageKeys.username, username);

  String? getSubscriptionType() =>
      _auth.get(StorageKeys.subscriptionType) as String?;
  Future<void> saveSubscriptionType(String type) =>
      _auth.put(StorageKeys.subscriptionType, type);

  String? getExpiresAt() => _auth.get(StorageKeys.expiresAt) as String?;
  Future<void> saveExpiresAt(String? isoDate) => isoDate != null
      ? _auth.put(StorageKeys.expiresAt, isoDate)
      : _auth.delete(StorageKeys.expiresAt);

  bool get isSubscriptionExpired {
    final raw = getExpiresAt();
    if (raw == null) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(raw));
    } catch (_) {
      return false;
    }
  }

  // ── Parental controls (local PIN, no backend) ─────────────────────────────
  bool get hideAdultContent =>
      (_auth.get(StorageKeys.hideAdultContent) as bool?) ?? false;
  Future<void> saveHideAdultContent(bool value) =>
      _auth.put(StorageKeys.hideAdultContent, value);

  String? getParentalPin() => _auth.get(StorageKeys.parentalPin) as String?;
  Future<void> saveParentalPin(String pin) =>
      _auth.put(StorageKeys.parentalPin, pin);
  Future<void> clearParentalPin() => _auth.delete(StorageKeys.parentalPin);

  bool verifyParentalPin(String pin) => getParentalPin() == pin;

  // ── Favorites ─────────────────────────────────────────────────────────────
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

  // ── Continue watching ──────────────────────────────────────────────────────
  Map<String, dynamic> _rawContinueWatching() {
    final raw = _continueWatching.get(StorageKeys.continueWatching);
    if (raw == null) return {};
    return Map<String, dynamic>.from(raw as Map);
  }

  Map<String, int> getContinueWatching() {
    return _rawContinueWatching().map((k, v) {
      final pos =
          v is List ? (v[0] as num).toInt() : (v as num).toInt();
      return MapEntry(k, pos);
    });
  }

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

  // ── Series progress ────────────────────────────────────────────────────────
  Future<void> saveSeriesLastEpisode(
      String seriesId, int season, String episodeId) async {
    await _seriesProgress.put(
        seriesId, {'season': season, 'episodeId': episodeId});
  }

  Map<String, dynamic>? getSeriesLastEpisode(String seriesId) {
    final raw = _seriesProgress.get(seriesId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── Clear all ─────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _auth.clear();
    await _favorites.clear();
    await _continueWatching.clear();
    await _seriesProgress.clear();
  }
}
