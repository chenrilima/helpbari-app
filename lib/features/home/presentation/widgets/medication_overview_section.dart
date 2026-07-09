import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../medications/presentation/widgets/medication_summary_card.dart';
import 'home_section.dart';

class MedicationOverviewSection extends StatelessWidget {
  const MedicationOverviewSection({
    required this.pendingCount,
    this.subtitle = 'Acompanhe sua rotina de remédios.',
    this.onRefresh,
    super.key,
  });

  final int pendingCount;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _openMedications(BuildContext context) async {
    await context.pushAndRefresh(AppRoutes.medications, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Medicamentos',
      subtitle: subtitle,
      child: Semantics(
        button: true,
        label: 'Abrir medicamentos',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _openMedications(context),
          child: MedicationSummaryCard(pendingCount: pendingCount),
        ),
      ),
    );
  }
}
