import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';

class PrivacyConsentDto {
  const PrivacyConsentDto({required this.consent, required this.syncMetadata});

  final PrivacyConsent consent;
  final SyncMetadata syncMetadata;

  PrivacyConsentRecordsCompanion toDrift() =>
      PrivacyConsentRecordsCompanion.insert(
        id: consent.id,
        userId: consent.userId,
        termsVersion: consent.termsVersion,
        privacyVersion: consent.privacyVersion,
        acceptedAt: consent.acceptedAt,
        deviceId: consent.deviceId,
        timezone: consent.timezone,
        createdAt: syncMetadata.createdAt,
        updatedAt: syncMetadata.updatedAt,
        deletedAt: Value(syncMetadata.deletedAt),
        syncStatus: syncMetadata.syncStatus.name,
      );

  Map<String, Object?> toSupabase() => {
    'id': consent.id,
    'user_id': consent.userId,
    'terms_version': consent.termsVersion,
    'privacy_version': consent.privacyVersion,
    'accepted_at': consent.acceptedAt.toUtc().toIso8601String(),
    'device_id': consent.deviceId,
    'timezone': consent.timezone,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  static PrivacyConsentDto fromDrift(PrivacyConsentRecord row) =>
      PrivacyConsentDto(
        consent: PrivacyConsent(
          id: row.id,
          userId: row.userId,
          termsVersion: row.termsVersion,
          privacyVersion: row.privacyVersion,
          acceptedAt: row.acceptedAt,
          deviceId: row.deviceId,
          timezone: row.timezone,
        ),
        syncMetadata: SyncMetadata(
          id: row.id,
          userId: row.userId,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          deletedAt: row.deletedAt,
          syncStatus: SyncStatus.fromName(row.syncStatus),
        ),
      );

  static PrivacyConsentDto fromSupabase(Map<String, dynamic> row) {
    DateTime date(String key) => DateTime.parse(row[key] as String);
    final userId = row['user_id'] as String;
    return PrivacyConsentDto(
      consent: PrivacyConsent(
        id: row['id'] as String,
        userId: userId,
        termsVersion: row['terms_version'] as String,
        privacyVersion: row['privacy_version'] as String,
        acceptedAt: date('accepted_at'),
        deviceId: row['device_id'] as String,
        timezone: row['timezone'] as String,
      ),
      syncMetadata: SyncMetadata(
        id: row['id'] as String,
        userId: userId,
        createdAt: date('created_at'),
        updatedAt: date('updated_at'),
        deletedAt: row['deleted_at'] == null ? null : date('deleted_at'),
        syncStatus: SyncStatus.synced,
      ),
    );
  }
}
