import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Header navigation bar, equivalent to `src/components/TopBar.tsx`: brand link, primary nav
/// and a user menu (profile summary, settings shortcut, logout).
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final navButtonStyle = TextButton.styleFrom(foregroundColor: onPrimary);

    return AppBar(
      title: const Text('base_project_flutter'),
      actions: [
        TextButton(
          style: navButtonStyle,
          onPressed: () => context.go('/'),
          child: const Text('Início'),
        ),
        TextButton(
          style: navButtonStyle,
          onPressed: () => context.go('/settings'),
          child: const Text('Configurações'),
        ),
        if (user != null)
          PopupMenuButton<String>(
            tooltip: 'Menu do usuário',
            icon: CircleAvatar(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              child: Text(
                (user.name.isNotEmpty ? user.name : user.email)[0]
                    .toUpperCase(),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.go('/settings');
                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
