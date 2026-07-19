import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import 'home_section.dart';
import 'quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({this.onRefresh, super.key});

  final Future<void> Function()? onRefresh;

  Future<void> _open(BuildContext context, String route) {
    return context.pushAndRefresh(route, onRefresh: onRefresh);
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
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.calendar,
              title: 'Consultas',
              subtitle: 'Agendar',
              onTap: () => _open(context, AppRoutes.appointments),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.health,
              title: 'Exames',
              subtitle: 'Cadastrar',
              onTap: () => _open(context, AppRoutes.exams),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.trending_up_outlined,
              title: 'Evolução',
              subtitle: 'Abrir',
              onTap: () => _open(context, AppRoutes.progress),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.profile,
              title: 'Perfil',
              subtitle: 'Abrir',
              onTap: () => _open(context, AppRoutes.profile),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.medication_outlined,
              title: 'Medicamentos',
              subtitle: 'Abrir',
              onTap: () => _open(context, AppRoutes.medications),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Prescrições',
              subtitle: 'Histórico',
              onTap: () => _open(context, AppRoutes.prescriptions),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.folder_outlined,
              title: 'Documentos',
              subtitle: 'Central',
              onTap: () => _open(context, AppRoutes.documentCenter),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.restaurant_outlined,
              title: 'Refeições',
              subtitle: 'Cadastrar',
              onTap: () => _open(context, AppRoutes.meals),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Relatórios',
              subtitle: 'PDF',
              onTap: () => _open(context, AppRoutes.medicalReports),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.health,
              title: 'Bioimpedância',
              subtitle: 'Avaliações',
              onTap: () => _open(context, AppRoutes.bioimpedance),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.menu_book_outlined,
              title: 'Academia',
              subtitle: 'Artigos e orientações',
              onTap: () => _open(context, AppRoutes.academy),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              subtitle: 'Abrir',
              onTap: () => _open(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
