import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../meals/presentation/widgets/meal_summary_card.dart';
import 'home_section.dart';

class MealOverviewSection extends StatelessWidget {
  const MealOverviewSection({
    required this.todayCount,
    required this.totalProteinToday,
    this.subtitle = 'Acompanhe sua alimentação de hoje.',
    this.onRefresh,
    super.key,
  });

  final int todayCount;
  final int totalProteinToday;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _openMeals(BuildContext context) async {
    await context.pushAndRefresh(AppRoutes.meals, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Refeições',
      subtitle: subtitle,
      child: Semantics(
        button: true,
        label: 'Abrir refeições',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _openMeals(context),
          child: MealSummaryCard(
            todayCount: todayCount,
            totalProteinToday: totalProteinToday,
          ),
        ),
      ),
    );
  }
}
