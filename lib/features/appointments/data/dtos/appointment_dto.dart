import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.syncMetadata,
    this.doctorName,
    this.location,
    this.notes,
  });

  final String id;
  final String title;
  final DateTime date;
  final AppointmentStatus status;
  final String? doctorName;
  final String? location;
  final String? notes;
  final SyncMetadata syncMetadata;

  Appointment toEntity({ClockService clock = const AppClockService()}) {
    return Appointment(
      id: id,
      title: title,
      date: AppointmentDate(date, clock: clock),
      doctorName: doctorName,
      location: location,
      notes: notes,
      status: status,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'title': title,
        'date': date.toIso8601String(),
        'status': status.name,
        'doctorName': doctorName,
        'location': location,
        'notes': notes,
      },
    );
  }

  static AppointmentDto fromEntity(
    Appointment appointment, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return AppointmentDto(
      id: appointment.id,
      title: appointment.title,
      date: appointment.date.value,
      status: appointment.status,
      doctorName: appointment.doctorName,
      location: appointment.location,
      notes: appointment.notes,
      syncMetadata: SyncMetadata(
        id: appointment.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static AppointmentDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return AppointmentDto(
      id: record.id,
      title: data['title'] as String,
      date: DateTime.parse(data['date'] as String),
      status: AppointmentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      doctorName: data['doctorName'] as String?,
      location: data['location'] as String?,
      notes: data['notes'] as String?,
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
