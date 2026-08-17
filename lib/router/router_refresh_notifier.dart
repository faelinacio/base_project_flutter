import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Bridges [authControllerProvider] state changes to go_router's `refreshListenable`, so route
/// redirects re-evaluate whenever auth state changes (login, logout, or the initial
/// silent-refresh bootstrap completing).
class GoRouterRefreshNotifier extends ChangeNotifier {
  void _notify() => notifyListeners();
}

final goRouterRefreshNotifierProvider =
    ChangeNotifierProvider<GoRouterRefreshNotifier>((ref) {
      final notifier = GoRouterRefreshNotifier();
      ref.listen(authControllerProvider, (_, _) => notifier._notify());
      return notifier;
    });
