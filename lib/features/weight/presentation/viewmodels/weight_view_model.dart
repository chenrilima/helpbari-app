import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_weight_form.dart';
import '../providers/weight_use_cases_provider.dart';
import '../states/weight_state.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../progress/presentation/providers/progress_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';

class WeightViewModel extends Notifier<WeightState> {
  WeightUseCases get _useCases => ref.read(weightUseCasesProvider);
  UuidService get _uuidService => ref.read(uuidServiceProvider);
  ClockService get _clock => ref.read(clockServiceProvider);

  @override
  WeightState build() => const WeightState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);

    try {
      final history = await _useCases.getHistory();

      state = state.copyWith(records: history, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> registerWeight(CreateWeightForm form) async {
    state = state.copyWith(isLoading: true);

    try {
      final weight = WeightValue.create(form.weight);

      if (weight == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Peso inválido.',
        );
        return false;
      }

      final notes = form.notes == null ? null : Notes.create(form.notes!);

      final record = WeightRecord(
        id: _uuidService.generate(),
        weight: weight,
        recordedAt: RecordedAt(form.recordedAt, clock: _clock),
        notes: notes,
      );

      await _useCases.register(record);

      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> updateWeight(
    WeightRecord existing,
    CreateWeightForm form,
  ) async {
    final weight = WeightValue.create(form.weight);
    if (weight == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _useCases.update(
        WeightRecord(
          id: existing.id,
          weight: weight,
          recordedAt: RecordedAt(form.recordedAt, clock: _clock),
          notes: form.notes == null ? null : Notes.create(form.notes!),
        ),
      );
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> deleteWeight(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _useCases.delete(id);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> _refresh() async {
    _invalidateConsumers();
    state = state.copyWith(
      records: await _useCases.getHistory(),
      isLoading: false,
    );
  }

  void _invalidateConsumers() {
    ref.invalidate(weightUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(weightChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(progressViewModelProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
  }
}
