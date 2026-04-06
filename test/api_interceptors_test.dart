import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_world/core/networking/api_interceptors.dart';
import 'package:connect_world/core/storage/local_storage.dart';

class MockLocalStorage extends Mock implements LocalStorage {}

class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late MockLocalStorage mockStorage;
  late AuthInterceptor interceptor;

  setUp(() {
    mockStorage = MockLocalStorage();
    interceptor = AuthInterceptor(mockStorage);
  });

  // ── onRequest ─────────────────────────────────────────────────────────────

  group('AuthInterceptor.onRequest', () {
    test('adds Authorization header when token exists', () {
      when(() => mockStorage.getAuthToken()).thenReturn('my-jwt-token');

      final options = RequestOptions(path: '/test');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer my-jwt-token'));
      verify(() => handler.next(options)).called(1);
    });

    test('does NOT add Authorization header when token is null', () {
      when(() => mockStorage.getAuthToken()).thenReturn(null);

      final options = RequestOptions(path: '/test');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });
  });

  // ── onError ───────────────────────────────────────────────────────────────

  group('AuthInterceptor.onError', () {
    test('clears auth on 401 response', () {
      when(() => mockStorage.clearAuth()).thenAnswer((_) async {});

      final err = DioException(
        requestOptions: RequestOptions(path: '/protected'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/protected'),
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      verify(() => mockStorage.clearAuth()).called(1);
      verify(() => handler.next(err)).called(1);
    });

    test('clears auth and marks expired on 403 with subscription_expired message', () {
      when(() => mockStorage.markSubscriptionExpired()).thenAnswer((_) async {});
      when(() => mockStorage.clearAuth()).thenAnswer((_) async {});

      final err = DioException(
        requestOptions: RequestOptions(path: '/catalog'),
        response: Response(
          statusCode: 403,
          data: {'message': 'subscription_expired'},
          requestOptions: RequestOptions(path: '/catalog'),
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      verify(() => mockStorage.markSubscriptionExpired()).called(1);
      verify(() => mockStorage.clearAuth()).called(1);
      verify(() => handler.next(err)).called(1);
    });

    test('does NOT clear auth on 403 with different message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/catalog'),
        response: Response(
          statusCode: 403,
          data: {'message': 'Se requieren permisos de administrador'},
          requestOptions: RequestOptions(path: '/catalog'),
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      verifyNever(() => mockStorage.clearAuth());
      verify(() => handler.next(err)).called(1);
    });

    test('passes through non-401/403 errors untouched', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/catalog'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/catalog'),
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      verifyNever(() => mockStorage.clearAuth());
      verify(() => handler.next(err)).called(1);
    });

    test('handles null response gracefully', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/catalog'),
        type: DioExceptionType.connectionError,
      );
      final handler = MockErrorInterceptorHandler();

      // No debe lanzar excepción
      expect(() => interceptor.onError(err, handler), returnsNormally);
      verify(() => handler.next(err)).called(1);
    });
  });
}
