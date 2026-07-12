import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/water_dao.dart';
import 'daos/weight_dao.dart';

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
