import 'package:flutter/material.dart';

/// Blocking full-screen loading indicator, equivalent to
/// `src/components/FullScreenSpinner.tsx`. Shown while the initial session bootstrap
/// (silent token refresh + profile fetch) is in flight.
class FullScreenSpinner extends StatelessWidget {
  const FullScreenSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x99000000),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
