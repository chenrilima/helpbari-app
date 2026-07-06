import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_weight_repository.dart';
import '../../domain/repositories/repositories.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return FakeWeightRepository();
});
