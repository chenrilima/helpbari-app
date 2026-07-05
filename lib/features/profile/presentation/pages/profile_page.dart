import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../providers/profile_view_model_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);

    if (state.isLoading) {
      return const HBPage(
        children: [HBLoading(message: 'Carregando perfil...')],
      );
    }

    if (state.profile == null) {
      return HBPage(
        children: [
          HBEmptyState(
            title: 'Complete seu perfil',
            description:
                'Precisamos de algumas informações para personalizar sua jornada.',
            icon: AppIcons.profile,
            actionLabel: 'Completar perfil',
            onActionPressed: () => context.go(AppRoutes.completeProfile),
          ),
        ],
      );
    }

    final profile = state.profile!;

    return HBPage(
      children: [
        HBMetricCard(
          title: 'Nome',
          value: profile.name,
          icon: AppIcons.profile,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Altura',
          value: profile.height.formatted,
          icon: AppIcons.profile,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Peso inicial',
          value: profile.initialWeight.formatted,
          icon: AppIcons.weight,
        ),
      ],
    );
  }
}
