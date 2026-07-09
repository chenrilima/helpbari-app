import 'dart:convert';

enum NotificationSource {
  vitamin,
  medication,
  appointment,
  push;

  static NotificationSource fromName(String value) {
    return NotificationSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => NotificationSource.push,
    );
  }
}

class LocalNotificationPayload {
  const LocalNotificationPayload({
    required this.source,
    required this.entityId,
    this.action = 'open',
    this.data = const <String, String>{},
  });

  final NotificationSource source;
  final String entityId;
  final String action;
  final Map<String, String> data;

  String encode() {
    return jsonEncode(<String, Object>{
      'source': source.name,
      'entityId': entityId,
      'action': action,
      'data': data,
    });
  }

  static LocalNotificationPayload? decode(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      final json = jsonDecode(value);

      if (json is! Map<String, Object?>) return null;

      final entityId = json['entityId'];
      final source = json['source'];
      final action = json['action'];
      final data = json['data'];

      if (entityId is! String || source is! String) return null;

      return LocalNotificationPayload(
        source: NotificationSource.fromName(source),
        entityId: entityId,
        action: action is String ? action : 'open',
        data: data is Map<String, Object?>
            ? data.map((key, value) => MapEntry(key, value?.toString() ?? ''))
            : const <String, String>{},
      );
    } on FormatException {
      return null;
    }
  }
}
