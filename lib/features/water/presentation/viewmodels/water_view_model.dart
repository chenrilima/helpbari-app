import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/water_use_cases_provider.dart';
import '../states/water_state.dart';

class WaterViewModel extends Notifier<WaterState> {
  late final UuidService _uuidService;
  late final LoggerService _logger;
  late final WaterUseCases _useCases;
  late final ClockService _clock;

  @override
  WaterState build() {
    _useCases = ref.read(waterUseCasesProvider);
    _logger = ref.read(loggerServiceProvider);
    _uuidService = ref.read(uuidServiceProvider);
    _clock = ref.read(clockServiceProvider);
    return WaterState(clock: _clock);
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);

    final history = await _useCases.getHistory();

    state = state.copyWith(records: history, isLoading: false);
  }

  Future<void> registerWater(int amountInMl) async {
    final amount = WaterAmount.create(amountInMl);

    if (amount == null) {
      return;
    }

    final record = WaterRecord(
      id: _uuidService.generate(),
      amount: amount,
      recordedAt: _clock.now(),
      clock: _clock,
    );

    await _useCases.save(record);
    _logger.info('ML de Água criado');
    await loadHistory();
  }
}
