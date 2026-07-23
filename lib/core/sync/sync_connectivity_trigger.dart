import 'dart:async';

class SyncConnectivityTrigger {
  SyncConnectivityTrigger({
    required Future<void> Function() onRecovered,
    this.debounce = const Duration(seconds: 1),
  }) : _onRecovered = onRecovered;

  final Future<void> Function() _onRecovered;
  final Duration debounce;
  StreamSubscription<bool>? _subscription;
  Timer? _debounceTimer;
  bool? _hasTransport;
  bool _foreground = true;
  bool _disposed = false;

  void listen(Stream<bool> changes) {
    _subscription ??= changes.distinct().listen(_onConnectivityChanged);
  }

  void setForeground(bool value) {
    _foreground = value;
    if (!value) _debounceTimer?.cancel();
  }

  void _onConnectivityChanged(bool hasTransport) {
    if (_disposed) return;
    final recovered = _hasTransport == false && hasTransport;
    _hasTransport = hasTransport;
    if (!recovered || !_foreground) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      if (_disposed || !_foreground || _hasTransport != true) return;
      unawaited(_onRecovered());
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _debounceTimer?.cancel();
    await _subscription?.cancel();
  }
}
