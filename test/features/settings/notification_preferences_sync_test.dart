import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/settings/data/dtos/settings_dto.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';

void main() {
  test(
    'sync payload round-trips the new authority and mirrors legacy booleans',
    () {
      final now = DateTime.utc(2026, 7, 23);
      final dto = SettingsDto.fromEntity(
        const AppSettings(
          id: 'settings-a',
          vitaminRemindersEnabled: true,
          medicationRemindersEnabled: true,
          appointmentRemindersEnabled: false,
          notificationPreferences: NotificationPreferences(
            globalEnabled: true,
            categories: {
              NotificationCategory.treatment: true,
              NotificationCategory.water: true,
            },
            items: {'treatment:routine-a': false},
          ),
        ),
        now: now,
        userId: 'user-a',
      );

      final payload = dto.toSupabase('user-a');
      final restored = SettingsDto.fromSupabase({
        ...payload,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).toEntity();

      expect(
        restored.effectiveNotificationPreferences.categoryEnabled(
          NotificationCategory.water,
        ),
        isTrue,
      );
      expect(
        restored.effectiveNotificationPreferences.itemEnabled(
          NotificationCategory.treatment,
          'routine-a',
        ),
        isFalse,
      );
    },
  );

  test('missing new payload falls back to legacy booleans', () {
    final now = DateTime.utc(2026, 7, 23);
    final entity = SettingsDto(
      id: 'settings-a',
      dailyWaterGoalMl: 2000,
      vitaminRemindersEnabled: false,
      medicationRemindersEnabled: true,
      appointmentRemindersEnabled: false,
      mealTrackingEnabled: true,
      treatmentTrackingEnabled: true,
      waterTrackingEnabled: true,
      weightTrackingEnabled: true,
      weightUnit: 'kg',
      syncMetadata: SyncMetadata(
        id: 'settings-a',
        userId: 'user-a',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ).toEntity();

    expect(
      entity.effectiveNotificationPreferences.categoryEnabled(
        NotificationCategory.treatment,
      ),
      isTrue,
    );
    expect(
      entity.effectiveNotificationPreferences.categoryEnabled(
        NotificationCategory.water,
      ),
      isFalse,
    );
  });
}
