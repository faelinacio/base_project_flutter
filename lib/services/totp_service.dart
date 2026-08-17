import 'package:dio/dio.dart';

import '../models/auth.dart';

/// Integration with the `/api/users/me/totp/*` endpoints of base_project_spring_boot.
///
/// Mirrors `src/services/totpService.ts`.
class TotpService {
  const TotpService(this._dio);

  final Dio _dio;

  Future<TotpSetup> setup() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/users/me/totp/setup',
    );
    return TotpSetup.fromJson(response.data!);
  }

  Future<void> enable(String code) {
    return _dio.post<void>('/api/users/me/totp/enable', data: {'code': code});
  }

  Future<void> disable(String code) {
    return _dio.post<void>('/api/users/me/totp/disable', data: {'code': code});
  }
}
