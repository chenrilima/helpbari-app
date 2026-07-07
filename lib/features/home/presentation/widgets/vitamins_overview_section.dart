import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../home/presentation/widgets/home_section.dart';

class VitaminsOverviewSection extends StatelessWidget {
  const VitaminsOverviewSection({
    required this.pendingCount,
    this.onRefresh,
    super.key,
  });

  final int pendingCount;
  final Future<void> Function()? onRefresh;

  Future<void> _openVitamins(BuildContext context) async {
    await context.push(AppRoutes.vitamins);
    await onRefresh?.call();
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
      subtitle: 'Acompanhe seus suplementos.',
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
