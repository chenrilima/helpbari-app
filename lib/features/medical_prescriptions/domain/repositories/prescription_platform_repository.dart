import '../entities/entities.dart';

abstract interface class PrescriptionPlatformRepository {
  Future<PrescriptionVersion> createDraftVersion({
    required MedicalPrescription snapshot,
    String? sourceProcessingId,
  });

  Future<PrescriptionVersion> submitForReview(
    String versionId, {
    String actor = 'patient',
  });

  Future<PrescriptionVersion> confirmVersion({
    required String versionId,
    required String actor,
    required Map<String, String> fieldDecisions,
  });

  Future<PrescriptionVersion> rejectVersion({
    required String versionId,
    required String actor,
    required Map<String, String> fieldDecisions,
    String? note,
  });

  Future<PrescriptionVersion> archiveVersion(String versionId);

  Future<List<PrescriptionVersion>> history(String prescriptionId);

  Future<List<TreatmentProposal>> proposals(String prescriptionId);

  Future<List<TreatmentProposal>> createProposals(String versionId);

  Future<void> dismissProposal(String proposalId);

  Future<PrescriptionRoutineLink> confirmProposal({
    required String proposalId,
    required TreatmentProposalDecision decision,
    String? targetRoutineId,
  });
}
