import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/alert_message.dart';
import '../core/api_error.dart';
import '../providers/auth_provider.dart';

final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Equivalent to `src/pages/RegisterPage.tsx`.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;
  Map<String, String> _serverFieldErrors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/', extra: const {'justRegistered': true});
    } catch (error) {
      final fieldErrors = extractFieldErrors(error);
      setState(() {
        _serverFieldErrors = {
          for (final entry in fieldErrors.entries)
            if (const ['name', 'email', 'password'].contains(entry.key))
              entry.key: entry.value,
        };
        _errorMessage = extractErrorMessage(
          error,
          fallback: 'Não foi possível criar a conta.',
        );
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearServerFieldError(String field) {
    if (_serverFieldErrors.containsKey(field)) {
      setState(
        () => _serverFieldErrors = {..._serverFieldErrors}..remove(field),
      );
    }
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Criar conta',
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        autofillHints: const [AutofillHints.name],
                        onChanged: (_) => _clearServerFieldError('name'),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Informe o nome';
                          }
                          if (v.length > 255) {
                            return 'O nome deve ter no máximo 255 caracteres';
                          }
                          return _serverFieldErrors['name'];
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) => _clearServerFieldError('email'),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Informe o e-mail';
                          }
                          if (!_emailRegExp.hasMatch(v) || v.length > 255) {
                            return 'E-mail inválido';
                          }
                          return _serverFieldErrors['email'];
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => _clearServerFieldError('password'),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.length < 8) {
                            return 'A senha deve ter no mínimo 8 caracteres';
                          }
                          if (utf8.encode(v).length > 72) {
                            return 'A senha deve ter no máximo 72 bytes';
                          }
                          return _serverFieldErrors['password'];
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                        ),
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme a senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Criar conta'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Já tem uma conta?'),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Entrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
