import '../../../core/health/calculators/protein_calculator.dart';
import '../../../core/services/clock_service.dart';
import '../../../core/sync/sync_state.dart';
import '../../appointments/domain/entities/entities.dart';
import '../../appointments/domain/usecases/use_cases.dart';
import '../../medical_prescriptions/domain/usecases/use_cases.dart';
import '../../settings/domain/entities/setting.dart';
import '../../weight/domain/usecases/use_cases.dart';
import '../../smart_routines/domain/enums/routine_enums.dart';
import '../../smart_routines/domain/services/treatment_query_models.dart';
import '../domain/models/models.dart';
import '../domain/services/deterministic_insight_engine.dart';
import '../domain/usecases/health_dashboard_use_cases.dart';

class HomeIntelligenceQueryFacade {
  const HomeIntelligenceQueryFacade({
    required this.userId,
    required this.dashboard,
    required this.treatment,
    required this.appointments,
    required this.prescriptions,
    required this.weight,
    required this.clock,
    required this.syncState,
    required this.timeZone,
    this.insightEngine = const DeterministicInsightEngine(),
  });

  final String userId;
  final HealthDashboardUseCases dashboard;
  final Future<TreatmentAdherenceQueryService> Function() treatment;
  final AppointmentUseCases appointments;
  final MedicalPrescriptionUseCases prescriptions;
  final WeightUseCases weight;
  final ClockService clock;
  final SyncState Function() syncState;
  final String Function() timeZone;
  final DeterministicInsightEngine insightEngine;

  Future<ProgressTrendReadModel> weightTrend(int days) async {
    if (userId.trim().isEmpty) {
      throw StateError('Authenticated user is required for Home Intelligence.');
    }
    final now = clock.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = DateTime(now.year, now.month, now.day - days + 1);
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    final records = await weight.getByPeriod(start, endExclusive);
    final points = records
        .map(
          (record) => ProgressTrendPointReadModel(
            date: record.recordedAt.value,
            value: record.weight.value,
          ),
        )
        .toList(growable: false);
    final rate = days <= 0 ? null : points.length / days;
    final coverage = CoverageReadModel(
      state: points.length >= 2
          ? CoverageState.sufficient
          : CoverageState.insufficient,
      rate: rate,
      reason: points.length >= 2 ? null : 'Amostra insuficiente para tendência',
      formulaVersion: 'weight-trend-v1',
    );
    return ProgressTrendReadModel(
      start: start,
      end: end,
      points: points,
      coverage: coverage,
      status: HomeSectionStatus(
        state: points.isEmpty ? HomeSectionState.empty : HomeSectionState.ready,
        freshness: FreshnessReadModel(generatedAt: now),
        coverage: coverage,
      ),
    );
  }

  Future<TodayDashboardReadModel> today() async {
    if (userId.trim().isEmpty) {
      throw StateError('Authenticated user is required for Home Intelligence.');
    }
    final now = clock.now();
    final date = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 7);
    final values = await Future.wait<Object?>([
      _safe(() => dashboard.load(start: date, end: date)),
      _safe(() async => (await treatment()).days(date, end)),
      _safe(() => appointments.getByPeriod(date, end)),
      _safe(prescriptions.countRequiringReview),
    ]);
    final health = values[0] as HealthDashboardAggregate?;
    final treatmentDays =
        values[1] as Map<String, TodayTreatmentReadModel>? ?? const {};
    final appointmentValues = values[2] as List<Appointment>? ?? const [];
    final prescriptionsAwaitingReview = values[3] as int? ?? 0;
    final sync = syncState();
    final pendingSync =
        sync.phase == SyncPhase.partialFailure ||
        sync.phase == SyncPhase.failure;
    final freshness = FreshnessReadModel(
      generatedAt: now,
      sourceUpdatedAt: sync.lastSyncAt,
      isStale:
          sync.lastSyncAt != null &&
          now.difference(sync.lastSyncAt!).inHours >= 24,
      reason: sync.lastSyncAt == null ? 'Ainda não sincronizado' : null,
    );
    final agenda = composeAgenda(
      now: now,
      start: date,
      end: end,
      treatmentDays: treatmentDays,
      appointments: appointmentValues,
      freshness: freshness,
      pendingSync: pendingSync,
    );
    final todayTreatment = treatmentDays[_dateKey(date)];
    final treatmentSummary = composeTreatmentSummary(
      todayTreatment,
      freshness,
      pendingSync,
    );
    final todayHealth = health?.days.firstOrNull;
    final profile = health?.profile;
    final currentWeight = health?.latestWeight?.weight.value;
    final proteinGoal = profile == null
        ? null
        : ProteinCalculator.goalForWeightKg(
            currentWeight ?? profile.initialWeight.value,
          );
    final progress = composeProgress(
      health: health,
      treatment: treatmentSummary,
      proteinGoal: proteinGoal,
      freshness: freshness,
      pendingSync: pendingSync,
    );
    final nextActions = composeNextActions(
      now: now,
      agenda: agenda,
      prescriptionsAwaitingReview: prescriptionsAwaitingReview,
      freshness: freshness,
      pendingSync: pendingSync,
    );
    final quickActions = composeQuickActions(
      agenda: agenda,
      freshness: freshness,
      pendingSync: pendingSync,
    );
    final insights = composeInsights(
      now: now,
      health: health,
      treatment: treatmentSummary,
      agenda: agenda,
      prescriptionsAwaitingReview: prescriptionsAwaitingReview,
      freshness: freshness,
      pendingSync: pendingSync,
    );
    final hasAnySource = values.any((value) => value != null);
    final status = HomeSectionStatus(
      state: !hasAnySource
          ? HomeSectionState.error
          : freshness.isStale
          ? HomeSectionState.stale
          : HomeSectionState.ready,
      freshness: freshness,
      hasPendingSync: pendingSync,
      message: !hasAnySource
          ? 'Não foi possível carregar os dados locais.'
          : null,
    );
    return TodayDashboardReadModel(
      userId: userId,
      clinicalDate: date,
      timeZone: timeZone(),
      userName: profile?.name,
      nextActions: nextActions,
      agenda: agenda,
      treatment: treatmentSummary,
      progress: progress,
      quickStats: composeQuickStats(
        health,
        treatmentSummary,
        freshness,
        pendingSync,
      ),
      quickActions: quickActions,
      insights: insights,
      healthScore: todayHealth?.healthScore,
      status: status,
    );
  }

  AgendaReadModel composeAgenda({
    required DateTime now,
    required DateTime start,
    required DateTime end,
    required Map<String, TodayTreatmentReadModel> treatmentDays,
    required List<Appointment> appointments,
    required FreshnessReadModel freshness,
    required bool pendingSync,
  }) {
    final items = <AgendaItemReadModel>[];
    for (final day in treatmentDays.values) {
      for (final occurrence in day.occurrences) {
        items.add(
          AgendaItemReadModel(
            id: 'treatment:${occurrence.id}',
            sourceId: occurrence.id,
            type: AgendaItemType.treatment,
            title: occurrence.title,
            effectiveAt: occurrence.scheduledFor,
            originalAt: occurrence.originalScheduledFor,
            timeZone: timeZone(),
            state: _agendaState(occurrence.operationalState),
            source: 'smartRoutines',
            deepLink: '/home',
            allowedActions:
                occurrence.operationalState == TreatmentOccurrenceState.open ||
                    occurrence.operationalState == TreatmentOccurrenceState.due
                ? const {HomeActionKind.treatmentCommand}
                : const {},
            accessibilityLabel:
                '${occurrence.title}, ${occurrence.operationalState.name}',
          ),
        );
      }
    }
    for (final appointment in appointments) {
      final instant = appointment.date.value;
      if (instant.isBefore(start) || !instant.isBefore(end)) continue;
      items.add(
        AgendaItemReadModel(
          id: 'appointment:${appointment.id}',
          sourceId: appointment.id,
          type: AgendaItemType.appointment,
          title: appointment.title,
          effectiveAt: instant,
          timeZone: timeZone(),
          state: appointment.isCanceled
              ? AgendaItemState.canceled
              : appointment.isCompleted
              ? AgendaItemState.resolved
              : _appointmentState(instant, now),
          source: 'appointments',
          deepLink: '/appointments',
          accessibilityLabel:
              '${appointment.title}, ${appointment.formattedDate}',
        ),
      );
    }
    items.sort(_agendaCompare);
    return AgendaReadModel(
      start: start,
      end: end,
      items: items,
      status: HomeSectionStatus(
        state: items.isEmpty ? HomeSectionState.empty : HomeSectionState.ready,
        freshness: freshness,
        hasPendingSync: pendingSync,
      ),
    );
  }

  TreatmentSummaryReadModel composeTreatmentSummary(
    TodayTreatmentReadModel? model,
    FreshnessReadModel freshness,
    bool pendingSync,
  ) {
    if (model == null) {
      const coverage = CoverageReadModel(
        state: CoverageState.unavailable,
        reason: 'Dados de tratamento indisponíveis',
        formulaVersion: 'treatment-adherence-v1',
      );
      return TreatmentSummaryReadModel(
        due: 0,
        open: 0,
        resolved: 0,
        missed: 0,
        requiresReview: 0,
        adherence: null,
        onTimeAdherence: null,
        coverage: coverage,
        origin: TreatmentDataOrigin.smartRoutines,
        formulaVersion: 'treatment-adherence-v1',
        adherenceByCategory: const {},
        status: HomeSectionStatus(
          state: HomeSectionState.unavailable,
          freshness: freshness,
          coverage: coverage,
          hasPendingSync: pendingSync,
        ),
      );
    }
    final occurrences = model.occurrences;
    final summary = model.adherence;
    final coverage = _coverage(summary);
    return TreatmentSummaryReadModel(
      due: occurrences
          .where((o) => o.operationalState == TreatmentOccurrenceState.due)
          .length,
      open: occurrences
          .where((o) => o.operationalState == TreatmentOccurrenceState.open)
          .length,
      resolved: occurrences
          .where((o) => o.operationalState == TreatmentOccurrenceState.resolved)
          .length,
      missed: occurrences
          .where((o) => o.operationalState == TreatmentOccurrenceState.missed)
          .length,
      requiresReview: occurrences
          .where(
            (o) =>
                o.operationalState == TreatmentOccurrenceState.requiresReview,
          )
          .length,
      adherence: summary.adherence,
      onTimeAdherence: summary.onTimeAdherence,
      coverage: coverage,
      origin: summary.origin,
      formulaVersion: summary.formulaVersion,
      adherenceByCategory: {
        for (final entry in summary.byCategory.entries)
          entry.key: entry.value.adherence,
      },
      status: HomeSectionStatus(
        state: occurrences.isEmpty
            ? HomeSectionState.empty
            : HomeSectionState.ready,
        freshness: freshness,
        coverage: coverage,
        hasPendingSync: pendingSync,
      ),
    );
  }

  ProgressSummaryReadModel composeProgress({
    required HealthDashboardAggregate? health,
    required TreatmentSummaryReadModel treatment,
    required int? proteinGoal,
    required FreshnessReadModel freshness,
    required bool pendingSync,
  }) {
    final day = health?.days.firstOrNull;
    final profile = health?.profile;
    final latestWeight = health?.latestWeight?.weight.value;
    final targetWeight = profile?.targetWeight?.value;
    final initialWeight = profile?.initialWeight.value;
    final weightProgress =
        initialWeight == null ||
            latestWeight == null ||
            targetWeight == null ||
            initialWeight == targetWeight
        ? null
        : ((initialWeight - latestWeight) / (initialWeight - targetWeight))
              .clamp(0.0, 1.0);
    final routineDenominator =
        treatment.resolved + treatment.missed + treatment.open;
    return ProgressSummaryReadModel(
      routine: _metric(
        id: 'routine',
        label: 'Rotina diária',
        value: treatment.resolved.toDouble(),
        target: routineDenominator == 0 ? null : routineDenominator.toDouble(),
        coverage: treatment.coverage,
      ),
      water: _metric(
        id: 'water',
        label: 'Água',
        value: day?.waterMl?.toDouble(),
        target: day?.waterGoalMl?.toDouble(),
        unit: 'ml',
        coverage: day?.waterMl == null
            ? _unavailable('Sem registro de água')
            : _sufficient(),
      ),
      protein: _metric(
        id: 'protein',
        label: 'Proteína',
        value: day?.proteinGrams?.toDouble(),
        target: proteinGoal?.toDouble(),
        unit: 'g',
        coverage: day?.proteinGrams == null || proteinGoal == null
            ? _unavailable('Meta ou registro de proteína indisponível')
            : _sufficient(),
      ),
      weight: _metric(
        id: 'weight',
        label: 'Peso',
        value: latestWeight,
        target: targetWeight,
        unit: 'kg',
        forcedProgress: weightProgress,
        coverage: latestWeight == null
            ? _unavailable('Sem pesagem')
            : _sufficient(),
      ),
      healthScore: _metric(
        id: 'health-score',
        label: 'Health Score',
        value: day?.healthScore.hasData == true
            ? day!.healthScore.score.toDouble()
            : null,
        target: day?.healthScore.hasData == true ? 100 : null,
        coverage: day?.healthScore.hasData == true
            ? _sufficient(formulaVersion: 'health-score-v2')
            : _unavailable('Componentes insuficientes'),
      ),
      streak: ProgressMetricReadModel(
        id: 'streak',
        label: 'Sequência',
        state: ProgressMetricState.awaitingData,
        coverage: const CoverageReadModel(
          state: CoverageState.insufficient,
          reason: 'O dia ainda está em andamento',
          formulaVersion: 'home-streak-v1',
        ),
      ),
      status: HomeSectionStatus(
        state: health == null
            ? HomeSectionState.unavailable
            : HomeSectionState.ready,
        freshness: freshness,
        hasPendingSync: pendingSync,
      ),
    );
  }

  ProgressMetricReadModel _metric({
    required String id,
    required String label,
    required double? value,
    required double? target,
    required CoverageReadModel coverage,
    String? unit,
    double? forcedProgress,
  }) {
    final progress =
        forcedProgress ??
        (value == null || target == null || target <= 0
            ? null
            : (value / target).clamp(0.0, 1.0));
    return ProgressMetricReadModel(
      id: id,
      label: label,
      state: coverage.hasSufficientData && value != null
          ? ProgressMetricState.available
          : ProgressMetricState.awaitingData,
      value: value,
      target: target,
      unit: unit,
      progress: progress,
      coverage: coverage,
      accessibilityLabel: value == null
          ? '$label, dados insuficientes'
          : '$label, ${value.toStringAsFixed(0)}${unit == null ? '' : ' $unit'}',
    );
  }

  NextActionsReadModel composeNextActions({
    required DateTime now,
    required AgendaReadModel agenda,
    required int prescriptionsAwaitingReview,
    required FreshnessReadModel freshness,
    required bool pendingSync,
  }) {
    final actions = <NextActionReadModel>[];
    for (final item in agenda.items.where((item) => item.isActionable)) {
      actions.add(
        NextActionReadModel(
          id: 'next:${item.id}',
          title: item.title,
          reason: _actionReason(item.state),
          priority: _actionPriority(item.state),
          dueAt: item.effectiveAt,
          source: item.source,
          deepLink: item.deepLink,
          command: item.allowedActions.contains(HomeActionKind.treatmentCommand)
              ? HomeActionKind.treatmentCommand
              : HomeActionKind.route,
          validUntil: item.effectiveAt.add(const Duration(days: 1)),
          accessibilityLabel: '${item.title}. ${_actionReason(item.state)}',
        ),
      );
    }
    if (prescriptionsAwaitingReview > 0) {
      actions.add(
        NextActionReadModel(
          id: 'next:prescription-review',
          title: 'Revisar prescrição',
          reason: 'Há uma prescrição aguardando sua revisão.',
          priority: HomeActionPriority.medium,
          source: 'prescriptions',
          deepLink: '/prescriptions',
          command: HomeActionKind.route,
          validUntil: now.add(const Duration(days: 1)),
          accessibilityLabel: 'Revisar prescrição pendente',
        ),
      );
    }
    actions.sort((a, b) {
      final priority = a.priority.index.compareTo(b.priority.index);
      if (priority != 0) return priority;
      return (a.dueAt ?? a.validUntil).compareTo(b.dueAt ?? b.validUntil);
    });
    return NextActionsReadModel(
      actions: actions,
      status: HomeSectionStatus(
        state: actions.isEmpty
            ? HomeSectionState.empty
            : HomeSectionState.ready,
        freshness: freshness,
        hasPendingSync: pendingSync,
      ),
    );
  }

  QuickActionsReadModel composeQuickActions({
    required AgendaReadModel agenda,
    AppSettings settings = const AppSettings(id: 'home-default'),
    required FreshnessReadModel freshness,
    required bool pendingSync,
  }) {
    final actions = <QuickActionReadModel>[];
    if (settings.waterTrackingEnabled) {
      actions.add(
        const QuickActionReadModel(
          id: 'quick:water',
          title: 'Registrar água',
          kind: HomeActionKind.route,
          deepLink: '/water',
          accessibilityLabel: 'Abrir acompanhamento para registrar água',
        ),
      );
    }
    if (settings.mealTrackingEnabled) {
      actions.add(
        const QuickActionReadModel(
          id: 'quick:meal',
          title: 'Registrar refeição',
          kind: HomeActionKind.route,
          deepLink: '/mealsRegister',
          accessibilityLabel: 'Registrar refeição',
        ),
      );
    }
    if (settings.treatmentTrackingEnabled) {
      actions.add(
        const QuickActionReadModel(
          id: 'quick:treatment',
          title: 'Ver tratamento',
          kind: HomeActionKind.route,
          deepLink: '/treatment',
          accessibilityLabel: 'Abrir tratamento',
        ),
      );
    }
    actions.add(
      const QuickActionReadModel(
        id: 'quick:agenda',
        title: 'Adicionar consulta',
        kind: HomeActionKind.route,
        deepLink: '/register-appointment',
        accessibilityLabel: 'Adicionar consulta',
      ),
    );
    return QuickActionsReadModel(
      fixed: actions.take(4),
      dynamic: const [],
      status: HomeSectionStatus(
        state: HomeSectionState.ready,
        freshness: freshness,
        hasPendingSync: pendingSync,
      ),
    );
  }

  QuickStatsReadModel composeQuickStats(
    HealthDashboardAggregate? health,
    TreatmentSummaryReadModel treatment,
    FreshnessReadModel freshness,
    bool pendingSync,
  ) {
    final day = health?.days.firstOrNull;
    return QuickStatsReadModel(
      waterLabel: day?.waterMl == null ? 'Sem dados' : '${day!.waterMl} ml',
      proteinLabel: day?.proteinGrams == null
          ? 'Sem dados'
          : '${day!.proteinGrams} g',
      routineLabel: '${treatment.resolved} concluídas',
      nextAppointmentLabel: health?.nextAppointment?.formattedDate,
      healthScore: day?.healthScore.hasData == true
          ? day?.healthScore.score
          : null,
      status: HomeSectionStatus(
        state: health == null
            ? HomeSectionState.unavailable
            : HomeSectionState.ready,
        freshness: freshness,
        hasPendingSync: pendingSync,
      ),
    );
  }

  InsightFeedReadModel composeInsights({
    required DateTime now,
    required HealthDashboardAggregate? health,
    required TreatmentSummaryReadModel treatment,
    required AgendaReadModel agenda,
    required int prescriptionsAwaitingReview,
    required FreshnessReadModel freshness,
    required bool pendingSync,
  }) {
    final day = health?.days.firstOrNull;
    final profile = health?.profile;
    final currentWeight = health?.latestWeight?.weight.value;
    final proteinGoal = profile == null
        ? null
        : ProteinCalculator.goalForWeightKg(
            currentWeight ?? profile.initialWeight.value,
          );
    return insightEngine.generate(
      DeterministicInsightInput(
        now: now,
        timeZone: timeZone(),
        waterMl: day?.waterMl,
        waterGoalMl: day?.waterGoalMl,
        proteinGrams: day?.proteinGrams,
        proteinGoalGrams: proteinGoal,
        treatment: treatment,
        agenda: agenda,
        prescriptionsAwaitingReview: prescriptionsAwaitingReview,
        pendingSync: pendingSync,
        lastWeightAt: health?.latestWeight?.recordedAt.value,
      ),
    );
  }

  CoverageReadModel _coverage(TreatmentAdherenceSummary summary) {
    final state = switch (summary.coverageState) {
      AdherenceCoverageState.complete => CoverageState.sufficient,
      AdherenceCoverageState.partial => CoverageState.partial,
      AdherenceCoverageState.unknown => CoverageState.insufficient,
      AdherenceCoverageState.notApplicable => CoverageState.notApplicable,
    };
    return CoverageReadModel(
      state: state,
      rate: summary.coverageState == AdherenceCoverageState.unknown
          ? null
          : summary.coverage,
      reason: state == CoverageState.insufficient
          ? 'Sem denominador avaliável'
          : null,
      formulaVersion: summary.formulaVersion,
    );
  }

  CoverageReadModel _sufficient({String formulaVersion = 'home-coverage-v1'}) =>
      CoverageReadModel(
        state: CoverageState.sufficient,
        rate: 1,
        formulaVersion: formulaVersion,
      );

  CoverageReadModel _unavailable(String reason) => CoverageReadModel(
    state: CoverageState.unavailable,
    reason: reason,
    formulaVersion: 'home-coverage-v1',
  );

  AgendaItemState _agendaState(TreatmentOccurrenceState state) =>
      switch (state) {
        TreatmentOccurrenceState.future => AgendaItemState.future,
        TreatmentOccurrenceState.due => AgendaItemState.next,
        TreatmentOccurrenceState.open => AgendaItemState.now,
        TreatmentOccurrenceState.resolved => AgendaItemState.resolved,
        TreatmentOccurrenceState.missed => AgendaItemState.missed,
        TreatmentOccurrenceState.canceled => AgendaItemState.canceled,
        TreatmentOccurrenceState.requiresReview =>
          AgendaItemState.requiresReview,
      };

  AgendaItemState _appointmentState(DateTime instant, DateTime now) {
    final difference = instant.difference(now);
    if (difference.isNegative) return AgendaItemState.missed;
    if (difference <= const Duration(hours: 1)) return AgendaItemState.now;
    if (difference <= const Duration(days: 1)) return AgendaItemState.next;
    return AgendaItemState.future;
  }

  int _agendaCompare(AgendaItemReadModel left, AgendaItemReadModel right) {
    final instant = left.effectiveAt.compareTo(right.effectiveAt);
    if (instant != 0) return instant;
    final actionable = (left.isActionable ? 0 : 1).compareTo(
      right.isActionable ? 0 : 1,
    );
    if (actionable != 0) return actionable;
    final state = left.state.index.compareTo(right.state.index);
    if (state != 0) return state;
    final type = left.type.index.compareTo(right.type.index);
    return type != 0 ? type : left.id.compareTo(right.id);
  }

  HomeActionPriority _actionPriority(AgendaItemState state) => switch (state) {
    AgendaItemState.requiresReview => HomeActionPriority.critical,
    AgendaItemState.now || AgendaItemState.missed => HomeActionPriority.high,
    AgendaItemState.next => HomeActionPriority.medium,
    _ => HomeActionPriority.low,
  };

  String _actionReason(AgendaItemState state) => switch (state) {
    AgendaItemState.requiresReview =>
      'O registro possui informações conflitantes.',
    AgendaItemState.missed => 'A janela terminou sem um registro de conclusão.',
    AgendaItemState.now => 'A janela de acompanhamento está aberta.',
    AgendaItemState.next => 'Este é o próximo item da sua agenda.',
    _ => 'Item disponível na agenda.',
  };

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
