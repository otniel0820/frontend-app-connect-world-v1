import 'package:flutter_test/flutter_test.dart';
import 'package:connect_world/models/user.dart';
import 'package:connect_world/models/movie.dart';
import 'package:connect_world/models/channel.dart';
import 'package:connect_world/models/series.dart';

void main() {
  // ── User model ────────────────────────────────────────────────────────────

  group('User.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'user-1',
        'username': 'alice',
        'token': 'jwt-abc',
        'subscriptionType': 'demo',
        'expiresAt': '2026-12-31T00:00:00.000Z',
      };
      final user = User.fromJson(json);

      expect(user.id, equals('user-1'));
      expect(user.username, equals('alice'));
      expect(user.token, equals('jwt-abc'));
      expect(user.subscriptionType, equals('demo'));
      expect(user.expiresAt, equals('2026-12-31T00:00:00.000Z'));
    });

    test('uses "active" as default subscriptionType when missing', () {
      final json = {
        'id': 'u1',
        'username': 'bob',
        'token': 'tok',
      };
      final user = User.fromJson(json);
      expect(user.subscriptionType, equals('active'));
    });

    test('expiresAt is null when missing from JSON', () {
      final json = {
        'id': 'u1',
        'username': 'bob',
        'token': 'tok',
        'subscriptionType': 'active',
        'expiresAt': null,
      };
      final user = User.fromJson(json);
      expect(user.expiresAt, isNull);
    });

    test('two Users with same data are equal (Freezed)', () {
      final json = {'id': 'u1', 'username': 'alice', 'token': 'tok'};
      final u1 = User.fromJson(json);
      final u2 = User.fromJson(json);
      expect(u1, equals(u2));
    });
  });

  // ── Movie model ───────────────────────────────────────────────────────────

  group('Movie.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'movie-1',
        'title': 'Inception',
        'posterUrl': 'http://img.com/poster.jpg',
        'backdropUrl': 'http://img.com/backdrop.jpg',
        'overview': 'A dream within a dream',
        'genre': 'Sci-Fi',
        'releaseYear': '2010',
        'rating': 8.8,
        'durationMinutes': 148,
      };
      final movie = Movie.fromJson(json);

      expect(movie.id, equals('movie-1'));
      expect(movie.title, equals('Inception'));
      expect(movie.genre, equals('Sci-Fi'));
      expect(movie.rating, equals(8.8));
      expect(movie.durationMinutes, equals(148));
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'm1',
        'title': 'Unknown Movie',
      };
      final movie = Movie.fromJson(json);

      expect(movie.posterUrl, isNull);
      expect(movie.genre, isNull);
      expect(movie.rating, isNull);
    });

    test('two Movies with same data are equal (Freezed)', () {
      final json = {'id': 'm1', 'title': 'Test'};
      expect(Movie.fromJson(json), equals(Movie.fromJson(json)));
    });
  });

  // ── Channel model ─────────────────────────────────────────────────────────

  group('Channel.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'ch-1',
        'name': 'CNN',
        'logoUrl': 'http://logo.png',
        'groupTitle': 'News',
        'epgId': 'cnn.us',
      };
      final channel = Channel.fromJson(json);

      expect(channel.id, equals('ch-1'));
      expect(channel.name, equals('CNN'));
      expect(channel.groupTitle, equals('News'));
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'ch-2',
        'name': 'BBC',
      };
      final channel = Channel.fromJson(json);
      expect(channel.logoUrl, isNull);
      expect(channel.groupTitle, isNull);
    });
  });

  // ── Series model ──────────────────────────────────────────────────────────

  group('Series.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'series-1',
        'title': 'Breaking Bad',
        'posterUrl': 'http://poster.jpg',
        'overview': 'A chemistry teacher...',
        'genre': 'Drama',
        'releaseYear': '2008',
        'rating': 9.5,
        'seasons': 5,
      };
      final series = Series.fromJson(json);

      expect(series.id, equals('series-1'));
      expect(series.title, equals('Breaking Bad'));
      expect(series.rating, equals(9.5));
      expect(series.seasons, equals(5));
    });

    test('handles null optional fields', () {
      final json = {
        'id': 's1',
        'title': 'Unknown Series',
      };
      final series = Series.fromJson(json);
      expect(series.overview, isNull);
      expect(series.genre, isNull);
    });
  });
}
