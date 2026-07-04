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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const _LoginHeader(),
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
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.signUp),
                      child: const Text('Ainda não tenho conta'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: null,
                      child: const Text('Entrar com Google em breve'),
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Bem-vindo ao HelpBari',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Acesse sua conta para acompanhar sua evolução, rotina e saúde em um só lugar.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
