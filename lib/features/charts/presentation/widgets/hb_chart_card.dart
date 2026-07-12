import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import 'hb_chart_canvas.dart';

class HBChartCard extends StatelessWidget {
  const HBChartCard({
    required this.title,
    required this.period,
    required this.onPeriodChanged,
    required this.series,
    super.key,
    this.subtitle,
    this.isLoading = false,
    this.errorMessage,
    this.color = AppColors.primary,
    this.height = 220,
    this.emptyIcon = Icons.bar_chart_outlined,
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final ChartSeries? series;
  final bool isLoading;
  final String? errorMessage;
  final Color color;
  final double height;
  final IconData emptyIcon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: title, subtitle: subtitle),
          const HBGap.md(),
          _PeriodSelector(value: period, onChanged: onPeriodChanged),
          const HBGap.lg(),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: _content(context),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        key: const ValueKey('chart-loading'),
        height: height,
        child: const HBLoading(message: 'Carregando gráfico...'),
      );
    }

    final error = errorMessage;

    if (error != null) {
      return ConstrainedBox(
        key: const ValueKey('chart-error'),
        constraints: BoxConstraints(minHeight: height),
        child: HBEmptyState(
          title: 'Não foi possível carregar',
          description: error,
          icon: Icons.error_outline,
          actionLabel: onRetry == null ? null : 'Tentar novamente',
          onActionPressed: onRetry,
        ),
      );
    }

    final currentSeries = series;

    if (currentSeries == null || !currentSeries.hasData) {
      return SizedBox(
        key: const ValueKey('chart-empty'),
        height: height,
        child: HBEmptyState(
          title: currentSeries?.emptyTitle ?? 'Sem dados suficientes',
          description:
              currentSeries?.emptyDescription ??
              'Registre novas informações para visualizar este gráfico.',
          icon: emptyIcon,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('chart-${currentSeries.title}-${period.name}'),
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return SizedBox(
          height: height,
          child: HBChartCanvas(
            series: currentSeries,
            color: color,
            animationProgress: progress,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const HBGap.xs(),
          HBText(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});

  final ChartPeriod value;
  final ValueChanged<ChartPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartPeriod.values.map((period) {
          final selected = period == value;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(period.label),
              selected: selected,
              onSelected: (_) => onChanged(period),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
