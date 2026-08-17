import 'package:base_project_flutter/core/token_storage.dart';
import 'package:base_project_flutter/pages/home_page.dart';
import 'package:base_project_flutter/providers/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Never touches the platform secure-storage channel, so [AuthController]'s bootstrap settles
/// to "no session" without needing a mocked plugin.
class _NullTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> setRefreshToken(String token) async {}
}

void main() {
  testWidgets('HomePage shows the integration message', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_NullTokenStorage()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('base_project_spring_boot'), findsOneWidget);
  });
}
