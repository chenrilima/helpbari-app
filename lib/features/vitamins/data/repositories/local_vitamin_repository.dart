import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_vitamin_datasource.dart';
import '../dtos/vitamin_dto.dart';

class LocalVitaminRepository implements VitaminRepository {
  const LocalVitaminRepository(this._datasource);

  final LocalVitaminDatasource _datasource;

  @override
  Future<List<Vitamin>> getAll() async {
    final vitamins = await _datasource.getAll();

    return vitamins.map((vitamin) => vitamin.toEntity()).toList();
  }

  @override
  Future<void> save(Vitamin vitamin) {
    return _datasource.save(
      VitaminDto.fromEntity(vitamin, now: DateTime.now()),
    );
  }

  @override
  Future<void> update(Vitamin vitamin) {
    return _datasource.save(
      VitaminDto.fromEntity(vitamin, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}
