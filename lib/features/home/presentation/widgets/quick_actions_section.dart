import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import 'home_section.dart';
import 'quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.onOpen, super.key});

  final ValueChanged<String> onOpen;

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
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.weight),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.water,
              title: 'Água',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.water),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.vitamin,
              title: 'Vitaminas',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.vitamins),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.calendar,
              title: 'Consultas',
              subtitle: 'Agendar',
              onTap: () => onOpen(AppRoutes.appointments),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.health,
              title: 'Exames',
              subtitle: 'Cadastrar',
              onTap: () => onOpen(AppRoutes.exams),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.trending_up_outlined,
              title: 'Evolução',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.progress),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.profile,
              title: 'Perfil',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.profile),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.medication_outlined,
              title: 'Medicamentos',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.medications),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Prescrições',
              subtitle: 'Histórico',
              onTap: () => onOpen(AppRoutes.prescriptions),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.folder_outlined,
              title: 'Documentos',
              subtitle: 'Central',
              onTap: () => onOpen(AppRoutes.documentCenter),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.restaurant_outlined,
              title: 'Refeições',
              subtitle: 'Cadastrar',
              onTap: () => onOpen(AppRoutes.meals),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Relatórios',
              subtitle: 'PDF',
              onTap: () => onOpen(AppRoutes.medicalReports),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: AppIcons.health,
              title: 'Bioimpedância',
              subtitle: 'Avaliações',
              onTap: () => onOpen(AppRoutes.bioimpedance),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.menu_book_outlined,
              title: 'Academia',
              subtitle: 'Artigos e orientações',
              onTap: () => onOpen(AppRoutes.academy),
            ),
            const HBGap.md(),
            QuickActionCard(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              subtitle: 'Abrir',
              onTap: () => onOpen(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
