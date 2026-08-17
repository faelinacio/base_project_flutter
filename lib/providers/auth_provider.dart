import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'core_providers.dart';

/// Mirrors `AuthContextValue` from `src/hooks/auth-context.ts`.
class AuthState {
  const AuthState({this.user, this.isLoading = false});

  final User? user;
  final bool isLoading;

  bool get isAuthenticated => user != null;
}

/// Mirrors `LoginOutcome` from `src/hooks/auth-context.ts`.
class LoginOutcome {
  const LoginOutcome({required this.mfaRequired, this.mfaToken});

  final bool mfaRequired;
  final String? mfaToken;
}

/// Session state and auth operations, equivalent to `AuthProvider.tsx` + `useAuth.ts`.
///
/// On construction it mirrors `AuthProvider`'s bootstrap effect: if a refresh token is already
/// stored, it silently exchanges it for a fresh access token and loads the current user before
/// [AuthState.isLoading] flips to false. A definite 401 during that (or any later) refresh clears
/// the session via [ApiClient.onAuthFailure].
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthService authService,
    required UserService userService,
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _authService = authService,
       _userService = userService,
       _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       super(const AuthState(isLoading: true)) {
    _apiClient.onAuthFailure = () => unawaited(_clearSession());
    unawaited(_bootstrap());
  }

  final AuthService _authService;
  final UserService _userService;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> _bootstrap() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthState(isLoading: false);
      return;
    }

    try {
      await _apiClient.refreshAccessToken();
      final user = await _userService.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (_) {
      // Transient failure (network error, 5xx): leave the refresh token in place so the user
      // can retry on the next app launch, matching AuthProvider's bootstrap effect.
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> _applyTokens(AuthTokens tokens) async {
    _apiClient.setAccessToken(tokens.accessToken);
    await _tokenStorage.setRefreshToken(tokens.refreshToken);
    final user = await _userService.getCurrentUser();
    state = AuthState(user: user, isLoading: false);
  }

  Future<LoginOutcome> login(String email, String password) async {
    final result = await _authService.login(email: email, password: password);
    if (result.mfaRequired) {
      return LoginOutcome(mfaRequired: true, mfaToken: result.mfaToken);
    }
    if (result.tokens != null) {
      await _applyTokens(result.tokens!);
    }
    return const LoginOutcome(mfaRequired: false);
  }

  Future<void> loginTotp(String mfaToken, String code) async {
    final tokens = await _authService.loginTotp(mfaToken: mfaToken, code: code);
    await _applyTokens(tokens);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final tokens = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
    await _applyTokens(tokens);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _authService.logout(refreshToken);
      } catch (_) {
        // Best-effort: the session is cleared locally regardless.
      }
    }
    await _clearSession();
  }

  Future<void> refreshUser() async {
    state = AuthState(
      user: await _userService.getCurrentUser(),
      isLoading: state.isLoading,
    );
  }

  Future<void> _clearSession() async {
    _apiClient.setAccessToken(null);
    await _tokenStorage.clear();
    state = const AuthState(isLoading: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      authService: ref.watch(authServiceProvider),
      userService: ref.watch(userServiceProvider),
      apiClient: ref.watch(apiClientProvider),
      tokenStorage: ref.watch(tokenStorageProvider),
    );
  },
);
