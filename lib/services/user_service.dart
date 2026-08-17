import 'package:dio/dio.dart';

import '../models/auth.dart';

/// Integration with the `/api/users/*` endpoints of base_project_spring_boot.
///
/// Mirrors `src/services/userService.ts`.
class UserService {
  const UserService(this._dio);

  final Dio _dio;

  Future<User> getCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/users/me');
    return User.fromJson(response.data!);
  }
}
