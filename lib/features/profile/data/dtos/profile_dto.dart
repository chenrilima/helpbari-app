import '../../../../core/database/database.dart';
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
        userId: previousMetadata?.userId,
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
