import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import 'home_section.dart';
import 'quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({this.onRefresh, super.key});

  final Future<void> Function()? onRefresh;

  Future<void> _open(BuildContext context, String route) async {
    await context.push(route);
    await onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Ações rápidas',
      subtitle: 'Acesse rapidamente as principais funcionalidades.',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            QuickActionCard(
              icon: AppIcons.weight,
              title: 'Peso',
              subtitle: 'Registrar',
              onTap: () => _open(context, AppRoutes.weight),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.water,
              title: 'Água',
              subtitle: 'Registrar',
              onTap: () => _open(context, AppRoutes.water),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.vitamin,
              title: 'Vitaminas',
              subtitle: 'Abrir',
              onTap: () => _open(context, AppRoutes.vitamins),
            ),
          ],
        ),
      ),
    );
  }
}
