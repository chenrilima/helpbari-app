import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../states/auth_state.dart';
import '../viewmodels/auth_providers.dart';

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
          context.go(AppRoutes.home);
        case AuthFailure(:final message):
          HBSnackBar.error(context, message: message);
        default:
          break;
      }
    });

    return HBLoadingOverlay(
      isLoading: isLoading,
      message: 'Criando conta...',
      child: HBPage(
        header: const _SignUpHeader(),
        children: [
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
                    validator: AppValidators.email,
                  ),
                  const HBGap.md(),
                  HBPasswordField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    validator: AppValidators.newPassword,
                    onFieldSubmitted: (_) => _signUp(),
                  ),
                  const HBGap.lg(),
                  HBButton(
                    label: 'Criar conta',
                    isLoading: isLoading,
                    onPressed: _signUp,
                  ),
                  const HBGap.md(),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const HBText('Já tenho uma conta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText('Criar conta', style: Theme.of(context).textTheme.headlineLarge),
        const HBGap.sm(),
        HBText(
          'Comece sua jornada no HelpBari com uma conta segura.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
