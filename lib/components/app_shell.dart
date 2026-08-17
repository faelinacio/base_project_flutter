import 'package:flutter/material.dart';

import 'top_bar.dart';

/// Authenticated app frame (top bar + constrained, scrollable content area), equivalent to
/// `src/components/Layout.tsx`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: child,
          ),
        ),
      ),
    );
  }
}
