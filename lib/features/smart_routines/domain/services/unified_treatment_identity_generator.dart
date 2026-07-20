import 'package:uuid/uuid.dart';

enum UnifiedTreatmentLegacySource { medication, vitamin }

enum UnifiedTreatmentTargetEntity {
  mapping,
  routine,
  plan,
  schedule,
  occurrence,
  adherenceEvent,
  logMapping,
}

final class UnifiedTreatmentIdentityGenerator {
  const UnifiedTreatmentIdentityGenerator();

  static const schemaVersion = 1;
  static const namespace = 'cf354d63-2e50-5af5-a987-a8d778d07d5d';
  static const Uuid _uuid = Uuid();

  String generate({
    required String userId,
    required UnifiedTreatmentLegacySource source,
    required String legacyId,
    required UnifiedTreatmentTargetEntity target,
  }) => _uuid.v5(
    namespace,
    canonicalName(
      userId: userId,
      source: source,
      legacyId: legacyId,
      target: target,
    ),
  );

  String canonicalName({
    required String userId,
    required UnifiedTreatmentLegacySource source,
    required String legacyId,
    required UnifiedTreatmentTargetEntity target,
  }) =>
      'v$schemaVersion|user:$userId|source:${source.name}'
      '|legacy:$legacyId|target:${target.name}';
}
