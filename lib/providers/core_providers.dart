import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';
import '../services/totp_service.dart';
import '../services/user_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Single [ApiClient] instance for the app's lifetime, so the in-memory access token and the
/// deduped refresh-in-flight state survive across screens.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider).dio);
});

final totpServiceProvider = Provider<TotpService>((ref) {
  return TotpService(ref.watch(apiClientProvider).dio);
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(apiClientProvider).dio);
});
