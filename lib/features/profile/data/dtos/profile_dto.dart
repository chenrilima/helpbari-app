import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.birthDate,
    required this.heightInCentimeters,
    required this.initialWeight,
    required this.surgeryDate,
    required this.surgeryType,
    required this.syncMetadata,
    this.targetWeight,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime birthDate;
  final int heightInCentimeters;
  final double initialWeight;
  final double? targetWeight;
  final DateTime surgeryDate;
  final SurgeryType surgeryType;
  final String? photoUrl;
  final SyncMetadata syncMetadata;

  Profile toEntity({ClockService clock = const AppClockService()}) {
    final height = Height.create(heightInCentimeters);
    final initial = Weight.create(initialWeight);
    final target = targetWeight == null ? null : Weight.create(targetWeight!);

    if (height == null || initial == null) {
      throw FormatException('Perfil local inválido: $id');
    }

    return Profile(
      id: id,
      name: name,
      email: email,
      createdAt: AppDate(createdAt, clock: clock),
      birthDate: AppDate(birthDate, clock: clock),
      height: height,
      initialWeight: initial,
      targetWeight: target,
      surgeryDate: AppDate(surgeryDate, clock: clock),
      surgeryType: surgeryType,
      photoUrl: photoUrl,
      clock: clock,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'birthDate': birthDate.toIso8601String(),
        'heightInCentimeters': heightInCentimeters,
        'initialWeight': initialWeight,
        'targetWeight': targetWeight,
        'surgeryDate': surgeryDate.toIso8601String(),
        'surgeryType': surgeryType.name,
        'photoUrl': photoUrl,
      },
    );
  }

  static ProfileDto fromEntity(
    Profile profile, {
    required DateTime now,
    String? userId,
    SyncMetadata? previousMetadata,
  }) {
    final createdAt = previousMetadata?.createdAt ?? profile.createdAt.value;
    final syncStatus = _nextSyncStatus(previousMetadata?.syncStatus);

    return ProfileDto(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      createdAt: profile.createdAt.value,
      birthDate: profile.birthDate.value,
      heightInCentimeters: profile.height.valueInCentimeters,
      initialWeight: profile.initialWeight.value,
      targetWeight: profile.targetWeight?.value,
      surgeryDate: profile.surgeryDate.value,
      surgeryType: profile.surgeryType,
      photoUrl: profile.photoUrl,
      syncMetadata: SyncMetadata(
        id: profile.id,
        userId: userId ?? previousMetadata?.userId,
        createdAt: createdAt,
        updatedAt: now,
        syncStatus: syncStatus,
      ),
    );
  }

  static ProfileDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return ProfileDto(
      id: record.id,
      name: data['name'] as String,
      email: data['email'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      birthDate: DateTime.parse(data['birthDate'] as String),
      heightInCentimeters: data['heightInCentimeters'] as int,
      initialWeight: (data['initialWeight'] as num).toDouble(),
      targetWeight: (data['targetWeight'] as num?)?.toDouble(),
      surgeryDate: DateTime.parse(data['surgeryDate'] as String),
      surgeryType: SurgeryType.values.firstWhere(
        (type) => type.name == data['surgeryType'],
        orElse: () => SurgeryType.other,
      ),
      photoUrl: data['photoUrl'] as String?,
      syncMetadata: record.metadata,
    );
  }

  ProfileRecordsCompanion toDrift({required String userId}) =>
      ProfileRecordsCompanion(
        id: Value(id),
        userId: Value(userId),
        name: Value(name),
        email: Value(email),
        birthDate: Value(birthDate),
        heightInCentimeters: Value(heightInCentimeters),
        initialWeight: Value(initialWeight),
        targetWeight: Value(targetWeight),
        surgeryDate: Value(surgeryDate),
        surgeryType: Value(surgeryType.name),
        photoUrl: Value(photoUrl),
        createdAt: Value(syncMetadata.createdAt),
        updatedAt: Value(syncMetadata.updatedAt),
        deletedAt: Value(syncMetadata.deletedAt),
        syncStatus: Value(syncMetadata.syncStatus.name),
      );

  Map<String, dynamic> toSupabase(String userId) => {
    'id': id,
    'user_id': userId,
    'name': name,
    'email': email,
    'birth_date': birthDate.toIso8601String(),
    'height_in_centimeters': heightInCentimeters,
    'initial_weight': initialWeight,
    'target_weight': targetWeight,
    'surgery_date': surgeryDate.toIso8601String(),
    'surgery_type': surgeryType.name,
    'photo_url': photoUrl,
    'created_at': syncMetadata.createdAt.toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toIso8601String(),
  };

  static ProfileDto fromDrift(ProfileRecord row) => ProfileDto(
    id: row.id,
    name: row.name,
    email: row.email,
    createdAt: row.createdAt,
    birthDate: row.birthDate,
    heightInCentimeters: row.heightInCentimeters,
    initialWeight: row.initialWeight,
    targetWeight: row.targetWeight,
    surgeryDate: row.surgeryDate,
    surgeryType: SurgeryType.values.firstWhere(
      (value) => value.name == row.surgeryType,
      orElse: () => SurgeryType.other,
    ),
    photoUrl: row.photoUrl,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );

  static ProfileDto fromSupabase(Map<String, dynamic> json) => ProfileDto(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    birthDate: DateTime.parse(json['birth_date'] as String),
    heightInCentimeters: json['height_in_centimeters'] as int,
    initialWeight: (json['initial_weight'] as num).toDouble(),
    targetWeight: (json['target_weight'] as num?)?.toDouble(),
    surgeryDate: DateTime.parse(json['surgery_date'] as String),
    surgeryType: SurgeryType.values.firstWhere(
      (value) => value.name == json['surgery_type'],
      orElse: () => SurgeryType.other,
    ),
    photoUrl: json['photo_url'] as String?,
    syncMetadata: SyncMetadata(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      syncStatus: SyncStatus.synced,
    ),
  );

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) {
    return switch (currentStatus) {
      SyncStatus.synced => SyncStatus.pendingUpdate,
      SyncStatus.failed => SyncStatus.pendingUpdate,
      SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
      SyncStatus.pendingCreate => SyncStatus.pendingCreate,
      SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
      null => SyncStatus.pendingCreate,
    };
  }
}
