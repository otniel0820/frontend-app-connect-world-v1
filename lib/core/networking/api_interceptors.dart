import 'package:dio/dio.dart';

import '../storage/local_storage.dart';

class AuthInterceptor extends Interceptor {
  final LocalStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;

    if (status == 401) {
      _storage.clearAuth();
      // Router redirect to login handled by go_router redirect
    }

    if (status == 403) {
      final msg = err.response?.data?['message'] as String? ?? '';
      if (msg == 'subscription_expired') {
        _storage.markSubscriptionExpired();
        _storage.clearAuth();
        // Router redirect to /subscription-expired handled by go_router redirect
      }
    }

    handler.next(err);
  }
}
