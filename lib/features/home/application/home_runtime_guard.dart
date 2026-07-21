class HomeRuntimeGuard {
  final Set<String> _inFlight = <String>{};

  bool begin(String key) => _inFlight.add(key);

  void complete(String key) => _inFlight.remove(key);

  bool isInFlight(String key) => _inFlight.contains(key);
}

class ClinicalDayRefreshPolicy {
  const ClinicalDayRefreshPolicy();

  bool shouldRefresh({
    required DateTime snapshotDate,
    required DateTime now,
    required String snapshotTimeZone,
    required String currentTimeZone,
  }) {
    final currentDate = DateTime(now.year, now.month, now.day);
    final normalizedSnapshot = DateTime(
      snapshotDate.year,
      snapshotDate.month,
      snapshotDate.day,
    );
    return normalizedSnapshot != currentDate ||
        snapshotTimeZone != currentTimeZone;
  }

  Duration untilNextDay(DateTime now) {
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final duration = nextDay.difference(now);
    return duration.isNegative || duration == Duration.zero
        ? const Duration(seconds: 1)
        : duration;
  }
}
