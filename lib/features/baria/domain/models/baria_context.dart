import '../../../../core/sync/sync.dart';
import '../../../home/domain/models/models.dart';
import '../../../medical_reports/domain/models/models.dart';
import '../../../academy/domain/entities/entities.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../exams/domain/entities/entities.dart';
import '../../../meals/domain/entities/entities.dart';
import '../../../medications/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../vitamins/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

class BariaContext {
  const BariaContext({
    required this.userId,
    required this.generatedAt,
    required this.today,
    required this.week,
    required this.month,
    required this.report,
    required this.syncState,
    this.recommendedArticles = const <KnowledgeArticle>[],
    this.relevantNotifications = const <String>[],
    this.homeInsights = const <String>[],
  });

  final String userId;
  final DateTime generatedAt;
  final HealthDashboardAggregate? today;
  final HealthDashboardAggregate? week;
  final HealthDashboardAggregate? month;
  final MedicalReportSnapshot? report;
  final SyncState syncState;
  final List<KnowledgeArticle> recommendedArticles;
  final List<String> relevantNotifications;
  final List<String> homeInsights;

  bool get hasAnyData =>
      today != null || week != null || month != null || report != null;
  DailyHealthAggregate? get todayData => today?.today;
  DateTime? get lastSyncAt => syncState.lastSyncAt;
  int? get pendingOfflineOperations => syncState.lastResult?.errors.length;
  String? get userName => today?.profile?.name ?? report?.profile?.name;
  int? get healthScore => todayData?.healthScore.hasData == true
      ? todayData?.healthScore.score
      : null;
  Profile? get userSummary => today?.profile ?? report?.profile;
  List<WeightRecord> get weightEvolution =>
      report?.weightHistory ?? const <WeightRecord>[];
  List<Meal> get recentMeals => report?.meals ?? const <Meal>[];
  List<Vitamin> get vitamins => report?.vitamins ?? const <Vitamin>[];
  List<Medication> get medications =>
      report?.medications ?? const <Medication>[];
  List<Appointment> get appointments =>
      report?.appointments ?? const <Appointment>[];
  List<Exam> get exams => report?.exams ?? const <Exam>[];
  MedicalReportSnapshot? get reports => report;
}
