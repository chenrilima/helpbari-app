enum ChartPeriod {
  sevenDays,
  thirtyDays,
  threeMonths,
  sixMonths,
  oneYear;

  String get label {
    return switch (this) {
      ChartPeriod.sevenDays => '7 dias',
      ChartPeriod.thirtyDays => '30 dias',
      ChartPeriod.threeMonths => '3 meses',
      ChartPeriod.sixMonths => '6 meses',
      ChartPeriod.oneYear => '1 ano',
    };
  }

  int get days {
    return switch (this) {
      ChartPeriod.sevenDays => 7,
      ChartPeriod.thirtyDays => 30,
      ChartPeriod.threeMonths => 90,
      ChartPeriod.sixMonths => 180,
      ChartPeriod.oneYear => 365,
    };
  }

  DateTime startDate(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return today.subtract(Duration(days: days - 1));
  }
}
