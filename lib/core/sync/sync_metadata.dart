import 'sync_status.dart';

class SyncMetadata {
  const SyncMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.userId,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get isDeleted => deletedAt != null;

  SyncMetadata copyWith({
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) {
    return SyncMetadata(
      id: id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  static SyncMetadata fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: switch (json['deletedAt']) {
        final String value when value.isNotEmpty => DateTime.parse(value),
        _ => null,
      },
      syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
    );
  }
}
