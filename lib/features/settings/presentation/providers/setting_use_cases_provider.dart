import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_setting_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FakeSettingsRepository();
});

final settingsUseCasesProvider = Provider<SettingsUseCases>((ref) {
  return SettingsUseCases(ref.read(settingsRepositoryProvider));
});
