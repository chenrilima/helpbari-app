import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_weight_form.dart';
import '../providers/weight_use_cases_provider.dart';
import '../states/weight_state.dart';

class WeightViewModel extends Notifier<WeightState> {
  late final WeightUseCases _useCases;
  late final UuidService _uuidService;

  @override
  WeightState build() {
    _useCases = ref.read(weightUseCasesProvider);
    _uuidService = ref.read(uuidServiceProvider);

    return const WeightState();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);

    try {
      final history = await _useCases.getHistory();

      state = state.copyWith(records: history, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> registerWeight(CreateWeightForm form) async {
    state = state.copyWith(isLoading: true);

    try {
      final weight = WeightValue.create(form.weight);

      if (weight == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Peso inválido.',
        );
        return;
      }

      final notes = form.notes == null ? null : Notes.create(form.notes!);

      final record = WeightRecord(
        id: _uuidService.generate(),
        weight: weight,
        recordedAt: RecordedAt(form.recordedAt),
        notes: notes,
      );

      await _useCases.register(record);

      final history = await _useCases.getHistory();

      state = state.copyWith(records: history, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
