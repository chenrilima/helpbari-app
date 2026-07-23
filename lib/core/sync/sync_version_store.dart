abstract interface class SyncVersionStore {
  Future<int?> read({
    required String userId,
    required String repositoryKey,
    required String recordId,
  });

  Future<void> write({
    required String userId,
    required String repositoryKey,
    required String recordId,
    required int serverRevision,
  });
}
