import '../entities/entities.dart';

abstract interface class PrescriptionPlatformRepository {
  Future<PrescriptionVersion> createDraftVersion({
    required MedicalPrescription snapshot,
    String? sourceProcessingId,
  });

  Future<PrescriptionVersion> submitForReview(String versionId);

  Future<PrescriptionVersion> confirmVersion({
    required String versionId,
    required String actor,
    required Map<String, String> fieldDecisions,
  });

  Future<List<PrescriptionVersion>> history(String prescriptionId);

  Future<List<TreatmentProposal>> proposals(String prescriptionId);

  Future<List<TreatmentProposal>> createProposals(String versionId);

  Future<PrescriptionRoutineLink> confirmProposal({
    required String proposalId,
    required TreatmentProposalDecision decision,
    String? targetRoutineId,
  });
}
