import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_storage.dart';
import '../models/user.dart';
import 'xtream_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final xtream = ref.watch(xtreamServiceProvider);
  return AuthService(storage, xtream);
});

class AuthService {
  final LocalStorage _storage;
  final XtreamService _xtream;

  AuthService(this._storage, this._xtream);

  Future<User> login(String serverUrl, String username, String password) async {
    // Normalize server URL
    var url = serverUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    try {
      final account = await _xtream.authenticate(url, username.trim(), password);

      // Persist credentials in Hive
      await _storage.saveXtreamUrl(url);
      await _storage.saveXtreamUsername(username.trim());
      await _storage.saveXtreamPassword(password);
      await _storage.saveUsername(account.username);
      await _storage.saveSubscriptionType(
          account.isActive ? 'active' : 'demo');
      await _storage.saveExpiresAt(account.expiresAt?.toIso8601String());

      return User(
        id: account.username,
        username: account.username,
        token: '',
        subscriptionType: account.isActive ? 'active' : 'demo',
        expiresAt: account.expiresAt?.toIso8601String(),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw Exception('Usuario o contraseña incorrectos');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
            'No se pudo conectar al servidor. Verifica la URL e intenta de nuevo.');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
