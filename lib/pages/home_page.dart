import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/alert_message.dart';
import '../providers/auth_provider.dart';

/// Equivalent to `src/pages/HomePage.tsx`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final extra = GoRouterState.of(context).extra;
    final justRegistered = extra is Map && extra['justRegistered'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (justRegistered) ...[
          const AlertMessage(
            status: AlertStatus.success,
            message: 'Conta criada com sucesso! Enviamos um link de verificação para o seu e-mail.',
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${user?.name ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Você está autenticado no base_project_flutter, integrado ao base_project_spring_boot.',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
