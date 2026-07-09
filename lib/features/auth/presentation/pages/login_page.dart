import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../states/auth_state.dart';
import '../viewmodels/auth_providers.dart';

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

  Future<void> _signInWithGoogle() async {
    await ref.read(authViewModelProvider.notifier).signInWithGoogle();
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

    return HBPage(
      header: const _LoginHeader(),
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
                  validator: AppValidators.password,
                  onFieldSubmitted: (_) => _signIn(),
                ),
                const HBGap.lg(),
                HBButton(
                  label: 'Entrar',
                  isLoading: isLoading,
                  onPressed: _signIn,
                ),
                const HBGap.md(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signUp),
                  child: const Text('Ainda não tenho conta'),
                ),
                const HBGap.sm(),
                TextButton(
                  onPressed: isLoading ? null : _signInWithGoogle,
                  child: const Text('Entrar com Google'),
                ),
              ],
            ),
          ),
        ),
      ],
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
          child: const HBIcon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const HBGap.lg(),
        HBText(
          'Bem-vindo ao HelpBari',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const HBGap.sm(),
        HBText(
          'Acesse sua conta para acompanhar sua evolução, rotina e saúde em um só lugar.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
