enum PrivacyDeletionKind { data, account }

class PrivacyDeletionResult {
  const PrivacyDeletionResult({
    required this.kind,
    required this.remoteCompleted,
    required this.localCompleted,
  });

  final PrivacyDeletionKind kind;
  final bool remoteCompleted;
  final bool localCompleted;
  bool get completed => remoteCompleted && localCompleted;
}
