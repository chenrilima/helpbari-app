class WaterLocalConsistencyReport {
  const WaterLocalConsistencyReport({
    required this.usersAnalyzed,
    required this.legacyRecords,
    required this.driftRecords,
    required this.missingInDrift,
    required this.extraInDrift,
    required this.divergent,
    required this.consistent,
    required this.checksums,
    required this.issues,
  });

  final List<String> usersAnalyzed;
  final int legacyRecords;
  final int driftRecords;
  final int missingInDrift;
  final int extraInDrift;
  final int divergent;
  final bool consistent;
  final Map<String, WaterUserChecksums> checksums;
  final List<WaterConsistencyIssue> issues;

  Map<String, Object> toJson() => {
    'usersAnalyzed': usersAnalyzed,
    'legacyRecords': legacyRecords,
    'driftRecords': driftRecords,
    'missingInDrift': missingInDrift,
    'extraInDrift': extraInDrift,
    'divergent': divergent,
    'consistent': consistent,
    'checksums': checksums.map(
      (userId, value) => MapEntry(userId, value.toJson()),
    ),
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class WaterUserChecksums {
  const WaterUserChecksums({required this.legacy, required this.drift});

  final String legacy;
  final String drift;

  bool get matches => legacy == drift;

  Map<String, Object> toJson() => {
    'legacy': legacy,
    'drift': drift,
    'matches': matches,
  };
}

enum WaterConsistencyIssueType {
  missingInDrift,
  extraInDrift,
  contentDivergent,
  tombstoneDivergent,
  syncStatusDivergent,
}

class WaterConsistencyIssue {
  const WaterConsistencyIssue({
    required this.userId,
    required this.recordId,
    required this.types,
  });

  final String userId;
  final String recordId;
  final List<WaterConsistencyIssueType> types;

  Map<String, Object> toJson() => {
    'userId': userId,
    'recordId': recordId,
    'types': types.map((type) => type.name).toList(),
  };
}
