import 'sync_conflict.dart';
import 'sync_error.dart';

enum SyncDomain {
  water,
  weight,
  meals,
  appointments,
  exams,
  treatment,
  prescriptions,
  settings,
  profile,
  vitamins,
  medications,
  bioimpedance,
  documents,
  privacy,
  onboarding,
  unknown;

  static SyncDomain fromRepositoryKey(String key) => switch (key) {
    'water' => water,
    'weight' => weight,
    'meals' => meals,
    'appointments' => appointments,
    'exams' || 'medical_exams' => exams,
    'smart_routines' || 'vitamin_logs' || 'medication_logs' => treatment,
    'medical_prescriptions' || 'prescription_platform' => prescriptions,
    'settings' => settings,
    'profile' => profile,
    'vitamins' => vitamins,
    'medications' => medications,
    'bioimpedance' => bioimpedance,
    'document_processings' => documents,
    'privacy_consents' => privacy,
    'onboarding_states' => onboarding,
    _ => unknown,
  };
}

class SyncResult {
  const SyncResult({
    required this.startedAt,
    required this.completedAt,
    required this.repositoriesProcessed,
    required this.pushed,
    required this.pulled,
    required this.deleted,
    required this.conflicts,
    required this.errors,
    this.userId,
    this.domainsChanged = const {},
    this.fullRefreshRequired = false,
  });

  final DateTime startedAt;
  final DateTime completedAt;
  final int repositoriesProcessed;
  final int pushed;
  final int pulled;
  final int deleted;
  final List<SyncConflict> conflicts;
  final List<SyncError> errors;
  final String? userId;
  final Set<SyncDomain> domainsChanged;
  final bool fullRefreshRequired;
  int get remoteChanges => pulled;
  int get localPromotions => pushed;

  bool get isSuccess => repositoriesProcessed > 0 && errors.isEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;
  bool belongsTo(String? currentUserId) =>
      userId != null && userId == currentUserId;

  SyncResult copyWith({
    DateTime? completedAt,
    int? repositoriesProcessed,
    int? pushed,
    int? pulled,
    int? deleted,
    List<SyncConflict>? conflicts,
    List<SyncError>? errors,
    Set<SyncDomain>? domainsChanged,
    bool? fullRefreshRequired,
  }) {
    return SyncResult(
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      repositoriesProcessed:
          repositoriesProcessed ?? this.repositoriesProcessed,
      pushed: pushed ?? this.pushed,
      pulled: pulled ?? this.pulled,
      deleted: deleted ?? this.deleted,
      conflicts: conflicts ?? this.conflicts,
      errors: errors ?? this.errors,
      userId: userId,
      domainsChanged: domainsChanged ?? this.domainsChanged,
      fullRefreshRequired: fullRefreshRequired ?? this.fullRefreshRequired,
    );
  }

  static SyncResult empty(DateTime startedAt) {
    return SyncResult(
      startedAt: startedAt,
      completedAt: startedAt,
      repositoriesProcessed: 0,
      pushed: 0,
      pulled: 0,
      deleted: 0,
      conflicts: const [],
      errors: const [],
      domainsChanged: const {},
    );
  }
}
