import '../sync/sync.dart';

class LocalDatabaseRecord {
  const LocalDatabaseRecord({required this.metadata, required this.data});

  final SyncMetadata metadata;
  final Map<String, dynamic> data;

  String get id => metadata.id;

  bool get isDeleted => metadata.isDeleted;

  LocalDatabaseRecord copyWith({
    SyncMetadata? metadata,
    Map<String, dynamic>? data,
  }) {
    return LocalDatabaseRecord(
      metadata: metadata ?? this.metadata,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {'metadata': metadata.toJson(), 'data': data};
  }

  static LocalDatabaseRecord fromJson(Map<String, dynamic> json) {
    return LocalDatabaseRecord(
      metadata: SyncMetadata.fromJson(
        Map<String, dynamic>.from(json['metadata'] as Map),
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
