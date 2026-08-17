import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/alert_message.dart';
import '../core/api_error.dart';
import '../providers/auth_provider.dart';

final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Equivalent to `src/pages/LoginPage.tsx`: email/password credentials, followed by a TOTP
/// challenge step when the account has 2FA enabled.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _credentialsFormKey = GlobalKey<FormState>();
  final _totpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  String? _mfaToken;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_credentialsFormKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    try {
      final outcome = await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (outcome.mfaRequired) {
        setState(() => _mfaToken = outcome.mfaToken);
      } else {
        _navigateAfterLogin();
      }
    } catch (error) {
      setState(() {
        _errorMessage = extractErrorMessage(
          error,
          fallback: 'Não foi possível entrar. Verifique suas credenciais.',
        );
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitTotp() async {
    if (_mfaToken == null || !_totpFormKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginTotp(_mfaToken!, _codeController.text.trim());
      if (!mounted) return;
      _navigateAfterLogin();
    } catch (error) {
      setState(() {
        _errorMessage = extractErrorMessage(
          error,
          fallback: 'Código inválido ou expirado.',
        );
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateAfterLogin() {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    context.go(redirect != null && redirect.isNotEmpty ? redirect : '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _mfaToken == null
                          ? 'Entrar'
                          : 'Verificação em duas etapas',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      AlertMessage(
                        status: AlertStatus.error,
                        message: _errorMessage!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_mfaToken == null)
                      _buildCredentialsForm()
                    else
                      _buildTotpForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsForm() {
    return Form(
      key: _credentialsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Informe o e-mail';
              if (!_emailRegExp.hasMatch(v)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Informe a senha' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitCredentials,
            child: _isSubmitting
                ? _submittingIndicator()
                : const Text('Entrar'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Não tem uma conta?'),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Cadastre-se'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotpForm() {
    return Form(
      key: _totpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informe o código de 6 dígitos do seu aplicativo autenticador.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código de verificação',
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (value) {
              final v = value?.trim() ?? '';
              return v.length == 6 ? null : 'O código deve ter 6 dígitos';
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitTotp,
            child: _isSubmitting
                ? _submittingIndicator()
                : const Text('Verificar'),
          ),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() {
                    _mfaToken = null;
                    _errorMessage = null;
                    _codeController.clear();
                  }),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _submittingIndicator() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
