import 'sync_status.dart';

enum SyncOperationType { create, update, delete }

class SyncOperation {
  const SyncOperation({
    required this.repositoryKey,
    required this.recordId,
    required this.type,
    required this.updatedAt,
    required this.payload,
    this.deletedAt,
    this.userId,
    this.attempts = 0,
  });

  final String repositoryKey;
  final String recordId;
  final SyncOperationType type;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final Map<String, dynamic> payload;
  final int attempts;

  bool get isDelete => type == SyncOperationType.delete || deletedAt != null;

  SyncStatus get syncStatus {
    return switch (type) {
      SyncOperationType.create => SyncStatus.pendingCreate,
      SyncOperationType.update => SyncStatus.pendingUpdate,
      SyncOperationType.delete => SyncStatus.pendingDelete,
    };
  }

  SyncOperation copyWith({
    String? repositoryKey,
    String? recordId,
    SyncOperationType? type,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    Map<String, dynamic>? payload,
    int? attempts,
  }) {
    return SyncOperation(
      repositoryKey: repositoryKey ?? this.repositoryKey,
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repositoryKey': repositoryKey,
      'recordId': recordId,
      'type': type.name,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'userId': userId,
      'payload': payload,
      'attempts': attempts,
    };
  }

  static SyncOperation fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      repositoryKey: json['repositoryKey'] as String,
      recordId: json['recordId'] as String,
      type: SyncOperationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SyncOperationType.update,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: switch (json['deletedAt']) {
        final String value when value.isNotEmpty => DateTime.parse(value),
        _ => null,
      },
      userId: json['userId'] as String?,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      attempts: json['attempts'] as int? ?? 0,
    );
  }
}
