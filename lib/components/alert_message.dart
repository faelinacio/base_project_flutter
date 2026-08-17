import 'package:flutter/material.dart';

enum AlertStatus { error, success }

/// Inline status banner, equivalent to `src/components/AlertMessage.tsx`.
class AlertMessage extends StatelessWidget {
  const AlertMessage({
    super.key,
    required this.status,
    required this.message,
    this.onClose,
  });

  final AlertStatus status;
  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      AlertStatus.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.error_outline,
      ),
      AlertStatus.success => (
        Colors.green.shade100,
        Colors.green.shade900,
        Icons.check_circle_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: foreground, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
