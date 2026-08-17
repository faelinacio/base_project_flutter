import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the refresh token in the platform keychain/keystore (never the access token,
/// which is kept in memory only — see [ApiClient]).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'auth.refreshToken';

  final FlutterSecureStorage _storage;

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _refreshTokenKey);
}
