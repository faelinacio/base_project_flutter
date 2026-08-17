import 'package:dio/dio.dart';

import '../models/auth.dart';

/// Integration with the `/api/auth/*` endpoints of base_project_spring_boot.
///
/// Mirrors `src/services/authService.ts`.
class AuthService {
  const AuthService(this._dio);

  final Dio _dio;

  Future<AuthTokens> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return AuthTokens.fromJson(response.data!);
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResult.fromJson(response.data!);
  }

  Future<AuthTokens> loginTotp({
    required String mfaToken,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login/totp',
      data: {'mfaToken': mfaToken, 'code': code},
    );
    return AuthTokens.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) {
    return _dio.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<void> resendVerification(String email) {
    return _dio.post<void>(
      '/api/auth/resend-verification',
      data: {'email': email},
    );
  }
}
