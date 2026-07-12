import 'dart:convert';

enum NotificationSource {
  vitamin,
  medication,
  appointment,
  push;

  static NotificationSource? tryParse(String value) => NotificationSource.values
      .where((source) => source.name == value)
      .firstOrNull;
}

class LocalNotificationPayload {
  const LocalNotificationPayload({
    required this.source,
    required this.entityId,
    required this.userId,
    this.action = 'open',
    this.data = const <String, String>{},
  });

  final NotificationSource source;
  final String entityId;
  final String userId;
  final String action;
  final Map<String, String> data;

  String encode() {
    return jsonEncode(<String, Object>{
      'source': source.name,
      'entityId': entityId,
      'userId': userId,
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
      final userId = json['userId'];
      final data = json['data'];

      if (entityId is! String ||
          entityId.isEmpty ||
          source is! String ||
          userId is! String ||
          userId.isEmpty) {
        return null;
      }
      final parsedSource = NotificationSource.tryParse(source);
      if (parsedSource == null) return null;

      return LocalNotificationPayload(
        source: parsedSource,
        entityId: entityId,
        userId: userId,
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
