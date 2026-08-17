import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/full_screen_spinner.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// Root widget, equivalent to `App.tsx`. Wires up the Material theme and the go_router
/// `RouterConfig`, and overlays [FullScreenSpinner] while the session bootstrap
/// ([AuthState.isLoading]) is in flight — matching `RequireAuth`/`PublicOnlyRoute`'s spinner in
/// the React app.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isLoading = ref.watch(
      authControllerProvider.select((state) => state.isLoading),
    );

    return MaterialApp.router(
      title: 'base_project_flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [?child, if (isLoading) const FullScreenSpinner()],
        );
      },
    );
  }
}
