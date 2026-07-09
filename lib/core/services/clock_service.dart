abstract interface class ClockService {
  DateTime now();
}

class AppClockService implements ClockService {
  const AppClockService();

  @override
  DateTime now() {
    return DateTime.now();
  }
}
