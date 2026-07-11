class WaterLocalMigrationReport {
  const WaterLocalMigrationReport({
    required this.read,
    required this.imported,
    required this.updated,
    required this.ignored,
    required this.invalid,
    required this.anonymous,
    required this.checksum,
  });

  final int read;
  final int imported;
  final int updated;
  final int ignored;
  final int invalid;
  final int anonymous;
  final String checksum;

  int get valid => read - invalid;

  Map<String, Object> toJson() {
    return {
      'read': read,
      'imported': imported,
      'updated': updated,
      'ignored': ignored,
      'invalid': invalid,
      'anonymous': anonymous,
      'checksum': checksum,
    };
  }
}
