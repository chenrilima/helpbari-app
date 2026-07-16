import '../../../../app/router/app_routes.dart';
import '../models/models.dart';

class BariaInsightEngine {
  const BariaInsightEngine();

  List<BariaInsight> generate(BariaContext context) {
    final day = context.todayData;
    final result = <BariaInsight>[];
    final createdAt = context.generatedAt;
    final water = day?.waterMl;
    final waterGoal = day?.waterGoalMl;
    if (water != null &&
        waterGoal != null &&
        waterGoal > 0 &&
        water < waterGoal) {
      final ratio = water / waterGoal;
      result.add(
        _insight(
          id: 'water:${_date(createdAt)}',
          title: 'Hidratação abaixo da meta',
          description: 'Você registrou $water ml de $waterGoal ml hoje.',
          priority: ratio < .5
              ? BariaInsightPriority.high
              : BariaInsightPriority.medium,
          category: BariaInsightCategory.water,
          route: AppRoutes.water,
          source: 'Resumo de hidratação',
          date: createdAt,
        ),
      );
    }
    final vitamins = day?.pendingVitamins ?? 0;
    if (vitamins > 0) {
      result.add(
        _insight(
          id: 'vitamins:${_date(createdAt)}',
          title: 'Vitamina pendente',
          description: vitamins == 1
              ? 'Há 1 vitamina pendente hoje.'
              : 'Há $vitamins vitaminas pendentes hoje.',
          priority: BariaInsightPriority.high,
          category: BariaInsightCategory.vitamins,
          route: AppRoutes.vitamins,
          source: 'Rotina de vitaminas',
          date: createdAt,
        ),
      );
    }
    final medications = day?.pendingMedications ?? 0;
    if (medications > 0) {
      result.add(
        _insight(
          id: 'medications:${_date(createdAt)}',
          title: 'Medicamento pendente',
          description: medications == 1
              ? 'Há 1 medicamento pendente hoje.'
              : 'Há $medications medicamentos pendentes hoje.',
          priority: BariaInsightPriority.critical,
          category: BariaInsightCategory.medications,
          route: AppRoutes.medications,
          source: 'Rotina de medicamentos',
          date: createdAt,
        ),
      );
    }
    final appointment = context.today?.nextAppointment;
    if (appointment != null) {
      final days =
          DateTime(
                appointment.date.value.year,
                appointment.date.value.month,
                appointment.date.value.day,
              )
              .difference(
                DateTime(createdAt.year, createdAt.month, createdAt.day),
              )
              .inDays;
      if (days >= 0 && days <= 1) {
        result.add(
          _insight(
            id: 'appointment:${appointment.id}',
            title: days == 0 ? 'Consulta hoje' : 'Consulta amanhã',
            description: '${appointment.title} • ${appointment.formattedDate}',
            priority: days == 0
                ? BariaInsightPriority.critical
                : BariaInsightPriority.high,
            category: BariaInsightCategory.appointments,
            route: AppRoutes.appointments,
            source: 'Agenda de consultas',
            date: createdAt,
          ),
        );
      }
    }
    final weights =
        context.week?.days
            .map((day) => day.weightKg)
            .whereType<double>()
            .toList() ??
        const <double>[];
    if (weights.length >= 2 && weights.first != weights.last) {
      final reduced = weights.last < weights.first;
      result.add(
        _insight(
          id: 'weight:${_date(createdAt)}',
          title: 'Evolução de peso registrada',
          description: reduced
              ? 'Seus registros indicam redução de peso no período.'
              : 'Seus registros indicam aumento de peso no período.',
          priority: BariaInsightPriority.medium,
          category: BariaInsightCategory.weight,
          route: AppRoutes.weight,
          source: 'Evolução de peso',
          date: createdAt,
        ),
      );
    }
    if (context.recommendedArticles.isNotEmpty) {
      final article = context.recommendedArticles.first;
      result.add(
        BariaInsight(
          id: 'academy:${article.id}',
          title: 'Conteúdo recomendado',
          message: article.title,
          createdAt: createdAt,
          priority: BariaInsightPriority.low,
          category: BariaInsightCategory.academy,
          action: BariaInsightAction(
            type: BariaInsightActionType.article,
            label: 'Ler artigo',
            destination: AppRoutes.academyArticlePath(article.id),
          ),
          source: 'Academia Bariátrica',
        ),
      );
    }
    result.sort((a, b) {
      final priority = a.priority.index.compareTo(b.priority.index);
      return priority != 0 ? priority : a.id.compareTo(b.id);
    });
    return List.unmodifiable(result);
  }

  BariaInsight _insight({
    required String id,
    required String title,
    required String description,
    required BariaInsightPriority priority,
    required BariaInsightCategory category,
    required String route,
    required String source,
    required DateTime date,
  }) => BariaInsight(
    id: id,
    title: title,
    message: description,
    createdAt: date,
    priority: priority,
    category: category,
    action: BariaInsightAction(
      type: BariaInsightActionType.route,
      label: 'Abrir',
      destination: route,
    ),
    source: source,
  );
  String _date(DateTime value) => '${value.year}-${value.month}-${value.day}';
}
