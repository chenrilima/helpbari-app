enum NotificationCategory { treatment, appointments, water, meals, weight }

enum NotificationScheduleKind { daily, weekly, appointmentLead }

final class NotificationTimePreference {
  const NotificationTimePreference({
    required this.id,
    required this.category,
    required this.kind,
    required this.hour,
    required this.minute,
    required this.timeZone,
    this.itemId,
    this.isoWeekday,
    this.leadMinutes,
    this.enabled = true,
  });

  final String id;
  final NotificationCategory category;
  final NotificationScheduleKind kind;
  final String? itemId;
  final int hour;
  final int minute;
  final String timeZone;
  final int? isoWeekday;
  final int? leadMinutes;
  final bool enabled;

  bool get isValid =>
      id.isNotEmpty &&
      hour >= 0 &&
      hour <= 23 &&
      minute >= 0 &&
      minute <= 59 &&
      timeZone.isNotEmpty &&
      (isoWeekday == null || (isoWeekday! >= 1 && isoWeekday! <= 7)) &&
      (leadMinutes == null || leadMinutes! >= 0);

  NotificationTimePreference copyWith({bool? enabled}) =>
      NotificationTimePreference(
        id: id,
        category: category,
        kind: kind,
        itemId: itemId,
        hour: hour,
        minute: minute,
        timeZone: timeZone,
        isoWeekday: isoWeekday,
        leadMinutes: leadMinutes,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'kind': kind.name,
    'itemId': itemId,
    'hour': hour,
    'minute': minute,
    'timeZone': timeZone,
    'isoWeekday': isoWeekday,
    'leadMinutes': leadMinutes,
    'enabled': enabled,
  };

  static NotificationTimePreference? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final category = NotificationCategory.values
        .where((item) => item.name == value['category'])
        .firstOrNull;
    final kind = NotificationScheduleKind.values
        .where((item) => item.name == value['kind'])
        .firstOrNull;
    final result = category == null || kind == null
        ? null
        : NotificationTimePreference(
            id: value['id'] as String? ?? '',
            category: category,
            kind: kind,
            itemId: value['itemId'] as String?,
            hour: value['hour'] as int? ?? -1,
            minute: value['minute'] as int? ?? -1,
            timeZone: value['timeZone'] as String? ?? '',
            isoWeekday: value['isoWeekday'] as int?,
            leadMinutes: value['leadMinutes'] as int?,
            enabled: value['enabled'] as bool? ?? true,
          );
    return result?.isValid == true ? result : null;
  }
}

final class NotificationPreferences {
  const NotificationPreferences({
    this.version = currentVersion,
    required this.globalEnabled,
    required this.categories,
    this.items = const <String, bool>{},
    this.times = const <NotificationTimePreference>[],
  });

  static const int currentVersion = 1;
  final int version;
  final bool globalEnabled;
  final Map<NotificationCategory, bool> categories;
  final Map<String, bool> items;
  final List<NotificationTimePreference> times;

  bool categoryEnabled(NotificationCategory category) =>
      globalEnabled && (categories[category] ?? false);

  bool itemEnabled(NotificationCategory category, String itemId) =>
      categoryEnabled(category) && (items[_itemKey(category, itemId)] ?? true);

  bool timeEnabled(NotificationTimePreference time) =>
      itemEnabled(time.category, time.itemId ?? time.category.name) &&
      time.enabled;

  NotificationPreferences copyWith({
    bool? globalEnabled,
    Map<NotificationCategory, bool>? categories,
    Map<String, bool>? items,
    List<NotificationTimePreference>? times,
  }) => NotificationPreferences(
    globalEnabled: globalEnabled ?? this.globalEnabled,
    categories: categories ?? this.categories,
    items: items ?? this.items,
    times: times ?? this.times,
  );

  NotificationPreferences setCategory(
    NotificationCategory category,
    bool enabled,
  ) => copyWith(categories: {...categories, category: enabled});

  NotificationPreferences setItem(
    NotificationCategory category,
    String itemId,
    bool enabled,
  ) => copyWith(items: {...items, _itemKey(category, itemId): enabled});

  NotificationPreferences putTime(NotificationTimePreference preference) {
    if (!preference.isValid) throw StateError('Invalid notification time.');
    return copyWith(
      times: [...times.where((item) => item.id != preference.id), preference],
    );
  }

  NotificationPreferences removeTime(String id) =>
      copyWith(times: times.where((item) => item.id != id).toList());

  Map<String, Object?> toJson() => {
    'version': version,
    'globalEnabled': globalEnabled,
    'categories': {
      for (final category in NotificationCategory.values)
        category.name: categories[category] ?? false,
    },
    'items': items,
    'times': times.map((item) => item.toJson()).toList(),
  };

  static NotificationPreferences legacy({
    required bool vitamins,
    required bool medications,
    required bool appointments,
  }) => NotificationPreferences(
    globalEnabled: vitamins || medications || appointments,
    categories: {
      NotificationCategory.treatment: vitamins || medications,
      NotificationCategory.appointments: appointments,
      NotificationCategory.water: false,
      NotificationCategory.meals: false,
      NotificationCategory.weight: false,
    },
  );

  static NotificationPreferences? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final rawCategories = value['categories'];
    final rawItems = value['items'];
    final rawTimes = value['times'];
    if (rawCategories is! Map<String, dynamic>) return null;
    return NotificationPreferences(
      globalEnabled: value['globalEnabled'] as bool? ?? false,
      categories: {
        for (final category in NotificationCategory.values)
          category: rawCategories[category.name] as bool? ?? false,
      },
      items: rawItems is Map<String, dynamic>
          ? rawItems.map((key, value) => MapEntry(key, value == true))
          : const {},
      times: rawTimes is List
          ? rawTimes
                .map(NotificationTimePreference.fromJson)
                .whereType<NotificationTimePreference>()
                .toList()
          : const [],
    );
  }

  static String _itemKey(NotificationCategory category, String itemId) =>
      '${category.name}:$itemId';
}
