import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_world/services/auth_service.dart';
import 'package:connect_world/core/networking/api_client.dart';
import 'package:connect_world/core/storage/local_storage.dart';
import 'package:connect_world/core/constants/app_constants.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late MockApiClient mockClient;
  late MockLocalStorage mockStorage;
  late AuthService authService;

  setUp(() {
    mockClient = MockApiClient();
    mockStorage = MockLocalStorage();
    authService = AuthService(mockClient, mockStorage);

    // Stub de storage que no hace nada por defecto
    when(() => mockStorage.saveAuthToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveUsername(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveSubscriptionType(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveExpiresAt(any())).thenAnswer((_) async {});
    when(() => mockStorage.clearAuth()).thenAnswer((_) async {});
    when(() => mockStorage.saveHideAdultContent(any())).thenAnswer((_) async {});
  });

  group('login', () {
    test('returns User and saves to storage on success', () async {
      final responseData = {
        'id': 'user-1',
        'username': 'testuser',
        'token': 'jwt-token-123',
        'subscriptionType': 'active',
        'expiresAt': null,
      };

      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.login),
        ),
      );

      final user = await authService.login('testuser', 'password');

      expect(user.id, equals('user-1'));
      expect(user.username, equals('testuser'));
      expect(user.token, equals('jwt-token-123'));

      verify(() => mockStorage.saveAuthToken('jwt-token-123')).called(1);
      verify(() => mockStorage.saveUsername('testuser')).called(1);
      verify(() => mockStorage.saveSubscriptionType('active')).called(1);
    });

    test('trims whitespace from username before sending', () async {
      final responseData = {
        'id': 'u1',
        'username': 'testuser',
        'token': 'tok',
        'subscriptionType': 'active',
        'expiresAt': null,
      };

      Map<String, dynamic>? sentData;
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        sentData = invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.login),
        );
      });

      await authService.login('  testuser  ', 'password');

      expect(sentData?['username'], equals('testuser'));
    });

    test('throws Exception with subscription_expired message on 403', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          data: {'message': 'subscription_expired'},
          statusCode: 403,
          requestOptions: RequestOptions(path: ApiConstants.login),
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            data: any(named: 'data'),
          )).thenThrow(dioException);

      await expectLater(
        authService.login('user', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('suscripción ha vencido'),
          ),
        ),
      );
    });

    test('throws Exception with invalid credentials message on 401', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          data: {'message': 'Credenciales inválidas'},
          statusCode: 401,
          requestOptions: RequestOptions(path: ApiConstants.login),
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            data: any(named: 'data'),
          )).thenThrow(dioException);

      await expectLater(
        authService.login('user', 'wrongpass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Credenciales inválidas'),
          ),
        ),
      );
    });

    test('rethrows DioException for other HTTP errors', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          data: {'message': 'Internal Server Error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ApiConstants.login),
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            data: any(named: 'data'),
          )).thenThrow(dioException);

      await expectLater(
        authService.login('user', 'pass'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('logout', () {
    test('clears auth storage', () async {
      await authService.logout();
      verify(() => mockStorage.clearAuth()).called(1);
    });
  });

  group('setParentalPin', () {
    test('saves new token when server returns one', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            ApiConstants.setParentalPin,
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: {'token': 'new-token-with-pin'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.setParentalPin),
        ),
      );

      await authService.setParentalPin('1234');

      verify(() => mockStorage.saveAuthToken('new-token-with-pin')).called(1);
      verify(() => mockStorage.saveHideAdultContent(true)).called(1);
    });
  });

  group('disableParentalPin', () {
    test('throws Exception with PIN incorrecto on 401', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ApiConstants.disableParentalPin),
        response: Response(
          data: {'message': 'Unauthorized'},
          statusCode: 401,
          requestOptions: RequestOptions(path: ApiConstants.disableParentalPin),
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockClient.delete<Map<String, dynamic>>(
            ApiConstants.disableParentalPin,
            data: any(named: 'data'),
          )).thenThrow(dioException);

      await expectLater(
        authService.disableParentalPin('9999'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('PIN incorrecto'),
          ),
        ),
      );
    });

    test('throws Exception when parental control not enabled (400)', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ApiConstants.disableParentalPin),
        response: Response(
          data: {'message': 'Bad request'},
          statusCode: 400,
          requestOptions: RequestOptions(path: ApiConstants.disableParentalPin),
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockClient.delete<Map<String, dynamic>>(
            ApiConstants.disableParentalPin,
            data: any(named: 'data'),
          )).thenThrow(dioException);

      await expectLater(
        authService.disableParentalPin('1234'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('control parental no está activado'),
          ),
        ),
      );
    });
  });
}
