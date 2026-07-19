import '../../../../core/sync/sync.dart';

enum MedicalPrescriptionStatus {
  draft,
  requiresReview,
  confirmed,
  archived,
  canceled,
}

enum PrescriptionItemType { medication, vitamin, supplement, other }

enum PrescriptionFrequencyType {
  onceDaily,
  timesDaily,
  specificTimes,
  everyHours,
  specificWeekdays,
  weekly,
  monthly,
  everyDays,
  continuous,
  freeText,
}

enum PrescriptionReviewStatus { pending, reviewed, confirmed }

class MedicalPrescriptionItem {
  const MedicalPrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.userId,
    required this.itemType,
    required this.name,
    required this.reviewStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.dosageValue,
    this.dosageUnit,
    this.route,
    this.frequencyType,
    this.frequencyValue,
    this.frequencyUnit,
    this.scheduleTimes = const [],
    this.daysOfWeek = const [],
    this.intervalDays,
    this.startDate,
    this.endDate,
    this.durationValue,
    this.durationUnit,
    this.instructions,
    this.asNeeded = false,
    this.notes,
    this.confidence,
    this.fieldConfidences = const {},
    this.provenance = const {},
    this.linkedMedicationId,
    this.linkedVitaminId,
    this.deletedAt,
  });

  final String id;
  final String prescriptionId;
  final String userId;
  final PrescriptionItemType itemType;
  final String name;
  final double? dosageValue;
  final String? dosageUnit;
  final String? route;
  final PrescriptionFrequencyType? frequencyType;
  final int? frequencyValue;
  final String? frequencyUnit;
  final List<String> scheduleTimes;
  final List<int> daysOfWeek;
  final int? intervalDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? durationValue;
  final String? durationUnit;
  final String? instructions;
  final bool asNeeded;
  final String? notes;
  final double? confidence;
  final Map<String, double> fieldConfidences;
  final Map<String, String> provenance;
  final PrescriptionReviewStatus reviewStatus;
  final String? linkedMedicationId;
  final String? linkedVitaminId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get isLinked => linkedMedicationId != null || linkedVitaminId != null;

  MedicalPrescriptionItem copyWith({
    PrescriptionItemType? itemType,
    String? name,
    double? dosageValue,
    String? dosageUnit,
    String? route,
    PrescriptionFrequencyType? frequencyType,
    int? frequencyValue,
    String? frequencyUnit,
    List<String>? scheduleTimes,
    List<int>? daysOfWeek,
    int? intervalDays,
    DateTime? startDate,
    DateTime? endDate,
    int? durationValue,
    String? durationUnit,
    String? instructions,
    bool? asNeeded,
    String? notes,
    double? confidence,
    Map<String, double>? fieldConfidences,
    Map<String, String>? provenance,
    PrescriptionReviewStatus? reviewStatus,
    String? linkedMedicationId,
    String? linkedVitaminId,
    bool clearLinkedMedication = false,
    bool clearLinkedVitamin = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => MedicalPrescriptionItem(
    id: id,
    prescriptionId: prescriptionId,
    userId: userId,
    itemType: itemType ?? this.itemType,
    name: name ?? this.name,
    dosageValue: dosageValue ?? this.dosageValue,
    dosageUnit: dosageUnit ?? this.dosageUnit,
    route: route ?? this.route,
    frequencyType: frequencyType ?? this.frequencyType,
    frequencyValue: frequencyValue ?? this.frequencyValue,
    frequencyUnit: frequencyUnit ?? this.frequencyUnit,
    scheduleTimes: scheduleTimes ?? this.scheduleTimes,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    intervalDays: intervalDays ?? this.intervalDays,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    durationValue: durationValue ?? this.durationValue,
    durationUnit: durationUnit ?? this.durationUnit,
    instructions: instructions ?? this.instructions,
    asNeeded: asNeeded ?? this.asNeeded,
    notes: notes ?? this.notes,
    confidence: confidence ?? this.confidence,
    fieldConfidences: fieldConfidences ?? this.fieldConfidences,
    provenance: provenance ?? this.provenance,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    linkedMedicationId: clearLinkedMedication
        ? null
        : linkedMedicationId ?? this.linkedMedicationId,
    linkedVitaminId: clearLinkedVitamin
        ? null
        : linkedVitaminId ?? this.linkedVitaminId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

class MedicalPrescription {
  const MedicalPrescription({
    required this.id,
    required this.userId,
    required this.prescribedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.professionalName,
    this.professionalSpecialty,
    this.professionalRegistration,
    this.validUntil,
    this.notes,
    this.sourceDocumentId,
    this.items = const [],
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String? professionalName;
  final String? professionalSpecialty;
  final String? professionalRegistration;
  final DateTime prescribedAt;
  final DateTime? validUntil;
  final String? notes;
  final String? sourceDocumentId;
  final MedicalPrescriptionStatus status;
  final List<MedicalPrescriptionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  List<MedicalPrescriptionItem> get activeItems =>
      items.where((item) => item.deletedAt == null).toList(growable: false);
  int get linkedItemsCount => activeItems.where((item) => item.isLinked).length;
  bool get requiresReview =>
      status == MedicalPrescriptionStatus.requiresReview ||
      activeItems.any(
        (item) => item.reviewStatus == PrescriptionReviewStatus.pending,
      );

  MedicalPrescription copyWith({
    String? professionalName,
    String? professionalSpecialty,
    String? professionalRegistration,
    DateTime? prescribedAt,
    DateTime? validUntil,
    String? notes,
    String? sourceDocumentId,
    MedicalPrescriptionStatus? status,
    List<MedicalPrescriptionItem>? items,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => MedicalPrescription(
    id: id,
    userId: userId,
    professionalName: professionalName ?? this.professionalName,
    professionalSpecialty: professionalSpecialty ?? this.professionalSpecialty,
    professionalRegistration:
        professionalRegistration ?? this.professionalRegistration,
    prescribedAt: prescribedAt ?? this.prescribedAt,
    validUntil: validUntil ?? this.validUntil,
    notes: notes ?? this.notes,
    sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
    status: status ?? this.status,
    items: items ?? this.items,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
