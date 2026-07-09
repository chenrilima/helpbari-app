import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/water/data/datasources/local_water_datasource.dart';
import 'package:helpbari/features/water/data/repositories/local_water_repository.dart';
import 'package:helpbari/features/water/domain/entities/entities.dart';
import 'package:helpbari/features/water/domain/value_objects/value_objects.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists water records sorted by recorded date descending', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();

    await repository.save(_record(id: 'older', date: DateTime(2026, 7, 1)));
    await repository.save(_record(id: 'newer', date: DateTime(2026, 7, 9)));

    final history = await repository.getHistory();

    expect(history.map((record) => record.id), ['newer', 'older']);
    expect(history.first.amount.valueInMl, 250);
  });
}

Future<LocalWaterRepository> _repository() async {
  final preferences = await SharedPreferences.getInstance();
  final storage = SharedPreferencesLocalStorageService(preferences);
  final database = SharedPreferencesLocalDatabase(storage);

  return LocalWaterRepository(
    LocalWaterDatasource(database: database, clock: const _FixedClock()),
  );
}

WaterRecord _record({required String id, DateTime? date}) {
  return WaterRecord(
    id: id,
    amount: WaterAmount.create(250)!,
    recordedAt: date ?? DateTime(2026, 7, 9),
    clock: const _FixedClock(),
  );
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}
