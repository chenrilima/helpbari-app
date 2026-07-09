import 'sync_operation.dart';

enum SyncConflictResolution { latestUpdatedAtWins }

class SyncConflict {
  const SyncConflict({
    required this.repositoryKey,
    required this.recordId,
    required this.local,
    required this.remote,
    required this.winner,
    this.resolution = SyncConflictResolution.latestUpdatedAtWins,
  });

  final String repositoryKey;
  final String recordId;
  final SyncOperation local;
  final SyncOperation remote;
  final SyncOperation winner;
  final SyncConflictResolution resolution;

  bool get remoteWon => identical(winner, remote);
  bool get localWon => identical(winner, local);
}
