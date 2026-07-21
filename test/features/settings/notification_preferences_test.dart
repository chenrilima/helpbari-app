import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';

void main() {
  test(
    'legacy booleans backfill conservatively without enabling new categories',
    () {
      final preferences = NotificationPreferences.legacy(
        vitamins: true,
        medications: false,
        appointments: true,
      );

      expect(preferences.globalEnabled, isTrue);
      expect(
        preferences.categoryEnabled(NotificationCategory.treatment),
        isTrue,
      );
      expect(
        preferences.categoryEnabled(NotificationCategory.appointments),
        isTrue,
      );
      expect(preferences.categoryEnabled(NotificationCategory.water), isFalse);
      expect(preferences.categoryEnabled(NotificationCategory.meals), isFalse);
      expect(preferences.categoryEnabled(NotificationCategory.weight), isFalse);
    },
  );

  test('global, category, item and time gates remain separate', () {
    const time = NotificationTimePreference(
      id: 'water-morning',
      category: NotificationCategory.water,
      kind: NotificationScheduleKind.daily,
      hour: 8,
      minute: 30,
      timeZone: 'America/Sao_Paulo',
      enabled: false,
    );
    final base = const NotificationPreferences(
      globalEnabled: true,
      categories: {NotificationCategory.water: true},
    ).putTime(time);

    expect(base.categoryEnabled(NotificationCategory.water), isTrue);
    expect(base.itemEnabled(NotificationCategory.water, 'water'), isTrue);
    expect(base.timeEnabled(time), isFalse);

    final itemOff = base.setItem(NotificationCategory.water, 'water', false);
    expect(itemOff.categoryEnabled(NotificationCategory.water), isTrue);
    expect(itemOff.itemEnabled(NotificationCategory.water, 'water'), isFalse);

    final globalOff = itemOff.copyWith(globalEnabled: false);
    expect(globalOff.categories[NotificationCategory.water], isTrue);
    expect(globalOff.globalEnabled, isFalse);
  });

  test('serialized preferences preserve item and weekly time choices', () {
    final original = const NotificationPreferences(
      globalEnabled: true,
      categories: {NotificationCategory.weight: true},
      items: {'weight:scale-a': false},
      times: [
        NotificationTimePreference(
          id: 'weight-weekly',
          category: NotificationCategory.weight,
          kind: NotificationScheduleKind.weekly,
          itemId: 'scale-a',
          hour: 7,
          minute: 15,
          timeZone: 'America/Sao_Paulo',
          isoWeekday: DateTime.monday,
        ),
      ],
    );

    final restored = NotificationPreferences.fromJson(original.toJson())!;

    expect(restored.items['weight:scale-a'], isFalse);
    expect(restored.times.single.isoWeekday, DateTime.monday);
    expect(restored.times.single.timeZone, 'America/Sao_Paulo');
  });
}
