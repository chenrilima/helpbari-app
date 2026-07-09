import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../home/presentation/widgets/home_section.dart';

class VitaminsOverviewSection extends StatelessWidget {
  const VitaminsOverviewSection({
    required this.pendingCount,
    this.subtitle = 'Acompanhe seus suplementos.',
    this.onRefresh,
    super.key,
  });

  final int pendingCount;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _openVitamins(BuildContext context) async {
    await context.pushAndRefresh(AppRoutes.vitamins, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final value = pendingCount == 0
        ? 'Tudo em dia'
        : '$pendingCount pendente${pendingCount > 1 ? 's' : ''}';

    final description = pendingCount == 0
        ? 'Nenhuma vitamina pendente hoje.'
        : 'Toque para atualizar sua rotina.';

    return HomeSection(
      title: 'Vitaminas',
      subtitle: subtitle,
      child: HBMetricCard(
        title: 'Rotina de vitaminas',
        value: value,
        description: description,
        icon: AppIcons.vitamin,
        onTap: () => _openVitamins(context),
      ),
    );
  }
}
