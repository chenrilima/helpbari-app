import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../../../../core/sync/sync.dart';

class MedicalPrescriptionUseCases {
  const MedicalPrescriptionUseCases(this._repository);

  final MedicalPrescriptionRepository _repository;

  Stream<List<MedicalPrescription>> watchPrescriptions() =>
      _repository.watchAll();
  Future<List<MedicalPrescription>> getAll() => _repository.getAll();
  Future<MedicalPrescription?> getById(String id) => _repository.getById(id);
  Future<void> create(MedicalPrescription value) => _repository.save(value);
  Future<void> update(MedicalPrescription value) => _repository.save(value);

  Future<void> confirm(MedicalPrescription value, DateTime now) {
    if (value.activeItems.isEmpty) {
      throw const FormatException('Adicione ao menos um item à prescrição.');
    }
    if (value.activeItems.any((item) => item.name.trim().isEmpty)) {
      throw const FormatException('Revise o nome de todos os itens.');
    }
    return _repository.save(
      value.copyWith(
        status: MedicalPrescriptionStatus.confirmed,
        updatedAt: now,
        syncStatus: SyncStatus.pendingUpdate,
        items: value.items
            .map(
              (item) => item.copyWith(
                reviewStatus: PrescriptionReviewStatus.confirmed,
                updatedAt: now,
                syncStatus: SyncStatus.pendingUpdate,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Future<void> archive(MedicalPrescription value, DateTime now) =>
      _repository.save(
        value.copyWith(
          status: MedicalPrescriptionStatus.archived,
          updatedAt: now,
          syncStatus: SyncStatus.pendingUpdate,
        ),
      );

  Future<void> delete(String id) => _repository.delete(id);

  Future<MedicalPrescription?> findPotentialDuplicate(
    MedicalPrescription candidate,
  ) async {
    final sourceId = candidate.sourceDocumentId?.trim();
    final signature = _signature(candidate);
    for (final current in await _repository.getAll()) {
      if (current.id == candidate.id) continue;
      if (sourceId != null &&
          sourceId.isNotEmpty &&
          current.sourceDocumentId == sourceId) {
        return current;
      }
      if (current.status == MedicalPrescriptionStatus.confirmed &&
          _signature(current) == signature) {
        return current;
      }
    }
    return null;
  }

  String _signature(MedicalPrescription value) {
    final names =
        value.activeItems.map((item) => _normalize(item.name)).toList()..sort();
    final day = value.prescribedAt.toIso8601String().substring(0, 10);
    return '$day|${_normalize(value.professionalName ?? '')}|${names.join(',')}';
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
