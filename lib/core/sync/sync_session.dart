import 'dart:async';

class SyncSessionRegistry {
  String? _userId;
  int _generation = 0;
  Completer<void> _revoked = Completer<void>();

  String? get userId => _userId;
  int get generation => _generation;

  void activate(String? userId) {
    if (_userId == userId) return;
    if (!_revoked.isCompleted) _revoked.complete();
    _userId = userId;
    _generation++;
    _revoked = Completer<void>();
  }

  SyncSessionToken capture(String expectedUserId) {
    if (_userId != expectedUserId) {
      throw SyncSessionRevokedException(expectedUserId, _generation);
    }
    return SyncSessionToken._(
      registry: this,
      userId: expectedUserId,
      generation: _generation,
      revoked: _revoked.future,
    );
  }
}

class SyncSessionToken {
  const SyncSessionToken._({
    required SyncSessionRegistry registry,
    required this.userId,
    required this.generation,
    required Future<void> revoked,
  }) : _registry = registry,
       _revoked = revoked;

  final SyncSessionRegistry _registry;
  final Future<void> _revoked;
  final String userId;
  final int generation;

  bool get isCurrent =>
      _registry.userId == userId && _registry.generation == generation;

  Future<void> get whenRevoked => _revoked;

  void ensureCurrent() {
    if (!isCurrent) throw SyncSessionRevokedException(userId, generation);
  }

  Future<void> cancellableDelay(Duration duration) async {
    ensureCurrent();
    if (duration == Duration.zero) return;
    await Future.any<void>([Future<void>.delayed(duration), whenRevoked]);
    ensureCurrent();
  }
}

class SyncSessionRevokedException implements Exception {
  const SyncSessionRevokedException(this.userId, this.generation);

  final String userId;
  final int generation;

  @override
  String toString() => 'Sync session was revoked.';
}
