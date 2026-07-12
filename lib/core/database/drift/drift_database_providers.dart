import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/water_dao.dart';
import 'daos/weight_dao.dart';
import 'daos/meal_dao.dart';
import 'daos/appointment_dao.dart';
import 'daos/exam_dao.dart';
import 'daos/vitamin_dao.dart';
import 'daos/vitamin_log_dao.dart';

final driftAvailableProvider = Provider<bool>((ref) => true);

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = AppDatabase();
  ref.onDispose(database.close);

  await database.customSelect('SELECT 1').getSingle();
  return database;
});

final waterDaoProvider = FutureProvider<WaterDao>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return database.waterDao;
});

final weightDaoProvider = FutureProvider<WeightDao>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return database.weightDao;
});

final mealDaoProvider = FutureProvider<MealDao>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return database.mealDao;
});
final appointmentDaoProvider = FutureProvider<AppointmentDao>(
  (ref) async => (await ref.watch(appDatabaseProvider.future)).appointmentDao,
);
final examDaoProvider = FutureProvider<ExamDao>(
  (ref) async => (await ref.watch(appDatabaseProvider.future)).examDao,
);
final vitaminDaoProvider = FutureProvider<VitaminDao>(
  (ref) async => (await ref.watch(appDatabaseProvider.future)).vitaminDao,
);
final vitaminLogDaoProvider = FutureProvider<VitaminLogDao>(
  (ref) async => (await ref.watch(appDatabaseProvider.future)).vitaminLogDao,
);
