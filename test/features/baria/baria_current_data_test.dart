import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/features/baria/data/repositories/fake_baria_repository.dart';
import 'package:helpbari/features/medications/domain/entities/entities.dart';
import 'package:helpbari/features/medications/domain/repositories/repositories.dart';
import 'package:helpbari/features/medications/domain/usecases/medication_use_cases.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/vitamins/domain/entities/entities.dart';
import 'package:helpbari/features/vitamins/domain/repositories/repositories.dart';
import 'package:helpbari/features/vitamins/domain/usecases/vitamin_use_cases.dart';
import 'package:helpbari/features/water/domain/entities/entities.dart';
import 'package:helpbari/features/water/domain/repositories/water_repository.dart';
import 'package:helpbari/features/water/domain/usecases/water_use_cases.dart';
import 'package:helpbari/features/water/domain/value_objects/value_objects.dart';

void main() {
  const clock = _Clock();
  late _WaterRepository water;
  late _SettingsRepository settings;
  late FakeBariaRepository baria;

  setUp(() {
    water = _WaterRepository();
    settings = _SettingsRepository(
      const AppSettings(id: 'user-a', dailyWaterGoalMl: 2500),
    );
    baria = _baria(water: water, settings: settings, clock: clock);
  });

  test(
    'uses the current 2500 ml Settings goal with offline Water data',
    () async {
      await water.create(_record('one', 1000, clock));

      final response = await baria.generateResponse('Como está minha água?');

      expect(response, contains('1000 ml de 2500 ml'));
      expect(response, contains('40%'));
      expect(response, contains('não substituem orientação médica'));
    },
  );

  test('reflects create, update and delete without recreating BarIA', () async {
    await water.create(_record('one', 500, clock));
    expect(await baria.generateResponse('água'), contains('500 ml de 2500 ml'));

    await water.update(_record('one', 900, clock));
    expect(await baria.generateResponse('água'), contains('900 ml de 2500 ml'));

    await water.delete('one');
    expect(await baria.generateResponse('água'), contains('0 ml de 2500 ml'));
  });

  test(
    'reflects remote pull replacement and a changed Settings goal',
    () async {
      water.records = [_record('remote', 1250, clock)];
      await settings.saveSettings(
        const AppSettings(id: 'user-a', dailyWaterGoalMl: 3000),
      );

      final response = await baria.generateResponse('resumo');

      expect(response, contains('Água: 1250/3000 ml'));
    },
  );

  test(
    'separate authenticated user repositories never leak Water data',
    () async {
      await water.create(_record('user-a-water', 750, clock));
      final userBWater = _WaterRepository();
      final userB = _baria(
        water: userBWater,
        settings: _SettingsRepository(
          const AppSettings(id: 'user-b', dailyWaterGoalMl: 1800),
        ),
        clock: clock,
      );

      expect(
        await baria.generateResponse('água'),
        contains('750 ml de 2500 ml'),
      );
      expect(await userB.generateResponse('água'), contains('0 ml de 1800 ml'));
    },
  );
}

FakeBariaRepository _baria({
  required _WaterRepository water,
  required _SettingsRepository settings,
  required ClockService clock,
}) => FakeBariaRepository(
  waterUseCases: WaterUseCases(water, clock),
  settingsUseCases: SettingsUseCases(settings),
  vitaminUseCases: VitaminUseCases(_VitaminRepository()),
  medicationUseCases: MedicationUseCases(_MedicationRepository()),
  healthScore: 80,
);

WaterRecord _record(String id, int amount, ClockService clock) => WaterRecord(
  id: id,
  amount: WaterAmount.create(amount)!,
  recordedAt: clock.now(),
  clock: clock,
);

class _Clock implements ClockService {
  const _Clock();

  @override
  DateTime now() => DateTime(2026, 7, 11, 12);
}

class _WaterRepository implements WaterRepository {
  List<WaterRecord> records = [];

  @override
  Future<List<WaterRecord>> getHistory() async => List.unmodifiable(records);

  @override
  Future<void> create(WaterRecord record) async => records.add(record);

  @override
  Future<void> update(WaterRecord record) async {
    final index = records.indexWhere((item) => item.id == record.id);
    if (index >= 0) records[index] = record;
  }

  @override
  Future<void> delete(String id) async {
    records.removeWhere((record) => record.id == id);
  }
}

class _SettingsRepository implements SettingsRepository {
  _SettingsRepository(this.settings);
  AppSettings settings;

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    this.settings = settings;
  }
}

class _VitaminRepository implements VitaminRepository {
  @override
  Future<List<Vitamin>> getAll() async => [];
  @override
  Future<void> save(Vitamin vitamin) async {}
  @override
  Future<void> update(Vitamin vitamin) async {}
  @override
  Future<void> delete(String id) async {}
}

class _MedicationRepository implements MedicationRepository {
  @override
  Future<List<Medication>> getAll() async => [];
  @override
  Future<void> save(Medication medication) async {}
  @override
  Future<void> update(Medication medication) async {}
  @override
  Future<void> delete(String id) async {}
}
