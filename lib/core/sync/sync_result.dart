import 'sync_conflict.dart';
import 'sync_error.dart';

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
  });

  final DateTime startedAt;
  final DateTime completedAt;
  final int repositoriesProcessed;
  final int pushed;
  final int pulled;
  final int deleted;
  final List<SyncConflict> conflicts;
  final List<SyncError> errors;

  bool get isSuccess => repositoriesProcessed > 0 && errors.isEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;

  SyncResult copyWith({
    DateTime? completedAt,
    int? repositoriesProcessed,
    int? pushed,
    int? pulled,
    int? deleted,
    List<SyncConflict>? conflicts,
    List<SyncError>? errors,
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
    );
  }
}
