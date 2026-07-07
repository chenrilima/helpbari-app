import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../home/presentation/widgets/home_section.dart';
import '../../../water/presentation/widgets/water_progress_card.dart';

class WaterOverviewSection extends StatelessWidget {
  const WaterOverviewSection({
    required this.totalTodayInMl,
    this.onRefresh,
    super.key,
  });

  final int totalTodayInMl;
  final Future<void> Function()? onRefresh;

  Future<void> _openWater(BuildContext context) async {
    await context.push(AppRoutes.water);
    await onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Água',
      subtitle: 'Sua hidratação de hoje.',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _openWater(context),
        child: WaterProgressCard(currentMl: totalTodayInMl),
      ),
    );
  }
}
