import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/vitamin_use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/vitamin_use_cases_provider.dart';
import '../states/vitamin_state.dart';

class VitaminViewModel extends Notifier<VitaminState> {
  late final UuidService _uuidService;
  late final LoggerService _logger;
  late final VitaminUseCases _useCases;

  @override
  VitaminState build() {
    _useCases = ref.read(vitaminUseCasesProvider);
    _logger = ref.read(loggerServiceProvider);
    _uuidService = ref.read(uuidServiceProvider);

    return const VitaminState();
  }

  Future<void> loadVitamins() async {
    state = state.copyWith(isLoading: true);

    final vitamins = await _useCases.getAll();

    state = state.copyWith(vitamins: vitamins, isLoading: false);
  }

  Future<void> createVitamin({
    required String name,
    required int hour,
    required int minute,
  }) async {
    final vitaminName = VitaminName.create(name);
    final scheduleTime = VitaminScheduleTime.create(hour: hour, minute: minute);

    if (vitaminName == null || scheduleTime == null) {
      return;
    }

    final vitamin = Vitamin(
      id: _uuidService.generate(),
      name: vitaminName,
      scheduleTime: scheduleTime,
    );

    await _useCases.save(vitamin);
    await loadVitamins();
    _logger.info('Vitamina Criada.');
  }

  Future<void> markAsTaken(String id) async {
    await _useCases.markAsTaken(id);
    await loadVitamins();
    _logger.info('Vitamina tomada');
  }

  Future<void> markAsSkipped(String id) async {
    await _useCases.markAsSkipped(id);
    await loadVitamins();
  }

  Future<void> resetStatus(String id) async {
    await _useCases.resetStatus(id);
    await loadVitamins();
  }
}
