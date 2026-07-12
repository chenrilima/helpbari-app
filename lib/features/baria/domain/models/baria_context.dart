import '../../../../core/sync/sync.dart';
import '../../../home/domain/models/models.dart';
import '../../../medical_reports/domain/models/models.dart';

class BariaContext {
  const BariaContext({
    required this.userId,
    required this.generatedAt,
    required this.today,
    required this.week,
    required this.month,
    required this.report,
    required this.syncState,
  });

  final String userId;
  final DateTime generatedAt;
  final HealthDashboardAggregate? today;
  final HealthDashboardAggregate? week;
  final HealthDashboardAggregate? month;
  final MedicalReportSnapshot? report;
  final SyncState syncState;

  bool get hasAnyData =>
      today != null || week != null || month != null || report != null;
  DailyHealthAggregate? get todayData => today?.today;
  DateTime? get lastSyncAt => syncState.lastSyncAt;
  int? get pendingOfflineOperations => syncState.lastResult?.errors.length;
}
