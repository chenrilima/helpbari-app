import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../value_objects/value_objects.dart';

class VitaminUseCases {
  const VitaminUseCases(this._repository);

  final VitaminRepository _repository;

  Future<List<Vitamin>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Vitamin vitamin) {
    return _repository.save(vitamin);
  }

  Future<void> update(Vitamin vitamin) {
    return _repository.update(vitamin);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<int> getPendingCount() async {
    final vitamins = await _repository.getAll();

    return vitamins.where((vitamin) => vitamin.isPending).length;
  }

  Future<void> markAsTaken(String id) async {
    final vitamins = await _repository.getAll();

    final vitamin = vitamins.where((item) => item.id == id).firstOrNull;

    if (vitamin == null) return;

    await _repository.update(vitamin.markAsTaken());
  }

  Future<void> markAsSkipped(String id) async {
    final vitamins = await _repository.getAll();

    final vitamin = vitamins.where((item) => item.id == id).firstOrNull;

    if (vitamin == null) return;

    await _repository.update(vitamin.markAsSkipped());
  }

  Future<void> resetStatus(String id) async {
    final vitamins = await _repository.getAll();

    final vitamin = vitamins.where((item) => item.id == id).firstOrNull;

    if (vitamin == null) return;

    await _repository.update(vitamin.copyWith(status: VitaminStatus.pending));
  }
}
