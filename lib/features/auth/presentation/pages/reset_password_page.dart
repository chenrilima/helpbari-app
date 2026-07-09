import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../states/auth_state.dart';
import '../viewmodels/auth_providers.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .resetPasswordForEmail(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      switch (next) {
        case AuthPasswordRecoverySent():
          HBSnackBar.success(
            context,
            message: 'Enviamos as instruções de recuperação para seu e-mail.',
          );
          context.go(AppRoutes.login);
        case AuthFailure(:final message):
          HBSnackBar.error(context, message: message);
        default:
          break;
      }
    });

    return HBLoadingOverlay(
      isLoading: isLoading,
      message: 'Enviando instruções...',
      child: HBPage(
        header: const _ResetPasswordHeader(),
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
                    textInputAction: TextInputAction.done,
                    validator: AppValidators.email,
                    onFieldSubmitted: (_) => _resetPassword(),
                  ),
                  const HBGap.lg(),
                  HBButton(
                    label: 'Recuperar senha',
                    isLoading: isLoading,
                    onPressed: _resetPassword,
                  ),
                  const HBGap.md(),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const HBText('Voltar para login'),
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

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          'Recuperar senha',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const HBGap.sm(),
        HBText(
          'Informe o e-mail da sua conta para receber as instruções de recuperação.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
