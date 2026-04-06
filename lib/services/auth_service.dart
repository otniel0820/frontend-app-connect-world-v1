import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/networking/api_client.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/local_storage.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(localStorageProvider);
  return AuthService(client, storage);
});

class AuthService {
  final ApiClient _client;
  final LocalStorage _storage;

  AuthService(this._client, this._storage);

  Future<User> login(String username, String password) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {
          'username': username.trim(),
          'password': password,
        },
      );
      final user = User.fromJson(response.data!);
      await _storage.saveAuthToken(user.token);
      await _storage.saveUsername(user.username);
      await _storage.saveSubscriptionType(user.subscriptionType);
      await _storage.saveExpiresAt(user.expiresAt);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final msg = e.response?.data?['message'] as String? ?? '';
        if (msg == 'subscription_expired') {
          throw Exception('Tu suscripción ha vencido. Contacta a tu proveedor.');
        }
      }
      if (e.response?.statusCode == 401) {
        final msg = e.response?.data?['message'] as String? ?? '';
        throw Exception(msg.isNotEmpty ? msg : 'Credenciales inválidas');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAuth();
  }

  Future<void> setParentalPin(String pin) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.setParentalPin,
      data: {'pin': pin},
    );
    final token = response.data?['token'] as String?;
    if (token != null) await _storage.saveAuthToken(token);
    await _storage.saveHideAdultContent(true);
  }

  Future<void> disableParentalPin(String pin) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        ApiConstants.disableParentalPin,
        data: {'pin': pin},
      );
      final token = response.data?['token'] as String?;
      if (token != null) await _storage.saveAuthToken(token);
      await _storage.saveHideAdultContent(false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('PIN incorrecto');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('El control parental no está activado');
      }
      rethrow;
    }
  }
}
