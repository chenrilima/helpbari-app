import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import 'home_section.dart';
import 'quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

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
              onTap: () {
                context.push(AppRoutes.weight);
              },
            ),

            const HBGap.md(),

            QuickActionCard(
              icon: AppIcons.water,
              title: 'Água',
              subtitle: 'Em breve',
              onTap: () {},
            ),

            const HBGap.md(),

            QuickActionCard(
              icon: AppIcons.vitamin,
              title: 'Vitaminas',
              subtitle: 'Em breve',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
