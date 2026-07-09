class SyncError {
  const SyncError({
    required this.repositoryKey,
    required this.message,
    this.recordId,
    this.operation,
    this.retryable = true,
    this.cause,
    this.stackTrace,
  });

  final String repositoryKey;
  final String? recordId;
  final String message;
  final String? operation;
  final bool retryable;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final record = recordId == null ? '' : ' record=$recordId';
    final action = operation == null ? '' : ' operation=$operation';
    return 'SyncError(repository=$repositoryKey$record$action, message=$message)';
  }
}
