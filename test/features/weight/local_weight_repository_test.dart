import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/weight/data/datasources/local_weight_datasource.dart';
import 'package:helpbari/features/weight/data/repositories/local_weight_repository.dart';
import 'package:helpbari/features/weight/domain/entities/entities.dart';
import 'package:helpbari/features/weight/domain/value_objects/value_objects.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists weight records sorted by recorded date descending', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();

    await repository.register(_record(id: 'older', date: DateTime(2026, 7, 1)));
    await repository.register(_record(id: 'newer', date: DateTime(2026, 7, 9)));

    final history = await repository.getHistory();

    expect(history.map((record) => record.id), ['newer', 'older']);
  });

  test('soft deletes weight record from history', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();

    await repository.register(_record(id: 'weight-1'));
    await repository.delete('weight-1');

    final history = await repository.getHistory();

    expect(history, isEmpty);
  });
}

Future<LocalWeightRepository> _repository() async {
  final preferences = await SharedPreferences.getInstance();
  final storage = SharedPreferencesLocalStorageService(preferences);
  final database = SharedPreferencesLocalDatabase(storage);

  return LocalWeightRepository(
    LocalWeightDatasource(database: database, clock: const _FixedClock()),
  );
}

WeightRecord _record({required String id, DateTime? date}) {
  return WeightRecord(
    id: id,
    weight: WeightValue.create(98.5)!,
    recordedAt: RecordedAt(
      date ?? DateTime(2026, 7, 9),
      clock: const _FixedClock(),
    ),
    notes: Notes.create('Registro local'),
  );
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}
