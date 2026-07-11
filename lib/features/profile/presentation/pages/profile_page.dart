import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../core/formatters/app_date_formatter.dart';
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
        appBar: HBAppBar(title: 'Perfil'),
        children: [HBLoading(message: 'Carregando perfil...')],
      );
    }

    if (state.profile == null) {
      return HBPage(
        appBar: const HBAppBar(
          title: 'Perfil',
          subtitle: 'Suas informações pessoais',
        ),
        children: [
          HBEmptyState(
            title: 'Complete seu perfil',
            description:
                'Precisamos de algumas informações para personalizar sua jornada.',
            icon: AppIcons.profile,
            actionLabel: 'Completar perfil',
            onActionPressed: () {
              context.pushAndRefresh(
                AppRoutes.completeProfile,
                onRefresh: () {
                  return ref
                      .read(profileViewModelProvider.notifier)
                      .loadProfile();
                },
              );
            },
          ),
        ],
      );
    }

    final profile = state.profile!;

    return HBPage(
      appBar: HBAppBar(
        title: 'Perfil',
        subtitle: 'Suas informações bariátricas',
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            onPressed: () => context.pushAndRefresh(
              AppRoutes.completeProfile,
              onRefresh: () =>
                  ref.read(profileViewModelProvider.notifier).loadProfile(),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir perfil',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir perfil?'),
                  content: const Text(
                    'O perfil será removido deste aparelho e sincronizado quando houver conexão.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(profileViewModelProvider.notifier)
                    .deleteProfile();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
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
        const HBGap.md(),
        HBMetricCard(
          title: 'Tipo de cirurgia',
          value: profile.surgeryType.label,
          icon: AppIcons.info,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Nascimento',
          value: AppDateFormatter.short(profile.birthDate.value),
          icon: AppIcons.info,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Data da cirurgia',
          value: AppDateFormatter.short(profile.surgeryDate.value),
          icon: AppIcons.info,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Idade',
          value: '${profile.age} anos',
          icon: AppIcons.profile,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'Dias desde a cirurgia',
          value: '${profile.daysSinceSurgery} dias',
          icon: AppIcons.info,
        ),
        const HBGap.md(),
        HBMetricCard(
          title: 'IMC inicial',
          value: profile.initialBmi.formatted,
          icon: AppIcons.weight,
        ),
      ],
    );
  }
}
