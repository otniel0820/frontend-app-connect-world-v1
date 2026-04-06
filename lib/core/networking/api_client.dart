import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/local_storage.dart';
import 'api_interceptors.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  final LocalStorage _storage;
  late final Dio _dio;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_storage));
    // LogInterceptor solo en modo debug — nunca registra cuerpos en producción
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);
}
