import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import 'hb_chart_card.dart';

class HBAsyncChartCard extends StatelessWidget {
  const HBAsyncChartCard({
    required this.title,
    required this.period,
    required this.onPeriodChanged,
    required this.series,
    super.key,
    this.subtitle,
    this.color = AppColors.primary,
    this.height = 220,
    this.emptyIcon = Icons.bar_chart_outlined,
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final AsyncValue<ChartSeries> series;
  final Color color;
  final double height;
  final IconData emptyIcon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return series.when(
      data: (data) => HBChartCard(
        title: title,
        subtitle: subtitle,
        period: period,
        onPeriodChanged: onPeriodChanged,
        series: data,
        color: color,
        height: height,
        emptyIcon: emptyIcon,
        onRetry: onRetry,
      ),
      error: (error, stackTrace) => HBChartCard(
        title: title,
        subtitle: subtitle,
        period: period,
        onPeriodChanged: onPeriodChanged,
        series: null,
        errorMessage: error.toString(),
        color: color,
        height: height,
        emptyIcon: emptyIcon,
        onRetry: onRetry,
      ),
      loading: () => HBChartCard(
        title: title,
        subtitle: subtitle,
        period: period,
        onPeriodChanged: onPeriodChanged,
        series: null,
        isLoading: true,
        color: color,
        height: height,
        emptyIcon: emptyIcon,
      ),
    );
  }
}
