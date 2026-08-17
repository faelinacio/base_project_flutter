import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/app_shell.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/not_found_page.dart';
import '../pages/register_page.dart';
import '../pages/settings_page.dart';
import '../providers/auth_provider.dart';
import 'router_refresh_notifier.dart';

/// Route guards, equivalent to `RequireAuth.tsx` + `PublicOnlyRoute.tsx`: unauthenticated users
/// are sent to `/login` (carrying a `redirect` query param back to the page they wanted),
/// authenticated users are kept out of `/login` and `/register`. No redirect decision is made
/// while the session is still bootstrapping ([AuthState.isLoading]); [FullScreenSpinner] covers
/// the screen for that brief window instead (see `app.dart`).
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: ref.watch(goRouterRefreshNotifierProvider),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!auth.isAuthenticated && !isAuthRoute) {
        final redirectTarget = Uri.encodeQueryComponent(state.uri.toString());
        return '/login?redirect=$redirectTarget';
      }

      if (auth.isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});
