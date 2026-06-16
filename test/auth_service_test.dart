import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_world/services/auth_service.dart';
import 'package:connect_world/services/xtream_service.dart';
import 'package:connect_world/core/storage/local_storage.dart';

class MockXtreamService extends Mock implements XtreamService {}

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late MockXtreamService mockXtream;
  late MockLocalStorage mockStorage;
  late AuthService authService;

  setUp(() {
    mockXtream = MockXtreamService();
    mockStorage = MockLocalStorage();
    authService = AuthService(mockStorage, mockXtream);

    // Stub de storage que no hace nada por defecto
    when(() => mockStorage.saveXtreamUrl(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveXtreamUsername(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveXtreamPassword(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveUsername(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveSubscriptionType(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveExpiresAt(any())).thenAnswer((_) async {});
    when(() => mockStorage.clearAll()).thenAnswer((_) async {});
  });

  group('login', () {
    test('returns User and saves credentials to storage on success', () async {
      when(() => mockXtream.authenticate('http://example.com', 'testuser', 'password'))
          .thenAnswer((_) async => const XtreamAccount(
                username: 'testuser',
                status: 'Active',
              ));

      final user = await authService.login(
          'http://example.com', 'testuser', 'password');

      expect(user.id, equals('testuser'));
      expect(user.username, equals('testuser'));
      expect(user.subscriptionType, equals('active'));

      verify(() => mockStorage.saveXtreamUrl('http://example.com')).called(1);
      verify(() => mockStorage.saveXtreamUsername('testuser')).called(1);
      verify(() => mockStorage.saveXtreamPassword('password')).called(1);
      verify(() => mockStorage.saveUsername('testuser')).called(1);
      verify(() => mockStorage.saveSubscriptionType('active')).called(1);
    });

    test('strips trailing slash from server URL before authenticating', () async {
      when(() => mockXtream.authenticate('http://example.com', 'testuser', 'password'))
          .thenAnswer((_) async => const XtreamAccount(
                username: 'testuser',
                status: 'Active',
              ));

      await authService.login('http://example.com/', 'testuser', 'password');

      verify(() => mockXtream.authenticate('http://example.com', 'testuser', 'password'))
          .called(1);
      verify(() => mockStorage.saveXtreamUrl('http://example.com')).called(1);
    });

    test('trims whitespace from username and server URL before authenticating', () async {
      when(() => mockXtream.authenticate('http://example.com', 'testuser', 'password'))
          .thenAnswer((_) async => const XtreamAccount(
                username: 'testuser',
                status: 'Active',
              ));

      await authService.login('  http://example.com  ', '  testuser  ', 'password');

      verify(() => mockXtream.authenticate('http://example.com', 'testuser', 'password'))
          .called(1);
    });

    test('saves demo subscription type when account is not active', () async {
      when(() => mockXtream.authenticate(any(), any(), any())).thenAnswer(
        (_) async => const XtreamAccount(username: 'testuser', status: 'Expired'),
      );

      final user = await authService.login(
          'http://example.com', 'testuser', 'password');

      expect(user.subscriptionType, equals('demo'));
      verify(() => mockStorage.saveSubscriptionType('demo')).called(1);
    });

    test('throws Exception with credentials message on 401', () async {
      when(() => mockXtream.authenticate(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/player_api.php'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/player_api.php'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        authService.login('http://example.com', 'user', 'wrongpass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Usuario o contraseña incorrectos'),
          ),
        ),
      );
    });

    test('throws Exception with credentials message on 403', () async {
      when(() => mockXtream.authenticate(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/player_api.php'),
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/player_api.php'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        authService.login('http://example.com', 'user', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Usuario o contraseña incorrectos'),
          ),
        ),
      );
    });

    test('throws Exception with connection message on connection error', () async {
      when(() => mockXtream.authenticate(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/player_api.php'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        authService.login('http://bad-url.invalid', 'user', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No se pudo conectar'),
          ),
        ),
      );
    });

    test('rethrows DioException for other errors', () async {
      when(() => mockXtream.authenticate(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/player_api.php'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/player_api.php'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        authService.login('http://example.com', 'user', 'pass'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('logout', () {
    test('clears all local storage', () async {
      await authService.logout();
      verify(() => mockStorage.clearAll()).called(1);
    });
  });
}
