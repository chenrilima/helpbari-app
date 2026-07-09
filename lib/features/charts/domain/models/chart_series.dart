import 'chart_point.dart';
import 'chart_type.dart';

class ChartSeries {
  const ChartSeries({
    required this.title,
    required this.points,
    required this.type,
    this.unit,
    this.emptyTitle = 'Sem dados suficientes',
    this.emptyDescription =
        'Registre novas informações para visualizar este gráfico.',
  });

  final String title;
  final List<ChartPoint> points;
  final ChartType type;
  final String? unit;
  final String emptyTitle;
  final String emptyDescription;

  bool get hasData => points.isNotEmpty;
}
