import '../../domain/entities/entities.dart';

class VitaminState {
  const VitaminState({this.vitamins = const [], this.isLoading = false});

  final List<Vitamin> vitamins;
  final bool isLoading;

  bool get hasVitamins => vitamins.isNotEmpty;

  int get pendingCount {
    return vitamins.where((vitamin) => vitamin.isPending).length;
  }

  VitaminState copyWith({List<Vitamin>? vitamins, bool? isLoading}) {
    return VitaminState(
      vitamins: vitamins ?? this.vitamins,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
