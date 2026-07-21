import '../models/home_intelligence_models.dart';

class DeterministicInsightInput {
  const DeterministicInsightInput({
    required this.now,
    required this.timeZone,
    required this.waterMl,
    required this.waterGoalMl,
    required this.proteinGrams,
    required this.proteinGoalGrams,
    required this.treatment,
    required this.agenda,
    required this.prescriptionsAwaitingReview,
    required this.pendingSync,
    this.lastWeightAt,
  });

  final DateTime now;
  final String timeZone;
  final int? waterMl;
  final int? waterGoalMl;
  final int? proteinGrams;
  final int? proteinGoalGrams;
  final TreatmentSummaryReadModel treatment;
  final AgendaReadModel agenda;
  final int prescriptionsAwaitingReview;
  final bool pendingSync;
  final DateTime? lastWeightAt;
}

class DeterministicInsightEngine {
  const DeterministicInsightEngine();

  static const disclaimer =
      'Informação de acompanhamento; não representa orientação ou avaliação clínica.';

  InsightFeedReadModel generate(DeterministicInsightInput input) {
    final insights = <DeterministicInsightReadModel>[
      ..._coverage(input),
      ..._treatment(input),
      ..._appointments(input),
      ..._hydration(input),
      ..._protein(input),
      ..._prescriptions(input),
      ..._weight(input),
      ..._sync(input),
    ]..sort(_compare);
    final unique = <String, DeterministicInsightReadModel>{};
    for (final insight in insights) {
      unique.putIfAbsent(insight.deduplicationKey, () => insight);
    }
    final freshness = FreshnessReadModel(generatedAt: input.now);
    return InsightFeedReadModel(
      insights: unique.values,
      status: HomeSectionStatus(
        state: unique.isEmpty ? HomeSectionState.empty : HomeSectionState.ready,
        freshness: freshness,
      ),
    );
  }

  List<DeterministicInsightReadModel> _coverage(
    DeterministicInsightInput input,
  ) {
    if (input.treatment.coverage.state != CoverageState.insufficient &&
        input.treatment.coverage.state != CoverageState.unavailable) {
      return const [];
    }
    return [
      _insight(
        input: input,
        ruleId: 'treatment-coverage',
        title: 'Dados de rotina insuficientes',
        message:
            'Ainda não há dados suficientes para avaliar sua rotina de tratamento.',
        priority: InsightPriority.medium,
        source: 'smartRoutines',
        coverage: input.treatment.coverage,
      ),
    ];
  }

  List<DeterministicInsightReadModel> _treatment(
    DeterministicInsightInput input,
  ) {
    if (input.treatment.requiresReview > 0) {
      return [
        _insight(
          input: input,
          ruleId: 'adherence-conflict',
          title: 'Registro precisa de revisão',
          message: 'Há registros conflitantes que precisam ser revisados.',
          priority: InsightPriority.critical,
          source: 'smartRoutines',
          coverage: input.treatment.coverage,
          deepLink: '/home',
        ),
      ];
    }
    if (input.treatment.missed > 0) {
      return [
        _insight(
          input: input,
          ruleId: 'treatment-missed',
          title: 'Rotina sem registro',
          message:
              'Uma janela de acompanhamento terminou sem registro de conclusão.',
          priority: InsightPriority.high,
          source: 'smartRoutines',
          coverage: input.treatment.coverage,
          deepLink: '/home',
        ),
      ];
    }
    if (input.treatment.open > 0) {
      return [
        _insight(
          input: input,
          ruleId: 'treatment-open',
          title: 'Rotina em andamento',
          message: 'Há uma ocorrência com janela de acompanhamento aberta.',
          priority: InsightPriority.high,
          source: 'smartRoutines',
          coverage: input.treatment.coverage,
          deepLink: '/home',
        ),
      ];
    }
    return const [];
  }

  List<DeterministicInsightReadModel> _appointments(
    DeterministicInsightInput input,
  ) {
    final today = DateTime(input.now.year, input.now.month, input.now.day);
    final matches = input.agenda.items.where(
      (item) =>
          item.type == AgendaItemType.appointment &&
          item.effectiveAt.isBefore(today.add(const Duration(days: 2))) &&
          !item.effectiveAt.isBefore(today),
    );
    if (matches.isEmpty) return const [];
    final appointment = matches.first;
    final tomorrow = appointment.effectiveAt.day != today.day;
    return [
      _insight(
        input: input,
        ruleId: 'appointment-soon',
        title: tomorrow ? 'Consulta amanhã' : 'Consulta hoje',
        message: 'Há uma consulta próxima na sua agenda.',
        priority: tomorrow ? InsightPriority.high : InsightPriority.critical,
        source: 'appointments',
        coverage: _sufficient(),
        deepLink: '/appointments',
        key: 'appointment:${appointment.id}',
      ),
    ];
  }

  List<DeterministicInsightReadModel> _hydration(
    DeterministicInsightInput input,
  ) {
    final current = input.waterMl;
    final goal = input.waterGoalMl;
    if (current == null || goal == null || goal <= 0) return const [];
    final elapsed = ((input.now.hour * 60 + input.now.minute) / (24 * 60))
        .clamp(.0, 1.0);
    final expected = goal * elapsed;
    if (input.now.hour < 8 || current >= expected * .7) return const [];
    return [
      _insight(
        input: input,
        ruleId: 'hydration-pace',
        title: 'Hidratação em progresso',
        message:
            'Seus registros de água estão abaixo do ritmo da meta neste momento do dia.',
        priority: InsightPriority.medium,
        source: 'water',
        coverage: _sufficient(),
        deepLink: '/water',
      ),
    ];
  }

  List<DeterministicInsightReadModel> _protein(
    DeterministicInsightInput input,
  ) {
    final current = input.proteinGrams;
    final goal = input.proteinGoalGrams;
    if (current == null || goal == null || goal <= 0 || input.now.hour < 14) {
      return const [];
    }
    final expected = input.now.hour >= 20 ? .8 : .45;
    if (current / goal >= expected) return const [];
    return [
      _insight(
        input: input,
        ruleId: 'protein-pace',
        title: 'Proteína em acompanhamento',
        message:
            'Os registros de proteína estão abaixo da progressão da meta neste momento do dia.',
        priority: InsightPriority.medium,
        source: 'meals',
        coverage: _sufficient(),
        deepLink: '/meals',
      ),
    ];
  }

  List<DeterministicInsightReadModel> _prescriptions(
    DeterministicInsightInput input,
  ) => input.prescriptionsAwaitingReview == 0
      ? const []
      : [
          _insight(
            input: input,
            ruleId: 'prescription-review',
            title: 'Prescrição aguardando revisão',
            message: 'Há uma prescrição que precisa da sua revisão.',
            priority: InsightPriority.medium,
            source: 'prescriptions',
            coverage: _sufficient(),
            deepLink: '/prescriptions',
          ),
        ];

  List<DeterministicInsightReadModel> _weight(
    DeterministicInsightInput input,
  ) =>
      input.lastWeightAt == null ||
          input.now.difference(input.lastWeightAt!).inDays <= 14
      ? const []
      : [
          _insight(
            input: input,
            ruleId: 'weight-freshness',
            title: 'Peso sem registro recente',
            message: 'Não há pesagem registrada nos últimos 14 dias.',
            priority: InsightPriority.low,
            source: 'weight',
            coverage: _sufficient(),
            deepLink: '/weight',
          ),
        ];

  List<DeterministicInsightReadModel> _sync(DeterministicInsightInput input) =>
      !input.pendingSync
      ? const []
      : [
          _insight(
            input: input,
            ruleId: 'pending-sync',
            title: 'Atualização pendente',
            message:
                'Alguns registros locais serão sincronizados quando houver conexão.',
            priority: InsightPriority.low,
            source: 'sync',
            coverage: _sufficient(),
          ),
        ];

  DeterministicInsightReadModel _insight({
    required DeterministicInsightInput input,
    required String ruleId,
    required String title,
    required String message,
    required InsightPriority priority,
    required String source,
    required CoverageReadModel coverage,
    String? deepLink,
    String? key,
  }) {
    final date =
        '${input.now.year}-${input.now.month.toString().padLeft(2, '0')}-${input.now.day.toString().padLeft(2, '0')}';
    final deduplicationKey = key ?? '$ruleId:$date';
    return DeterministicInsightReadModel(
      id: '$deduplicationKey:v1',
      ruleId: ruleId,
      ruleVersion: '1',
      title: title,
      message: message,
      priority: priority,
      sources: List.unmodifiable([source]),
      deduplicationKey: deduplicationKey,
      expiresAt: DateTime(input.now.year, input.now.month, input.now.day + 1),
      cooldown: const Duration(hours: 4),
      coverage: coverage,
      disclaimer: disclaimer,
      deepLink: deepLink,
    );
  }

  CoverageReadModel _sufficient() => const CoverageReadModel(
    state: CoverageState.sufficient,
    rate: 1,
    formulaVersion: 'home-coverage-v1',
  );

  int _compare(
    DeterministicInsightReadModel left,
    DeterministicInsightReadModel right,
  ) {
    final priority = left.priority.index.compareTo(right.priority.index);
    return priority != 0 ? priority : left.id.compareTo(right.id);
  }
}
