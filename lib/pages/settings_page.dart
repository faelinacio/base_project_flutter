import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/alert_message.dart';
import '../core/api_error.dart';
import '../models/auth.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';

enum _TotpMode { idle, enroll, disable }

/// Equivalent to `src/pages/SettingsPage.tsx`: profile summary plus TOTP 2FA enrollment/disable.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  _TotpMode _mode = _TotpMode.idle;
  TotpSetup? _setupData;
  final _codeController = TextEditingController();

  String? _errorMessage;
  String? _successMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _resetTotpForm() {
    setState(() {
      _mode = _TotpMode.idle;
      _setupData = null;
      _codeController.clear();
    });
  }

  Future<void> _startEnroll() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSubmitting = true;
    });
    try {
      final data = await ref.read(totpServiceProvider).setup();
      setState(() {
        _setupData = data;
        _mode = _TotpMode.enroll;
      });
    } catch (error) {
      if (extractStatusCode(error) == 409) {
        await ref.read(authControllerProvider.notifier).refreshUser();
        setState(
          () => _errorMessage =
              'A autenticação de dois fatores já está ativada nesta conta.',
        );
      } else {
        setState(() {
          _errorMessage = extractErrorMessage(
            error,
            fallback: 'Não foi possível iniciar a configuração do 2FA.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmEnable() async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(totpServiceProvider).enable(_codeController.text.trim());
      await ref.read(authControllerProvider.notifier).refreshUser();
      setState(
        () => _successMessage =
            'Autenticação de dois fatores ativada com sucesso.',
      );
      _resetTotpForm();
    } catch (error) {
      setState(() {
        _errorMessage = extractErrorMessage(
          error,
          fallback: 'Código inválido. Tente novamente.',
        );
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDisable() async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(totpServiceProvider).disable(_codeController.text.trim());
      await ref.read(authControllerProvider.notifier).refreshUser();
      setState(
        () => _successMessage = 'Autenticação de dois fatores desativada.',
      );
      _resetTotpForm();
    } catch (error) {
      setState(() {
        _errorMessage = extractErrorMessage(
          error,
          fallback: 'Código inválido. Tente novamente.',
        );
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Configurações',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perfil', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ProfileField(label: 'Nome', value: user.name),
                const SizedBox(height: 8),
                _ProfileField(label: 'E-mail', value: user.email),
                const SizedBox(height: 8),
                Text(
                  'Perfil de acesso',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(user.role.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Autenticação de dois fatores (2FA)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (user.totpEnabled)
                      const Chip(
                        label: Text(
                          'Ativada',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Proteja sua conta exigindo um código do seu aplicativo autenticador a cada login.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  AlertMessage(
                    status: AlertStatus.error,
                    message: _errorMessage!,
                    onClose: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  AlertMessage(
                    status: AlertStatus.success,
                    message: _successMessage!,
                    onClose: () => setState(() => _successMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_mode == _TotpMode.idle && !user.totpEnabled)
                  FilledButton(
                    onPressed: _isSubmitting ? null : _startEnroll,
                    child: _isSubmitting
                        ? _submittingIndicator()
                        : const Text('Ativar 2FA'),
                  ),
                if (_mode == _TotpMode.idle && user.totpEnabled)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _mode = _TotpMode.disable),
                    child: const Text('Desativar 2FA'),
                  ),
                if (_mode == _TotpMode.enroll && _setupData != null)
                  _buildEnrollForm(),
                if (_mode == _TotpMode.disable) _buildDisableForm(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _submittingIndicator() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }

  Widget _buildEnrollForm() {
    final setupData = _setupData!;
    final qrBytes = _decodeQrImage(setupData.qrCodeImage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text(
          '1. Escaneie o QR code abaixo com seu aplicativo autenticador (Google Authenticator, '
          'Authy, etc.).',
        ),
        const SizedBox(height: 12),
        if (qrBytes != null) Image.memory(qrBytes, width: 180, height: 180),
        const SizedBox(height: 12),
        const Text('Ou digite o código manualmente:'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            setupData.secret,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 12),
        const Text('2. Informe o código de 6 dígitos gerado para confirmar:'),
        const SizedBox(height: 8),
        SizedBox(width: 220, child: _codeField()),
        const Divider(height: 32),
        Row(
          children: [
            FilledButton(
              onPressed:
                  (_isSubmitting || _codeController.text.trim().length != 6)
                  ? null
                  : _confirmEnable,
              child: _isSubmitting
                  ? _submittingIndicator()
                  : const Text('Confirmar e ativar'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isSubmitting ? null : _resetTotpForm,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisableForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Informe um código atual do seu aplicativo autenticador para desativar o 2FA.',
        ),
        const SizedBox(height: 12),
        SizedBox(width: 220, child: _codeField()),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed:
                  (_isSubmitting || _codeController.text.trim().length != 6)
                  ? null
                  : _confirmDisable,
              child: _isSubmitting
                  ? _submittingIndicator()
                  : const Text('Confirmar desativação'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isSubmitting ? null : _resetTotpForm,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeField() {
    return TextField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: const InputDecoration(counterText: ''),
      onChanged: (_) => setState(() {}),
    );
  }
}

Uint8List? _decodeQrImage(String dataUri) {
  final commaIndex = dataUri.indexOf(',');
  if (!dataUri.startsWith('data:') || commaIndex == -1) return null;
  try {
    return base64Decode(dataUri.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        Text(value),
      ],
    );
  }
}
