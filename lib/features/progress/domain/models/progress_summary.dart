import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.profile,
    required this.latestWeightRecord,
  });

  final Profile profile;
  final WeightRecord? latestWeightRecord;

  double get initialWeight => profile.initialWeight.value;

  double? get currentWeight => latestWeightRecord?.weight.value;

  double? get targetWeight => profile.targetWeight?.value;

  double? get weightLost {
    final current = currentWeight;

    if (current == null) return null;

    return initialWeight - current;
  }

  double? get remainingToTarget {
    final current = currentWeight;
    final target = targetWeight;

    if (current == null || target == null) return null;

    return current - target;
  }

  double? get targetProgressPercent {
    final current = currentWeight;
    final target = targetWeight;

    if (current == null || target == null) return null;

    final totalToLose = initialWeight - target;
    final alreadyLost = initialWeight - current;

    if (totalToLose <= 0) return null;

    return (alreadyLost / totalToLose).clamp(0, 1) * 100;
  }

  String get formattedInitialWeight => '${initialWeight.toStringAsFixed(1)} kg';

  String get formattedCurrentWeight {
    final current = currentWeight;

    if (current == null) return 'Sem registro';

    return '${current.toStringAsFixed(1)} kg';
  }

  String get formattedWeightLost {
    final value = weightLost;

    if (value == null) return 'Sem registro';

    if (value == 0) return 'Peso inicial mantido';

    if (value > 0) {
      return '${value.toStringAsFixed(1)} kg perdidos';
    }

    return '${value.abs().toStringAsFixed(1)} kg acima do inicial';
  }

  String get formattedRemainingToTarget {
    final value = remainingToTarget;

    if (value == null) return 'Meta não definida';

    if (value <= 0) return 'Meta atingida';

    return '${value.toStringAsFixed(1)} kg até a meta';
  }

  String get formattedTargetProgress {
    final value = targetProgressPercent;

    if (value == null) return 'Meta não definida';

    return '${value.round()}% da meta';
  }

  String get formattedInitialBmi => profile.initialBmi.formatted;
}
