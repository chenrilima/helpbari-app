import '../domain/models/models.dart';

class BariaContextCache {
  BariaContext? _value;

  BariaContext? read({
    required String userId,
    required DateTime now,
    required Duration maxAge,
  }) {
    final value = _value;
    if (value == null || value.userId != userId) return null;
    if (now.difference(value.generatedAt) >= maxAge) return null;
    return value;
  }

  void write(BariaContext context) => _value = context;
  void invalidate() => _value = null;
}
