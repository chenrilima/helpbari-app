import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../water/presentation/widgets/water_progress_card.dart';
import 'home_section.dart';

class WaterOverviewSection extends StatelessWidget {
  const WaterOverviewSection({
    required this.totalTodayInMl,
    required this.goalMl,
    this.subtitle = 'Sua hidratação de hoje.',
    this.onRefresh,
    super.key,
  });

  final int totalTodayInMl;
  final int goalMl;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _openWater(BuildContext context) async {
    await context.pushAndRefresh(AppRoutes.water, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Água',
      subtitle: subtitle,
      child: Semantics(
        button: true,
        label: 'Abrir água',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _openWater(context),
          child: WaterProgressCard(currentMl: totalTodayInMl, goalMl: goalMl),
        ),
      ),
    );
  }
}
