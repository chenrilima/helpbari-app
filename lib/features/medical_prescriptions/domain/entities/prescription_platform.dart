import '../../../../core/sync/sync.dart';
import 'medical_prescription.dart';

enum PrescriptionVersionStatus { draft, requiresReview, confirmed, archived }

enum PrescriptionReviewDecision { submitted, confirmed, rejected }

enum TreatmentProposalDecision {
  pending,
  createRoutine,
  linkExisting,
  createRevision,
  dismissed,
}

class PrescriptionVersion {
  const PrescriptionVersion({
    required this.id,
    required this.prescriptionId,
    required this.userId,
    required this.revision,
    required this.status,
    required this.snapshot,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.sourceProcessingId,
    this.submittedAt,
    this.confirmedAt,
  });

  final String id;
  final String prescriptionId;
  final String userId;
  final int revision;
  final PrescriptionVersionStatus status;
  final MedicalPrescription snapshot;
  final String? sourceProcessingId;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
}

class PrescriptionReview {
  const PrescriptionReview({
    required this.id,
    required this.prescriptionId,
    required this.versionId,
    required this.userId,
    required this.decision,
    required this.actor,
    required this.fieldDecisions,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String prescriptionId;
  final String versionId;
  final String userId;
  final PrescriptionReviewDecision decision;
  final String actor;
  final Map<String, String> fieldDecisions;
  final String? note;
  final DateTime createdAt;
}

class TreatmentProposal {
  const TreatmentProposal({
    required this.id,
    required this.userId,
    required this.prescriptionId,
    required this.prescriptionVersionId,
    required this.prescriptionItemId,
    required this.decision,
    required this.draft,
    required this.createdAt,
    this.targetRoutineId,
    this.resultingPlanId,
    this.confirmedAt,
  });

  final String id;
  final String userId;
  final String prescriptionId;
  final String prescriptionVersionId;
  final String prescriptionItemId;
  final TreatmentProposalDecision decision;
  final Map<String, Object?> draft;
  final String? targetRoutineId;
  final String? resultingPlanId;
  final DateTime? confirmedAt;
  final DateTime createdAt;
}

class PrescriptionRoutineLink {
  const PrescriptionRoutineLink({
    required this.id,
    required this.userId,
    required this.prescriptionId,
    required this.prescriptionVersionId,
    required this.prescriptionItemId,
    required this.routineId,
    required this.planId,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String prescriptionId;
  final String prescriptionVersionId;
  final String prescriptionItemId;
  final String routineId;
  final String planId;
  final bool active;
  final DateTime createdAt;
}
