import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:helpbari/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:helpbari/shared/widgets/forms/hb_password_field.dart';
import 'package:helpbari/shared/widgets/forms/hb_text_field.dart';
import 'package:helpbari/shared/widgets/hb_button.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/hb_responsive_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.dashboard);
        case AuthFailure(:final message):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        default:
          break;
      }
    });

    return Scaffold(
      body: HBResponsivePage(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              HBTextField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'seuemail@exemplo.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Informe seu e-mail.';
                  }

                  if (!text.contains('@')) {
                    return 'Informe um e-mail válido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              HBPasswordField(
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Informe sua senha.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: AppSpacing.lg),
              HBButton(
                label: 'Entrar',
                isLoading: isLoading,
                onPressed: _signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
