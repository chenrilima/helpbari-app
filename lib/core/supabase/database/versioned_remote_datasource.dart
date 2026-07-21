abstract interface class VersionedRemoteDatasource<T> {
  Future<T> upsertVersioned(
    T value, {
    required String userId,
    required int? baseRevision,
  });
}
