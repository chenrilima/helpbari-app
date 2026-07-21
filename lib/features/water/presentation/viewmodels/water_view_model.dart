import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/sync/sync.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/water_use_cases_provider.dart';
import '../models/water_form.dart';
import '../states/water_state.dart';

class WaterViewModel extends Notifier<WaterState> {
  UuidService get _uuidService => ref.read(uuidServiceProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);
  WaterUseCases get _useCases => ref.read(waterUseCasesProvider);
  ClockService get _clock => ref.read(clockServiceProvider);

  @override
  WaterState build() {
    return WaterState(clock: _clock);
  }

  Future<void> loadHistory() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSyncWarning: true,
    );
    try {
      final history = await _useCases.getHistory();
      state = state.copyWith(records: history, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> registerWater(int amountInMl) {
    return createWater(
      WaterForm(amountInMl: amountInMl, recordedAt: _clock.now()),
    );
  }

  Future<bool> createWater(WaterForm form) async {
    final amount = WaterAmount.create(form.amountInMl);

    if (amount == null) {
      state = state.copyWith(errorMessage: 'Quantidade de água inválida.');
      return false;
    }

    final record = WaterRecord(
      id: _uuidService.generate(),
      amount: amount,
      recordedAt: form.recordedAt,
      clock: _clock,
    );

    return _persist(() => _useCases.create(record), 'Registro de água criado.');
  }

  Future<bool> updateWater(WaterRecord record, WaterForm form) async {
    final amount = WaterAmount.create(form.amountInMl);
    if (amount == null) {
      state = state.copyWith(errorMessage: 'Quantidade de água inválida.');
      return false;
    }
    final updated = WaterRecord(
      id: record.id,
      amount: amount,
      recordedAt: form.recordedAt,
      clock: _clock,
    );
    return _persist(
      () => _useCases.update(updated),
      'Registro de água atualizado.',
    );
  }

  Future<bool> deleteWater(String id) {
    return _persist(() => _useCases.delete(id), 'Registro de água excluído.');
  }

  Future<bool> _persist(Future<void> Function() operation, String log) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await operation();
      _logger.info(log);
      await loadHistory();
      ref.invalidate(waterUseCasesProvider);
      ref.invalidate(todayDashboardProvider);
      ref.invalidate(waterChartSeriesProvider);
      ref.invalidate(healthScoreChartSeriesProvider);
      ref.invalidate(healthPeriodAggregateProvider);
      final syncResult = await ref.read(syncManagerProvider.notifier).syncNow();
      if (syncResult != null && !syncResult.isSuccess) {
        state = state.copyWith(
          syncWarning:
              'Registro salvo no aparelho. A sincronização será tentada novamente.',
        );
      }
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}
