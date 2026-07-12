import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const appointmentLegacyStorageKey = 'local_database.collection.appointments';
const anonymousAppointmentUserId = 'anonymous';

class NormalizedAppointmentRecord {
  const NormalizedAppointmentRecord({
    required this.userId,
    required this.id,
    required this.title,
    required this.appointmentAt,
    required this.status,
    required this.doctorName,
    required this.location,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });
  factory NormalizedAppointmentRecord.fromLegacy(Map<String, dynamic> json) {
    final record = LocalDatabaseRecord.fromJson(json);
    final data = record.data;
    final title = data['title'], date = data['date'], status = data['status'];
    if (record.id.isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        date is! String ||
        status is! String ||
        !const {'scheduled', 'completed', 'canceled'}.contains(status)) {
      throw const FormatException('Invalid appointment');
    }
    final rawUser = record.metadata.userId?.trim();
    return NormalizedAppointmentRecord(
      userId: rawUser == null || rawUser.isEmpty
          ? anonymousAppointmentUserId
          : rawUser,
      id: record.id,
      title: title.trim(),
      appointmentAt: DateTime.parse(date),
      status: status,
      doctorName: data['doctorName'] as String?,
      location: data['location'] as String?,
      notes: data['notes'] as String?,
      createdAt: record.metadata.createdAt,
      updatedAt: record.metadata.updatedAt,
      deletedAt: record.metadata.deletedAt,
      syncStatus: record.metadata.syncStatus.name,
    );
  }
  factory NormalizedAppointmentRecord.fromDrift(AppointmentRecord r) =>
      NormalizedAppointmentRecord(
        userId: r.userId,
        id: r.id,
        title: r.title,
        appointmentAt: r.appointmentAt,
        status: r.status,
        doctorName: r.doctorName,
        location: r.location,
        notes: r.notes,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
        syncStatus: r.syncStatus,
      );
  final String userId, id, title, status, syncStatus;
  final DateTime appointmentAt, createdAt, updatedAt;
  final DateTime? deletedAt;
  final String? doctorName, location, notes;
  AppointmentRecordsCompanion get companion =>
      AppointmentRecordsCompanion.insert(
        id: id,
        userId: userId,
        title: title,
        appointmentAt: appointmentAt,
        status: status,
        doctorName: Value(doctorName),
        location: Value(location),
        notes: Value(notes),
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: Value(deletedAt),
        syncStatus: syncStatus,
      );
  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': id,
    'title': title,
    'appointmentAt': appointmentAt.toUtc().toIso8601String(),
    'status': status,
    'doctorName': doctorName,
    'location': location,
    'notes': notes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'syncStatus': syncStatus,
  };
}

class AppointmentLegacySnapshot {
  const AppointmentLegacySnapshot(this.records, this.invalid);
  final List<NormalizedAppointmentRecord> records;
  final int invalid;
}

AppointmentLegacySnapshot readAppointmentLegacy(LocalStorageService storage) {
  final raw = storage.getString(appointmentLegacyStorageKey);
  if (raw == null || raw.isEmpty) return const AppointmentLegacySnapshot([], 0);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const AppointmentLegacySnapshot([], 1);
    final records = <NormalizedAppointmentRecord>[];
    var invalid = 0;
    for (final item in decoded) {
      try {
        records.add(
          NormalizedAppointmentRecord.fromLegacy(
            Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (_) {
        invalid++;
      }
    }
    return AppointmentLegacySnapshot(records, invalid);
  } catch (_) {
    return const AppointmentLegacySnapshot([], 1);
  }
}

String appointmentChecksum(Iterable<NormalizedAppointmentRecord> records) {
  final values = records.map((r) => r.normalized).toList()
    ..sort(
      (a, b) =>
          '${a['userId']}:${a['id']}'.compareTo('${b['userId']}:${b['id']}'),
    );
  return sha256.convert(utf8.encode(jsonEncode(values))).toString();
}

class AppointmentLegacyService {
  const AppointmentLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.appointments.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final snapshot = readAppointmentLegacy(_storage);
    final cutovers =
        (await _database.select(_database.appointmentCutovers).get())
            .map((r) => r.userId)
            .toSet();
    final candidates = snapshot.records
        .where((r) => !cutovers.contains(r.userId))
        .toList();
    await _database.transaction(() async {
      for (final candidate in candidates) {
        final existing =
            await (_database.select(_database.appointmentRecords)..where(
                  (r) =>
                      r.userId.equals(candidate.userId) &
                      r.id.equals(candidate.id),
                ))
                .getSingleOrNull();
        if (existing == null ||
            candidate.updatedAt.isAfter(existing.updatedAt)) {
          await _database
              .into(_database.appointmentRecords)
              .insertOnConflictUpdate(candidate.companion);
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(appointmentChecksum(candidates)),
              importedCount: Value(candidates.length),
            ),
          );
    });
  }
}
