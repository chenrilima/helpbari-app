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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .resetPasswordForEmail(email: _emailController.text.trim());
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .updatePassword(password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState is AuthLoading;
    final isPasswordRecovery = authState is AuthPasswordRecoveryReady;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      switch (next) {
        case AuthPasswordRecoverySent():
          HBSnackBar.success(
            context,
            message: 'Enviamos as instruções de recuperação para seu e-mail.',
          );
          context.go(AppRoutes.login);
        case AuthPasswordRecoveryReady():
          HBSnackBar.info(
            context,
            message: 'Informe uma nova senha para concluir a recuperação.',
          );
        case AuthPasswordUpdated():
          HBSnackBar.success(context, message: 'Senha atualizada com sucesso.');
          context.go(AppRoutes.home);
        case AuthFailure(:final message):
          HBSnackBar.error(context, message: message);
        default:
          break;
      }
    });

    return HBLoadingOverlay(
      isLoading: isLoading,
      message: isPasswordRecovery
          ? 'Atualizando senha...'
          : 'Enviando instruções...',
      child: HBPage(
        header: _ResetPasswordHeader(isPasswordRecovery: isPasswordRecovery),
        children: [
          HBCard(
            child: Form(
              key: _formKey,
              child: isPasswordRecovery
                  ? _NewPasswordForm(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isLoading: isLoading,
                      onSubmit: _updatePassword,
                    )
                  : _RecoveryEmailForm(
                      emailController: _emailController,
                      isLoading: isLoading,
                      onSubmit: _resetPassword,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader({required this.isPasswordRecovery});

  final bool isPasswordRecovery;

  @override
  Widget build(BuildContext context) {
    final title = isPasswordRecovery ? 'Nova senha' : 'Recuperar senha';
    final description = isPasswordRecovery
        ? 'Crie uma nova senha para voltar a acessar sua conta.'
        : 'Informe o e-mail da sua conta para receber as instruções de recuperação.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(title, style: Theme.of(context).textTheme.headlineLarge),
        const HBGap.sm(),
        HBText(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RecoveryEmailForm extends StatelessWidget {
  const _RecoveryEmailForm({
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HBTextField(
          controller: emailController,
          label: 'E-mail',
          hint: 'seuemail@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: AppValidators.email,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const HBGap.lg(),
        HBButton(
          label: 'Recuperar senha',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const HBGap.md(),
        TextButton(
          onPressed: isLoading ? null : () => context.go(AppRoutes.login),
          child: const HBText('Voltar para login'),
        ),
      ],
    );
  }
}

class _NewPasswordForm extends StatelessWidget {
  const _NewPasswordForm({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HBPasswordField(
          controller: passwordController,
          textInputAction: TextInputAction.next,
          validator: AppValidators.newPassword,
        ),
        const HBGap.md(),
        HBPasswordField(
          controller: confirmPasswordController,
          label: 'Confirmar senha',
          textInputAction: TextInputAction.done,
          validator: (value) {
            final validation = AppValidators.newPassword(value);
            if (validation != null) return validation;

            if (value != passwordController.text) {
              return 'As senhas não conferem.';
            }

            return null;
          },
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const HBGap.lg(),
        HBButton(
          label: 'Salvar nova senha',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
