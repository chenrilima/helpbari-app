import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../viewmodels/auth_providers.dart';
import '../states/auth_state.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (authState) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
        case AuthUnauthenticated():
        case AuthPasswordRecoverySent():
        case AuthFailure():
          context.go(AppRoutes.login);
        case AuthInitial():
        case AuthLoading():
          break;
      }
    });

    return HBPage(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HBText(
              'HelpBari',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const HBGap.md(),
            HBText(
              'Preparando sua jornada...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const HBGap.xl(),
            const HBLoading(),
          ],
        ),
      ],
    );
  }
}
