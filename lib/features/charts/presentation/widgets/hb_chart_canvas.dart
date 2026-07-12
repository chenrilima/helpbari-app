import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';

class HBChartCanvas extends StatelessWidget {
  const HBChartCanvas({
    required this.series,
    required this.color,
    required this.animationProgress,
    super.key,
  });

  final ChartSeries series;
  final Color color;
  final double animationProgress;

  @override
  Widget build(BuildContext context) {
    final description = series.points
        .map(
          (point) =>
              '${_date(point.date)}: ${point.value.toStringAsFixed(1)} ${series.unit ?? ''}',
        )
        .join(', ');
    return Tooltip(
      message: description,
      child: Semantics(
        label: '${series.title}. $description',
        child: CustomPaint(
          painter: _ChartPainter(
            series: series,
            color: color,
            labelStyle: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            animationProgress: animationProgress,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.color,
    required this.labelStyle,
    required this.animationProgress,
  });

  final ChartSeries series;
  final Color color;
  final TextStyle? labelStyle;
  final double animationProgress;

  static const _leftPadding = 40.0;
  static const _rightPadding = 8.0;
  static const _topPadding = 12.0;
  static const _bottomPadding = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.isEmpty) return;

    final chartRect = Rect.fromLTWH(
      _leftPadding,
      _topPadding,
      size.width - _leftPadding - _rightPadding,
      size.height - _topPadding - _bottomPadding,
    );

    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final adjustedMin = minValue == maxValue ? minValue - 1 : minValue;
    final adjustedMax = minValue == maxValue ? maxValue + 1 : maxValue;
    final adjustedRange = adjustedMax - adjustedMin;

    _drawGrid(canvas, chartRect, adjustedMin, adjustedRange);

    final reference = series.referenceValue;
    if (reference != null) {
      final progress = ((reference - adjustedMin) / adjustedRange).clamp(
        0.0,
        1.0,
      );
      final y = chartRect.bottom - chartRect.height * progress;
      final paint = Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        paint,
      );
    }

    switch (series.type) {
      case ChartType.line:
        _drawLine(canvas, chartRect, points, adjustedMin, adjustedRange);
      case ChartType.bar:
        _drawBars(canvas, chartRect, points, adjustedMin, adjustedRange);
    }

    _drawAxisLabels(
      canvas,
      size,
      chartRect,
      points,
      adjustedMin,
      adjustedRange,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect, double minValue, double range) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var index = 0; index <= 3; index++) {
      final y = rect.top + rect.height * (index / 3);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<ChartPoint> points,
    double minValue,
    double range,
  ) {
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? rect.center.dx
          : rect.left + rect.width * (index / (points.length - 1));
      final valueProgress = (points[index].value - minValue) / range;
      final y = rect.bottom - rect.height * valueProgress;

      offsets.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var index = 0; index < offsets.length; index++) {
      final offset = offsets[index];
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final pathMetric = path.computeMetrics().firstOrNull;
    if (pathMetric != null) {
      canvas.drawPath(
        pathMetric.extractPath(0, pathMetric.length * animationProgress),
        linePaint,
      );
    } else {
      canvas.drawCircle(offsets.first, 4 * animationProgress, linePaint);
    }

    final dotPaint = Paint()..color = color;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4 * animationProgress, dotPaint);
    }
  }

  void _drawBars(
    Canvas canvas,
    Rect rect,
    List<ChartPoint> points,
    double minValue,
    double range,
  ) {
    final paint = Paint()..color = color;
    final slotWidth = rect.width / points.length;
    final barWidth = math.min(slotWidth * 0.58, 22.0);

    for (var index = 0; index < points.length; index++) {
      final valueProgress = (points[index].value - minValue) / range;
      final height = rect.height * valueProgress * animationProgress;
      final centerX = rect.left + slotWidth * index + slotWidth / 2;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          rect.bottom - height,
          barWidth,
          height,
        ),
        const Radius.circular(AppRadius.sm),
      );

      canvas.drawRRect(barRect, paint);
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    Size size,
    Rect rect,
    List<ChartPoint> points,
    double minValue,
    double range,
  ) {
    final maxLabel = _formatValue(minValue + range);
    final minLabel = _formatValue(minValue);

    _drawText(canvas, maxLabel, Offset(0, rect.top - 6), maxWidth: 34);
    _drawText(canvas, minLabel, Offset(0, rect.bottom - 8), maxWidth: 34);

    final first = points.first.label ?? _formatDate(points.first.date);
    final last = points.last.label ?? _formatDate(points.last.date);

    _drawText(canvas, first, Offset(rect.left, size.height - 22), maxWidth: 80);
    _drawText(
      canvas,
      last,
      Offset(rect.right - 80, size.height - 22),
      maxWidth: 80,
      align: TextAlign.right,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, offset);
  }

  String _formatValue(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.1) return rounded.toInt().toString();

    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.color != color ||
        oldDelegate.animationProgress != animationProgress;
  }
}
