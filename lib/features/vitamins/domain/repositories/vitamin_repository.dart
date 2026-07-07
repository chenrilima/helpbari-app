import '../entities/entities.dart';

abstract interface class VitaminRepository {
  Future<List<Vitamin>> getAll();

  Future<void> save(Vitamin vitamin);

  Future<void> update(Vitamin vitamin);

  Future<void> delete(String id);
}
