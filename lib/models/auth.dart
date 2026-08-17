/// Auth-related models shared across services and providers.
///
/// Mirrors the shape of the base_project_spring_boot DTOs consumed by the app
/// (`AuthResponse`, `LoginResponse`, `UserResponse`, `TotpSetupResponse`, `ErrorResponse`).
library;

/// Access/refresh token pair returned by `/api/auth/register`, `/api/auth/login/totp` and
/// `/api/auth/refresh` (`AuthResponse` on the backend).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
}

/// Result of `POST /api/auth/login` (`LoginResponse` on the backend). When [mfaRequired] is
/// true, [mfaToken] must be submitted together with a TOTP code to `/api/auth/login/totp` to
/// obtain [tokens]; otherwise [tokens] is already populated.
class LoginResult {
  const LoginResult({required this.mfaRequired, this.mfaToken, this.tokens});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as Map<String, dynamic>?;
    return LoginResult(
      mfaRequired: json['mfaRequired'] as bool,
      mfaToken: json['mfaToken'] as String?,
      tokens: tokensJson == null ? null : AuthTokens.fromJson(tokensJson),
    );
  }

  final bool mfaRequired;
  final String? mfaToken;
  final AuthTokens? tokens;
}

enum Role {
  user,
  admin;

  static Role fromJson(String value) {
    return switch (value) {
      'ADMIN' => Role.admin,
      _ => Role.user,
    };
  }

  String get label => switch (this) {
    Role.admin => 'ADMIN',
    Role.user => 'USER',
  };
}

/// The authenticated user's profile (`UserResponse` on the backend).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.totpEnabled,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: Role.fromJson(json['role'] as String),
      totpEnabled: json['totpEnabled'] as bool,
    );
  }

  final String id;
  final String name;
  final String email;
  final Role role;
  final bool totpEnabled;
}

/// Response from `POST /api/users/me/totp/setup` (`TotpSetupResponse` on the backend).
class TotpSetup {
  const TotpSetup({required this.secret, required this.qrCodeImage});

  factory TotpSetup.fromJson(Map<String, dynamic> json) {
    return TotpSetup(
      secret: json['secret'] as String,
      qrCodeImage: json['qrCodeImage'] as String,
    );
  }

  final String secret;

  /// Ready-to-render `data:image/png;base64,...` URI.
  final String qrCodeImage;
}

/// Error body returned by the backend's `GlobalExceptionHandler` (`ErrorResponse`).
class ApiErrorResponse {
  const ApiErrorResponse({
    required this.status,
    required this.error,
    required this.message,
    required this.path,
    this.fieldErrors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final rawFieldErrors = json['fieldErrors'] as Map<String, dynamic>?;
    return ApiErrorResponse(
      status: json['status'] as int,
      error: json['error'] as String,
      message: json['message'] as String,
      path: json['path'] as String,
      fieldErrors: rawFieldErrors?.map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
  }

  final int status;
  final String error;
  final String message;
  final String path;
  final Map<String, String>? fieldErrors;
}
