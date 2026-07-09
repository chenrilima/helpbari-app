import 'sync_result.dart';

enum SyncPhase { idle, syncing, success, failure }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.idle,
    this.lastPullAt,
    this.lastPushAt,
    this.lastSyncAt,
    this.deviceId,
    this.appVersion = 'unknown',
    this.userId,
    this.lastResult,
    this.errorMessage,
  });

  final SyncPhase phase;
  final DateTime? lastPullAt;
  final DateTime? lastPushAt;
  final DateTime? lastSyncAt;
  final String? deviceId;
  final String appVersion;
  final String? userId;
  final SyncResult? lastResult;
  final String? errorMessage;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncState copyWith({
    SyncPhase? phase,
    DateTime? lastPullAt,
    DateTime? lastPushAt,
    DateTime? lastSyncAt,
    String? deviceId,
    String? appVersion,
    String? userId,
    SyncResult? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      userId: userId ?? this.userId,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'lastPullAt': lastPullAt?.toIso8601String(),
      'lastPushAt': lastPushAt?.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'deviceId': deviceId,
      'appVersion': appVersion,
      'userId': userId,
    };
  }

  static SyncState fromJson(Map<String, dynamic> json) {
    return SyncState(
      phase: SyncPhase.values.firstWhere(
        (phase) => phase.name == json['phase'],
        orElse: () => SyncPhase.idle,
      ),
      lastPullAt: _date(json['lastPullAt']),
      lastPushAt: _date(json['lastPushAt']),
      lastSyncAt: _date(json['lastSyncAt']),
      deviceId: json['deviceId'] as String?,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      userId: json['userId'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    return switch (value) {
      final String raw when raw.isNotEmpty => DateTime.parse(raw),
      _ => null,
    };
  }
}
