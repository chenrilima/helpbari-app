import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/water_use_cases_provider.dart';
import '../states/water_state.dart';

class WaterViewModel extends Notifier<WaterState> {
  final _uuid = const Uuid();

  late final WaterUseCases _useCases;

  @override
  WaterState build() {
    _useCases = ref.read(waterUseCasesProvider);

    return const WaterState();
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
      id: _uuid.v4(),
      amount: amount,
      recordedAt: DateTime.now(),
    );

    await _useCases.save(record);

    await loadHistory();
  }
}
