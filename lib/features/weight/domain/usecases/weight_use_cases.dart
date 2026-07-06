import 'delete_weight_use_case.dart';
import 'get_weight_history_use_case.dart';
import 'register_weight_use_case.dart';
import 'update_weight_use_case.dart';

class WeightUseCases {
  const WeightUseCases({
    required this.getHistory,
    required this.register,
    required this.update,
    required this.delete,
  });

  final GetWeightHistoryUseCase getHistory;
  final RegisterWeightUseCase register;
  final UpdateWeightUseCase update;
  final DeleteWeightUseCase delete;
}
