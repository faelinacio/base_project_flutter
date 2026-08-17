import 'package:dio/dio.dart';

import 'app_config.dart';
import 'token_storage.dart';
import '../models/auth.dart';

/// Thin wrapper around [Dio] that mirrors `src/lib/apiClient.ts` from base_project_react:
/// the access token lives in memory only, requests are authenticated via an interceptor, and a
/// 401 response triggers a single deduped token refresh before the original request is retried.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, String? baseUrl})
    : _tokenStorage = tokenStorage,
      dio = Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.apiBaseUrl)),
      _refreshDio = Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.apiBaseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  /// Authenticated HTTP client used by every service.
  final Dio dio;

  /// Plain client (no interceptors) used only for `/api/auth/refresh`, so a refresh attempt can
  /// never trigger the 401 retry logic on itself.
  final Dio _refreshDio;

  final TokenStorage _tokenStorage;

  String? _accessToken;
  Future<String>? _refreshFuture;

  /// Called when a refresh attempt comes back with a definite 401 (invalid/expired/reused
  /// refresh token), so the app can clear the session and send the user back to login.
  void Function()? onAuthFailure;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = error.requestOptions;
    final isAuthEndpoint = requestOptions.path.startsWith('/api/auth/');
    final alreadyRetried = requestOptions.extra['retried'] == true;

    if (error.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      handler.next(error);
      return;
    }

    try {
      final newAccessToken = await refreshAccessToken();
      requestOptions.extra['retried'] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Refreshes the access token, deduping concurrent calls so only one `/api/auth/refresh`
  /// request is ever in flight. Only a definite 401 clears the session — transient failures
  /// (network error, 5xx) are left for the caller to retry without destroying an otherwise-valid
  /// refresh token.
  Future<String> refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(
      () => _refreshFuture = null,
    );
  }

  Future<String> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw StateError('No refresh token available');
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      _accessToken = tokens.accessToken;
      await _tokenStorage.setRefreshToken(tokens.refreshToken);
      return tokens.accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _accessToken = null;
        await _tokenStorage.clear();
        onAuthFailure?.call();
      }
      rethrow;
    }
  }
}
