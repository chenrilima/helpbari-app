class DailySummaryItem {
  const DailySummaryItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.date,
  });

  final String id;
  final String title;
  final String? subtitle;
  final DateTime? date;

  bool get hasSubtitle => subtitle != null && subtitle!.isNotEmpty;
}
