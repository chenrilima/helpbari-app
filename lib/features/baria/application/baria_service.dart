import '../../../core/services/clock_service.dart';
import '../../../core/sync/sync.dart';
import '../../../core/health/health.dart';
import '../../home/domain/models/models.dart';
import '../../home/domain/usecases/use_cases.dart';
import '../../medical_reports/domain/entities/report_template.dart';
import '../../medical_reports/domain/models/models.dart';
import '../../medical_reports/domain/usecases/use_cases.dart';
import '../../academy/application/knowledge_use_cases.dart';
import '../../academy/domain/entities/entities.dart';
import '../domain/models/models.dart';
import 'baria_context_cache.dart';

abstract interface class BariaContextService {
  Future<BariaContext> buildContext();

  List<String> insights(BariaContext context);
}

class BariaService implements BariaContextService {
  BariaService({
    required HealthDashboardUseCases dashboard,
    required MedicalReportUseCases reports,
    required ClockService clock,
    required SyncState Function() syncState,
    required String userId,
    KnowledgeUseCases? knowledge,
    this.cacheDuration = const Duration(minutes: 5),
    BariaContextCache? cache,
  }) : _dashboard = dashboard,
       _reports = reports,
       _clock = clock,
       _syncState = syncState,
       _userId = userId,
       _knowledge = knowledge,
       _cache = cache ?? BariaContextCache();

  final HealthDashboardUseCases _dashboard;
  final MedicalReportUseCases _reports;
  final ClockService _clock;
  final SyncState Function() _syncState;
  final String _userId;
  final KnowledgeUseCases? _knowledge;
  final Duration cacheDuration;
  final BariaContextCache _cache;

  void invalidate() => _cache.invalidate();

  @override
  Future<BariaContext> buildContext() async {
    final now = _clock.now();
    final cached = _cache.read(
      userId: _userId,
      now: now,
      maxAge: cacheDuration,
    );
    if (cached != null) return cached;
    final today = _day(now);
    final values = await Future.wait<Object?>([
      _safe(() => _dashboard.load(start: today, end: today)),
      _safe(
        () => _dashboard.load(
          start: DateTime(today.year, today.month, today.day - 6),
          end: today,
        ),
      ),
      _safe(
        () => _dashboard.load(
          start: DateTime(today.year, today.month, today.day - 29),
          end: today,
        ),
      ),
      _safe(() => _reports.buildSnapshot(template: ReportTemplate.complete())),
      _knowledge == null
          ? Future<KnowledgeCatalog?>.value()
          : _safe(() => _knowledge.loadCatalog()),
    ]);
    final catalog = values[4] as KnowledgeCatalog?;
    final articles = (catalog?.articles ?? const <KnowledgeArticle>[])
        .take(3)
        .toList();
    final todayAggregate = values[0] as HealthDashboardAggregate?;
    final todayData = todayAggregate?.today;
    final profile = todayAggregate?.profile;
    final currentWeight = todayAggregate?.latestWeight?.weight.value;
    final proteinGoal = profile == null
        ? 0
        : ProteinCalculator.goalForWeightKg(
            currentWeight ?? profile.initialWeight.value,
          );
    final homeInsights = todayData == null
        ? const <String>[]
        : HealthInsightGenerator.generate(
            waterCurrentMl: todayData.waterMl ?? 0,
            waterGoalMl: todayData.waterGoalMl ?? 0,
            proteinCurrentGrams: todayData.proteinGrams ?? 0,
            proteinGoalGrams: proteinGoal,
            pendingVitamins: todayData.pendingVitamins ?? 0,
            pendingMedications: todayData.pendingMedications ?? 0,
          ).map((insight) => insight.message).toList();
    final notifications = <String>[
      if ((todayAggregate?.today.pendingVitamins ?? 0) > 0)
        'Vitaminas pendentes',
      if ((todayAggregate?.today.pendingMedications ?? 0) > 0)
        'Medicamentos pendentes',
      if (todayAggregate?.nextAppointment != null) 'Próxima consulta agendada',
    ];
    final context = BariaContext(
      userId: _userId,
      generatedAt: now,
      today: values[0] as HealthDashboardAggregate?,
      week: values[1] as HealthDashboardAggregate?,
      month: values[2] as HealthDashboardAggregate?,
      report: values[3] as MedicalReportSnapshot?,
      syncState: _syncState(),
      recommendedArticles: List.unmodifiable(articles),
      relevantNotifications: List.unmodifiable(notifications),
      homeInsights: List.unmodifiable(homeInsights),
    );
    _cache.write(context);
    return context;
  }

  @override
  List<String> insights(BariaContext context) {
    final result = <String>[];
    final today = context.todayData;
    final week = context.week;
    if (today?.waterMl != null && week != null) {
      final values = week.days
          .map((day) => day.waterMl)
          .whereType<int>()
          .toList();
      if (values.isNotEmpty) {
        final average = values.reduce((a, b) => a + b) / values.length;
        if (today!.waterMl! > average) {
          result.add(
            'Hoje seu registro de água está acima da média dos dias registrados nesta semana.',
          );
        } else if (values.length >= 2 && today.waterMl! < average) {
          result.add(
            'Hoje seu registro de água está abaixo da média dos dias registrados nesta semana.',
          );
        }
      }
    }
    if (today?.mealsCount == null) {
      result.add('Ainda não há refeição registrada hoje.');
    }
    if ((today?.pendingVitamins ?? 0) > 0 ||
        (today?.pendingMedications ?? 0) > 0) {
      result.add('Há registros de vitaminas ou medicamentos pendentes hoje.');
    }
    final lastWeight = context.report?.latestWeight?.recordedAt.value;
    if (lastWeight == null) {
      result.add('Não há peso registrado para avaliar evolução.');
    } else if (context.generatedAt.difference(lastWeight).inDays > 14) {
      result.add('Não há pesagem recente nos últimos 14 dias.');
    }
    final pending = context.pendingOfflineOperations;
    if (pending != null && pending > 0) {
      result.add(
        'Existem $pending operações com falha aguardando nova sincronização.',
      );
    }
    return result;
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
