import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/forms/hb_password_field.dart';
import '../../../../shared/widgets/forms/hb_text_field.dart';
import '../../../../shared/widgets/button/hb_button.dart';
import '../../../../shared/widgets/card/hb_card.dart';
import '../../../../shared/widgets/layout/hb_responsive_page.dart';
import '../viewmodels/auth_providers.dart';
import '../states/auth_state.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .signUpWithEmailAndPassword(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Criar conta',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Comece sua jornada no HelpBari com uma conta segura.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            HBCard(
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

                        if (text.isEmpty) return 'Informe seu e-mail.';
                        if (!text.contains('@'))
                          return 'Informe um e-mail válido.';

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HBPasswordField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final text = value ?? '';

                        if (text.isEmpty) return 'Informe sua senha.';
                        if (text.length < 6)
                          return 'A senha deve ter pelo menos 6 caracteres.';

                        return null;
                      },
                      onFieldSubmitted: (_) => _signUp(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HBButton(
                      label: 'Criar conta',
                      isLoading: isLoading,
                      onPressed: _signUp,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Já tenho uma conta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
