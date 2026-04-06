import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connect_world/core/storage/local_storage.dart';

/// Tests unitarios para LocalStorage.
/// Usan un directorio temporal en memoria para no necesitar un dispositivo.
void main() {
  late LocalStorage storage;

  setUpAll(() async {
    // Inicializar Hive en modo test (sin path real)
    Hive.init('.');
  });

  setUp(() async {
    // Abrir boxes frescas para cada test
    await Hive.openBox<dynamic>('auth');
    await Hive.openBox<dynamic>('favorites');
    await Hive.openBox<dynamic>('continue_watching');
    await Hive.openBox<dynamic>('series_progress');
    storage = LocalStorage();
  });

  tearDown(() async {
    await Hive.box<dynamic>('auth').clear();
    await Hive.box<dynamic>('favorites').clear();
    await Hive.box<dynamic>('continue_watching').clear();
    await Hive.box<dynamic>('series_progress').clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  // ── Auth ──────────────────────────────────────────────────────────────────

  group('Auth token', () {
    test('getAuthToken returns null when not set', () {
      expect(storage.getAuthToken(), isNull);
    });

    test('saveAuthToken and getAuthToken round-trip', () async {
      await storage.saveAuthToken('my-jwt-token');
      expect(storage.getAuthToken(), equals('my-jwt-token'));
    });

    test('isAuthenticated returns false when token is null', () {
      expect(storage.isAuthenticated, isFalse);
    });

    test('isAuthenticated returns true after saving a token', () async {
      await storage.saveAuthToken('some-token');
      expect(storage.isAuthenticated, isTrue);
    });

    test('clearAuth removes the token', () async {
      await storage.saveAuthToken('token-to-clear');
      await storage.clearAuth();
      expect(storage.getAuthToken(), isNull);
      expect(storage.isAuthenticated, isFalse);
    });
  });

  // ── Username ──────────────────────────────────────────────────────────────

  group('Username', () {
    test('getUsername returns null when not set', () {
      expect(storage.getUsername(), isNull);
    });

    test('saveUsername and getUsername round-trip', () async {
      await storage.saveUsername('alice');
      expect(storage.getUsername(), equals('alice'));
    });
  });

  // ── Subscription ──────────────────────────────────────────────────────────

  group('Subscription', () {
    test('getSubscriptionType returns null when not set', () {
      expect(storage.getSubscriptionType(), isNull);
    });

    test('saveSubscriptionType and getSubscriptionType round-trip', () async {
      await storage.saveSubscriptionType('active');
      expect(storage.getSubscriptionType(), equals('active'));
    });

    test('isSubscriptionExpired returns false when expiresAt is null', () {
      expect(storage.isSubscriptionExpired, isFalse);
    });

    test('isSubscriptionExpired returns true for past date', () async {
      final past = DateTime.now().subtract(const Duration(days: 1));
      await storage.saveExpiresAt(past.toIso8601String());
      expect(storage.isSubscriptionExpired, isTrue);
    });

    test('isSubscriptionExpired returns false for future date', () async {
      final future = DateTime.now().add(const Duration(days: 1));
      await storage.saveExpiresAt(future.toIso8601String());
      expect(storage.isSubscriptionExpired, isFalse);
    });

    test('wasMarkedExpired returns false by default', () {
      expect(storage.wasMarkedExpired, isFalse);
    });

    test('markSubscriptionExpired sets wasMarkedExpired to true', () async {
      await storage.markSubscriptionExpired();
      expect(storage.wasMarkedExpired, isTrue);
    });

    test('saveExpiresAt with null deletes the key', () async {
      await storage.saveExpiresAt('2025-01-01T00:00:00.000Z');
      await storage.saveExpiresAt(null);
      expect(storage.getExpiresAt(), isNull);
      expect(storage.isSubscriptionExpired, isFalse);
    });
  });

  // ── Parental Controls ─────────────────────────────────────────────────────

  group('Parental controls', () {
    test('hideAdultContent returns false by default', () {
      expect(storage.hideAdultContent, isFalse);
    });

    test('saveHideAdultContent(true) updates hideAdultContent', () async {
      await storage.saveHideAdultContent(true);
      expect(storage.hideAdultContent, isTrue);
    });

    test('saveHideAdultContent(false) updates hideAdultContent', () async {
      await storage.saveHideAdultContent(true);
      await storage.saveHideAdultContent(false);
      expect(storage.hideAdultContent, isFalse);
    });
  });

  // ── Favorites ─────────────────────────────────────────────────────────────

  group('Favorites', () {
    test('getFavoriteIds returns empty list by default', () {
      expect(storage.getFavoriteIds(), isEmpty);
    });

    test('toggleFavorite adds an id when not present', () async {
      await storage.toggleFavorite('stream-abc');
      expect(storage.getFavoriteIds(), contains('stream-abc'));
    });

    test('toggleFavorite removes an id when already present', () async {
      await storage.toggleFavorite('stream-abc');
      await storage.toggleFavorite('stream-abc');
      expect(storage.getFavoriteIds(), isNot(contains('stream-abc')));
    });

    test('isFavorite returns false before adding', () {
      expect(storage.isFavorite('stream-xyz'), isFalse);
    });

    test('isFavorite returns true after adding', () async {
      await storage.toggleFavorite('stream-xyz');
      expect(storage.isFavorite('stream-xyz'), isTrue);
    });

    test('multiple favorites are stored correctly', () async {
      await storage.toggleFavorite('id-1');
      await storage.toggleFavorite('id-2');
      await storage.toggleFavorite('id-3');
      final ids = storage.getFavoriteIds();
      expect(ids, containsAll(['id-1', 'id-2', 'id-3']));
      expect(ids.length, equals(3));
    });
  });

  // ── Continue Watching ─────────────────────────────────────────────────────

  group('Continue Watching', () {
    test('getContinueWatching returns empty map by default', () {
      expect(storage.getContinueWatching(), isEmpty);
    });

    test('saveContinueWatching and getContinueWatchingEntry round-trip', () async {
      await storage.saveContinueWatching('stream-1', 60000, 3600000);
      final entry = storage.getContinueWatchingEntry('stream-1');
      expect(entry, isNotNull);
      expect(entry![0], equals(60000));
      expect(entry[1], equals(3600000));
    });

    test('getContinueWatchingEntry returns null for unknown id', () {
      expect(storage.getContinueWatchingEntry('unknown-id'), isNull);
    });

    test('getContinueWatching returns positionMs map', () async {
      await storage.saveContinueWatching('s1', 10000, 90000);
      await storage.saveContinueWatching('s2', 20000, 120000);
      final map = storage.getContinueWatching();
      expect(map['s1'], equals(10000));
      expect(map['s2'], equals(20000));
    });

    test('overwriting continue watching updates the entry', () async {
      await storage.saveContinueWatching('stream-1', 10000, 3600000);
      await storage.saveContinueWatching('stream-1', 50000, 3600000);
      final entry = storage.getContinueWatchingEntry('stream-1');
      expect(entry![0], equals(50000));
    });
  });

  // ── Series Progress ───────────────────────────────────────────────────────

  group('Series Progress', () {
    test('getSeriesLastEpisode returns null when not set', () {
      expect(storage.getSeriesLastEpisode('series-123'), isNull);
    });

    test('saveSeriesLastEpisode and getSeriesLastEpisode round-trip', () async {
      await storage.saveSeriesLastEpisode('series-123', 2, 'ep-456');
      final progress = storage.getSeriesLastEpisode('series-123');
      expect(progress, isNotNull);
      expect(progress!['season'], equals(2));
      expect(progress['episodeId'], equals('ep-456'));
    });

    test('overwriting series progress updates correctly', () async {
      await storage.saveSeriesLastEpisode('series-123', 1, 'ep-1');
      await storage.saveSeriesLastEpisode('series-123', 2, 'ep-5');
      final progress = storage.getSeriesLastEpisode('series-123');
      expect(progress!['season'], equals(2));
      expect(progress['episodeId'], equals('ep-5'));
    });
  });
}
