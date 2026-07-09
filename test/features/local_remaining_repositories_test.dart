import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/appointments/data/datasources/local_appointment_datasource.dart';
import 'package:helpbari/features/appointments/data/repositories/local_appointment_repository.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/exams/data/datasources/local_exam_datasource.dart';
import 'package:helpbari/features/exams/data/repositories/local_exam_repository.dart';
import 'package:helpbari/features/exams/domain/entities/entities.dart';
import 'package:helpbari/features/exams/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/meals/data/datasources/local_meal_datasource.dart';
import 'package:helpbari/features/meals/data/repositories/local_meal_repository.dart';
import 'package:helpbari/features/meals/domain/entities/entities.dart';
import 'package:helpbari/features/meals/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/medications/data/datasources/local_medication_datasource.dart';
import 'package:helpbari/features/medications/data/repositories/local_medication_repository.dart';
import 'package:helpbari/features/medications/domain/entities/entities.dart';
import 'package:helpbari/features/medications/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/settings/data/datasources/local_settings_datasource.dart';
import 'package:helpbari/features/settings/data/repositories/local_settings_repository.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/vitamins/data/datasources/local_vitamin_datasource.dart';
import 'package:helpbari/features/vitamins/data/repositories/local_vitamin_repository.dart';
import 'package:helpbari/features/vitamins/domain/entities/entities.dart';
import 'package:helpbari/features/vitamins/domain/value_objects/value_objects.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists vitamins sorted by schedule time and soft deletes', () async {
    final database = await _database();
    final repository = LocalVitaminRepository(
      LocalVitaminDatasource(database: database, clock: const _FixedClock()),
    );

    await repository.save(_vitamin(id: 'late', hour: 20));
    await repository.save(_vitamin(id: 'early', hour: 8));
    await repository.delete('late');

    final vitamins = await repository.getAll();

    expect(vitamins.map((vitamin) => vitamin.id), ['early']);
  });

  test('persists medications, updates status, and soft deletes', () async {
    final database = await _database();
    final repository = LocalMedicationRepository(
      LocalMedicationDatasource(database: database, clock: const _FixedClock()),
    );

    await repository.save(_medication(id: 'med-1', hour: 9));
    await repository.update(
      _medication(id: 'med-1', hour: 9, status: MedicationStatus.taken),
    );

    var medications = await repository.getAll();
    expect(medications.single.status, MedicationStatus.taken);

    await repository.delete('med-1');
    medications = await repository.getAll();
    expect(medications, isEmpty);
  });

  test('persists meals sorted by date descending', () async {
    final database = await _database();
    final repository = LocalMealRepository(
      LocalMealDatasource(database: database, clock: const _FixedClock()),
    );

    await repository.save(_meal(id: 'old', date: DateTime(2026, 7, 1)));
    await repository.save(_meal(id: 'new', date: DateTime(2026, 7, 9)));

    final meals = await repository.getAll();

    expect(meals.map((meal) => meal.id), ['new', 'old']);
  });

  test(
    'persists appointments sorted by date ascending and soft deletes',
    () async {
      final database = await _database();
      final repository = LocalAppointmentRepository(
        LocalAppointmentDatasource(
          database: database,
          clock: const _FixedClock(),
        ),
      );

      await repository.save(
        _appointment(id: 'later', date: DateTime(2026, 8, 1)),
      );
      await repository.save(
        _appointment(id: 'sooner', date: DateTime(2026, 7, 10)),
      );
      await repository.delete('later');

      final appointments = await repository.getAll();

      expect(appointments.map((appointment) => appointment.id), ['sooner']);
    },
  );

  test('persists exams sorted by date descending and soft deletes', () async {
    final database = await _database();
    final repository = LocalExamRepository(
      LocalExamDatasource(database: database, clock: const _FixedClock()),
    );

    await repository.save(_exam(id: 'old', date: DateTime(2026, 7, 1)));
    await repository.save(_exam(id: 'new', date: DateTime(2026, 7, 9)));
    await repository.delete('old');

    final exams = await repository.getAll();

    expect(exams.map((exam) => exam.id), ['new']);
  });

  test('persists settings and returns defaults when empty', () async {
    final database = await _database();
    final repository = LocalSettingsRepository(
      LocalSettingsDatasource(database: database, clock: const _FixedClock()),
    );

    final defaults = await repository.getSettings();
    expect(defaults.dailyWaterGoalMl, 2000);

    await repository.saveSettings(
      const AppSettings(id: 'local-settings', dailyWaterGoalMl: 2400),
    );

    final saved = await repository.getSettings();
    expect(saved.dailyWaterGoalMl, 2400);
  });
}

Future<LocalDatabase> _database() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final storage = SharedPreferencesLocalStorageService(preferences);

  return SharedPreferencesLocalDatabase(storage);
}

Vitamin _vitamin({required String id, required int hour}) {
  return Vitamin(
    id: id,
    name: VitaminName.create('Vitamina D')!,
    scheduleTime: VitaminScheduleTime.create(hour: hour, minute: 0)!,
  );
}

Medication _medication({
  required String id,
  required int hour,
  MedicationStatus status = MedicationStatus.pending,
}) {
  return Medication(
    id: id,
    name: MedicationName.create('Omeprazol')!,
    scheduleTime: MedicationScheduleTime.create(hour: hour, minute: 30)!,
    dosage: '20mg',
    status: status,
  );
}

Meal _meal({required String id, required DateTime date}) {
  return Meal(
    id: id,
    name: MealName.create('Frango')!,
    type: MealType.lunch,
    mealDate: MealDate(date, clock: const _FixedClock()),
    proteinGrams: 30,
  );
}

Appointment _appointment({required String id, required DateTime date}) {
  return Appointment(
    id: id,
    title: 'Consulta',
    date: AppointmentDate(date, clock: const _FixedClock()),
    doctorName: 'Dra. Ana',
  );
}

Exam _exam({required String id, required DateTime date}) {
  return Exam(
    id: id,
    name: ExamName.create('Hemograma')!,
    examDate: ExamDate(date),
    laboratory: 'Lab',
  );
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}
