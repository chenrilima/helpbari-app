import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_water_repository.dart';
import '../../domain/usecases/use_cases.dart';

final waterRepositoryProvider = Provider((ref) => FakeWaterRepository());

final waterUseCasesProvider = Provider(
  (ref) => WaterUseCases(ref.read(waterRepositoryProvider)),
);
