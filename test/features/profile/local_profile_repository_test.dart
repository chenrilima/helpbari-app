import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/profile/data/datasources/local_profile_datasource.dart';
import 'package:helpbari/features/profile/data/repositories/local_profile_repository.dart';
import 'package:helpbari/features/profile/domain/entities/entities.dart';
import 'package:helpbari/features/profile/domain/value_objects/value_objects.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and reads profile from local storage', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();
    final profile = _profile(id: 'profile-1');

    await repository.saveProfile(profile);

    final saved = await repository.getProfile();

    expect(saved?.id, 'profile-1');
    expect(saved?.name, 'Carlos');
    expect(saved?.height.valueInCentimeters, 178);
    expect(saved?.initialWeight.value, 112.4);
  });

  test('soft deletes profile from active reads', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();
    final profile = _profile(id: 'profile-1');

    await repository.saveProfile(profile);
    await repository.deleteProfile(profile);

    final saved = await repository.getProfile();

    expect(saved, isNull);
  });
}

Future<LocalProfileRepository> _repository() async {
  final preferences = await SharedPreferences.getInstance();
  final storage = SharedPreferencesLocalStorageService(preferences);
  final database = SharedPreferencesLocalDatabase(storage);

  return LocalProfileRepository(
    LocalProfileDatasource(database: database, clock: const _FixedClock()),
  );
}

Profile _profile({required String id}) {
  final height = Height.create(178)!;
  final initialWeight = Weight.create(112.4)!;
  final targetWeight = Weight.create(82)!;

  return Profile(
    id: id,
    name: 'Carlos',
    email: 'carlos@example.com',
    createdAt: AppDate(DateTime(2026, 1, 1), clock: const _FixedClock()),
    birthDate: AppDate(DateTime(1990, 5, 20), clock: const _FixedClock()),
    height: height,
    initialWeight: initialWeight,
    targetWeight: targetWeight,
    surgeryDate: AppDate(DateTime(2025, 1, 10), clock: const _FixedClock()),
    surgeryType: SurgeryType.sleeve,
    clock: const _FixedClock(),
  );
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}
