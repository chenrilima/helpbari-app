import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/appointments/domain/repositories/repositories.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/usecases/appointment_use_cases.dart';
import 'package:helpbari/features/home/domain/usecases/health_dashboard_use_cases.dart';
import 'package:helpbari/features/meals/domain/repositories/repositories.dart';
import 'package:helpbari/features/meals/domain/entities/entities.dart';
import 'package:helpbari/features/meals/domain/usecases/use_cases.dart';
import 'package:helpbari/features/medical_exams/domain/entities/entities.dart';
import 'package:helpbari/features/medical_exams/domain/repositories/medical_exam_repository.dart';
import 'package:helpbari/features/medical_exams/domain/usecases/medical_exam_use_cases.dart';
import 'package:helpbari/features/profile/domain/repositories/profile_repository.dart';
import 'package:helpbari/features/profile/domain/usecases/delete_profile_use_case.dart';
import 'package:helpbari/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:helpbari/features/profile/domain/usecases/profile_use_cases.dart';
import 'package:helpbari/features/profile/domain/usecases/save_profile_use_case.dart';
import 'package:helpbari/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/setting_use_cases.dart';
import 'package:helpbari/features/smart_routines/domain/enums/routine_enums.dart';
import 'package:helpbari/features/smart_routines/domain/services/treatment_query_models.dart';
import 'package:helpbari/features/water/domain/repositories/water_repository.dart';
import 'package:helpbari/features/water/domain/entities/entities.dart';
import 'package:helpbari/features/water/domain/usecases/water_use_cases.dart';
import 'package:helpbari/features/weight/domain/repositories/weight_repository.dart';
import 'package:helpbari/features/weight/domain/entities/entities.dart';
import 'package:helpbari/features/weight/domain/usecases/weight_use_cases.dart';

void main() {
  test(
    'latest exam in dashboard comes from medical_exams even without results',
    () async {
      final latest = MedicalExam(
        id: 'medical-exam-1',
        userId: 'user-a',
        performedAt: DateTime(2026, 7, 18, 12),
        title: 'Hemograma completo',
        laboratoryName: 'Lab Vida',
        source: MedicalExamSource.imported,
        createdAt: DateTime.utc(2026, 7, 18),
        updatedAt: DateTime.utc(2026, 7, 18),
        syncStatus: SyncStatus.synced,
      );

      final useCases = HealthDashboardUseCases(
        profile: ProfileUseCases(
          getProfile: GetProfileUseCase(_ProfileRepository()),
          saveProfile: SaveProfileUseCase(_ProfileRepository()),
          updateProfile: UpdateProfileUseCase(_ProfileRepository()),
          deleteProfile: DeleteProfileUseCase(_ProfileRepository()),
        ),
        weight: WeightUseCases(_WeightRepository()),
        water: WaterUseCases(_WaterRepository(), const _Clock()),
        meals: MealUseCases(_MealRepository()),
        appointments: AppointmentUseCases(_AppointmentRepository()),
        exams: MedicalExamUseCases(_MedicalExamRepository([latest])),
        settings: SettingsUseCases(_SettingsRepository()),
        treatment: () async => const _TreatmentQuery(),
      );

      final aggregate = await useCases.load(
        start: DateTime.utc(2026, 7, 18),
        end: DateTime.utc(2026, 7, 18),
      );

      expect(aggregate.latestExam?.id, 'medical-exam-1');
      expect(aggregate.latestExam?.activeResultsCount, 0);
      expect(aggregate.latestExam?.title, 'Hemograma completo');
    },
  );
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 18);
}

class _ProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(null);
  }
}

class _WeightRepository implements WeightRepository, WeightRangeRepository {
  @override
  Future<List<WeightRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => const [];

  @override
  Future<WeightRecord?> getLatest() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(const []);
  }
}

class _WaterRepository implements WaterRepository, WaterRangeRepository {
  @override
  Future<List<WaterRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(const []);
  }
}

class _MealRepository implements MealRepository, MealRangeRepository {
  @override
  Future<List<Meal>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(const []);
  }
}

class _AppointmentRepository
    implements AppointmentRepository, AppointmentRangeRepository {
  @override
  Future<List<Appointment>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(const []);
  }
}

class _MedicalExamRepository
    implements MedicalExamRepository, MedicalExamRangeRepository {
  const _MedicalExamRepository(this.items);

  final List<MedicalExam> items;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<MedicalExam?> getById(String id) async =>
      items.where((item) => item.id == id).firstOrNull;

  @override
  Future<List<MedicalExam>> getHistory() async => items;

  @override
  Future<List<MedicalExam>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => items
      .where(
        (item) =>
            !item.performedAt.isBefore(startInclusive) &&
            item.performedAt.isBefore(endExclusive),
      )
      .take(limit)
      .toList();

  @override
  Future<void> save(MedicalExam exam) async {}
}

class _SettingsRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(const AppSettings(id: 'user-a'));
  }
}

class _TreatmentQuery implements TreatmentAdherenceQueryService {
  const _TreatmentQuery();

  @override
  Future<TreatmentAdherenceSummary> summary(
    DateTime start,
    DateTime end,
  ) async => const TreatmentAdherenceSummary(
    eligible: 0,
    taken: 0,
    takenOnTime: 0,
    skipped: 0,
    missed: 0,
    coverage: 0,
    coverageState: AdherenceCoverageState.unknown,
    origin: TreatmentDataOrigin.smartRoutines,
  );

  @override
  Future<TodayTreatmentReadModel> today(DateTime date) async =>
      TodayTreatmentReadModel(
        date: date,
        occurrences: const [],
        adherence: await summary(date, date),
      );

  @override
  Future<Map<String, TodayTreatmentReadModel>> days(
    DateTime start,
    DateTime end,
  ) async {
    final result = <String, TodayTreatmentReadModel>{};
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      final key =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      result[key] = await today(date);
    }
    return result;
  }
}
