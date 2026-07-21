import '../../../../core/health/models/health_score_result.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';

enum HomeSectionState { loading, ready, empty, stale, unavailable, error }

enum CoverageState {
  sufficient,
  partial,
  insufficient,
  unavailable,
  notApplicable,
}

enum AgendaItemType { treatment, appointment, importantEvent }

enum AgendaItemState {
  now,
  next,
  future,
  resolved,
  missed,
  canceled,
  requiresReview,
  unavailable,
}

enum HomeActionKind { route, treatmentCommand, quickWater }

enum HomeActionPriority { critical, high, medium, low }

enum ProgressMetricState { available, awaitingData, unavailable, notApplicable }

enum InsightPriority { critical, high, medium, low }

class FreshnessReadModel {
  const FreshnessReadModel({
    required this.generatedAt,
    this.sourceUpdatedAt,
    this.isStale = false,
    this.reason,
  });

  final DateTime generatedAt;
  final DateTime? sourceUpdatedAt;
  final bool isStale;
  final String? reason;
}

class CoverageReadModel {
  const CoverageReadModel({
    required this.state,
    this.rate,
    this.reason,
    this.formulaVersion,
  });

  final CoverageState state;
  final double? rate;
  final String? reason;
  final String? formulaVersion;

  bool get hasSufficientData => state == CoverageState.sufficient;
}

class HomeSectionStatus {
  const HomeSectionStatus({
    required this.state,
    required this.freshness,
    this.coverage,
    this.message,
    this.hasPendingSync = false,
  });

  final HomeSectionState state;
  final FreshnessReadModel freshness;
  final CoverageReadModel? coverage;
  final String? message;
  final bool hasPendingSync;
}

class AgendaItemReadModel {
  AgendaItemReadModel({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.title,
    required this.effectiveAt,
    required this.timeZone,
    required this.state,
    required this.source,
    required this.accessibilityLabel,
    this.originalAt,
    this.deepLink,
    Iterable<HomeActionKind> allowedActions = const <HomeActionKind>{},
    this.hasIncompleteData = false,
  }) : allowedActions = Set.unmodifiable(allowedActions);

  final String id;
  final String sourceId;
  final AgendaItemType type;
  final String title;
  final DateTime effectiveAt;
  final DateTime? originalAt;
  final String timeZone;
  final AgendaItemState state;
  final String source;
  final String? deepLink;
  final Set<HomeActionKind> allowedActions;
  final bool hasIncompleteData;
  final String accessibilityLabel;

  bool get isActionable => {
    AgendaItemState.now,
    AgendaItemState.next,
    AgendaItemState.missed,
    AgendaItemState.requiresReview,
  }.contains(state);
}

class AgendaReadModel {
  AgendaReadModel({
    required this.start,
    required this.end,
    required Iterable<AgendaItemReadModel> items,
    required this.status,
  }) : items = List.unmodifiable(items);

  final DateTime start;
  final DateTime end;
  final List<AgendaItemReadModel> items;
  final HomeSectionStatus status;

  Map<DateTime, List<AgendaItemReadModel>> get groupedByDate {
    final result = <DateTime, List<AgendaItemReadModel>>{};
    for (final item in items) {
      final date = DateTime(
        item.effectiveAt.year,
        item.effectiveAt.month,
        item.effectiveAt.day,
      );
      result.putIfAbsent(date, () => <AgendaItemReadModel>[]).add(item);
    }
    final immutable = <DateTime, List<AgendaItemReadModel>>{
      for (final entry in result.entries)
        entry.key: List.unmodifiable(entry.value),
    };
    return Map.unmodifiable(immutable);
  }
}

class TreatmentSummaryReadModel {
  TreatmentSummaryReadModel({
    required this.due,
    required this.open,
    required this.resolved,
    required this.missed,
    required this.requiresReview,
    required this.adherence,
    required this.onTimeAdherence,
    required this.coverage,
    required this.origin,
    required this.formulaVersion,
    required Map<RoutineCategory, double?> adherenceByCategory,
    required this.status,
  }) : adherenceByCategory = Map.unmodifiable(adherenceByCategory);

  final int due;
  final int open;
  final int resolved;
  final int missed;
  final int requiresReview;
  final double? adherence;
  final double? onTimeAdherence;
  final CoverageReadModel coverage;
  final TreatmentDataOrigin origin;
  final String formulaVersion;
  final Map<RoutineCategory, double?> adherenceByCategory;
  final HomeSectionStatus status;
}

class NextActionReadModel {
  const NextActionReadModel({
    required this.id,
    required this.title,
    required this.reason,
    required this.priority,
    required this.source,
    required this.validUntil,
    required this.accessibilityLabel,
    this.dueAt,
    this.deepLink,
    this.command,
  });

  final String id;
  final String title;
  final String reason;
  final HomeActionPriority priority;
  final DateTime? dueAt;
  final String source;
  final String? deepLink;
  final HomeActionKind? command;
  final DateTime validUntil;
  final String accessibilityLabel;
}

class NextActionsReadModel {
  NextActionsReadModel({
    required Iterable<NextActionReadModel> actions,
    required this.status,
  }) : actions = List.unmodifiable(actions.take(3));

  final List<NextActionReadModel> actions;
  final HomeSectionStatus status;
}

class ProgressMetricReadModel {
  const ProgressMetricReadModel({
    required this.id,
    required this.label,
    required this.state,
    required this.coverage,
    this.value,
    this.target,
    this.unit,
    this.progress,
    this.accessibilityLabel,
  });

  final String id;
  final String label;
  final ProgressMetricState state;
  final double? value;
  final double? target;
  final String? unit;
  final double? progress;
  final CoverageReadModel coverage;
  final String? accessibilityLabel;
}

class ProgressSummaryReadModel {
  const ProgressSummaryReadModel({
    required this.routine,
    required this.water,
    required this.protein,
    required this.weight,
    required this.healthScore,
    required this.streak,
    required this.status,
  });

  final ProgressMetricReadModel routine;
  final ProgressMetricReadModel water;
  final ProgressMetricReadModel protein;
  final ProgressMetricReadModel weight;
  final ProgressMetricReadModel healthScore;
  final ProgressMetricReadModel streak;
  final HomeSectionStatus status;
}

class QuickStatsReadModel {
  const QuickStatsReadModel({
    required this.waterLabel,
    required this.proteinLabel,
    required this.routineLabel,
    required this.status,
    this.nextAppointmentLabel,
    this.healthScore,
  });

  final String waterLabel;
  final String proteinLabel;
  final String routineLabel;
  final String? nextAppointmentLabel;
  final int? healthScore;
  final HomeSectionStatus status;
}

class QuickActionReadModel {
  const QuickActionReadModel({
    required this.id,
    required this.title,
    required this.kind,
    required this.accessibilityLabel,
    this.deepLink,
    this.sourceId,
  });

  final String id;
  final String title;
  final HomeActionKind kind;
  final String? deepLink;
  final String? sourceId;
  final String accessibilityLabel;
}

class QuickActionsReadModel {
  QuickActionsReadModel({
    required Iterable<QuickActionReadModel> fixed,
    required Iterable<QuickActionReadModel> dynamic,
    required this.status,
  }) : fixed = List.unmodifiable(fixed),
       dynamic = List.unmodifiable(dynamic.take(2));

  final List<QuickActionReadModel> fixed;
  final List<QuickActionReadModel> dynamic;
  final HomeSectionStatus status;
}

class DeterministicInsightReadModel {
  const DeterministicInsightReadModel({
    required this.id,
    required this.ruleId,
    required this.ruleVersion,
    required this.title,
    required this.message,
    required this.priority,
    required this.sources,
    required this.deduplicationKey,
    required this.expiresAt,
    required this.cooldown,
    required this.coverage,
    required this.disclaimer,
    this.deepLink,
  });

  final String id;
  final String ruleId;
  final String ruleVersion;
  final String title;
  final String message;
  final InsightPriority priority;
  final List<String> sources;
  final String deduplicationKey;
  final DateTime expiresAt;
  final Duration cooldown;
  final CoverageReadModel coverage;
  final String disclaimer;
  final String? deepLink;
}

class InsightFeedReadModel {
  InsightFeedReadModel({
    required Iterable<DeterministicInsightReadModel> insights,
    required this.status,
  }) : insights = List.unmodifiable(insights);

  final List<DeterministicInsightReadModel> insights;
  final HomeSectionStatus status;
}

class ProgressTrendPointReadModel {
  const ProgressTrendPointReadModel({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class ProgressTrendReadModel {
  ProgressTrendReadModel({
    required this.start,
    required this.end,
    required Iterable<ProgressTrendPointReadModel> points,
    required this.coverage,
    required this.status,
  }) : points = List.unmodifiable(points);

  final DateTime start;
  final DateTime end;
  final List<ProgressTrendPointReadModel> points;
  final CoverageReadModel coverage;
  final HomeSectionStatus status;
}

class TodayDashboardReadModel {
  const TodayDashboardReadModel({
    required this.userId,
    required this.clinicalDate,
    required this.timeZone,
    required this.nextActions,
    required this.agenda,
    required this.treatment,
    required this.progress,
    required this.quickStats,
    required this.quickActions,
    required this.insights,
    required this.status,
    this.userName,
    this.healthScore,
  });

  final String userId;
  final DateTime clinicalDate;
  final String timeZone;
  final String? userName;
  final NextActionsReadModel nextActions;
  final AgendaReadModel agenda;
  final TreatmentSummaryReadModel treatment;
  final ProgressSummaryReadModel progress;
  final QuickStatsReadModel quickStats;
  final QuickActionsReadModel quickActions;
  final InsightFeedReadModel insights;
  final HealthScoreResult? healthScore;
  final HomeSectionStatus status;
}
