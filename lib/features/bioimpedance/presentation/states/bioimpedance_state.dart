import '../../domain/entities/bioimpedance_record.dart';

class BioimpedanceState {
  const BioimpedanceState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selected,
  });

  final List<BioimpedanceRecord> items;
  final bool isLoading;
  final String? errorMessage;
  final BioimpedanceRecord? selected;

  bool get hasItems => items.isNotEmpty;

  BioimpedanceState copyWith({
    List<BioimpedanceRecord>? items,
    bool? isLoading,
    String? errorMessage,
    BioimpedanceRecord? selected,
    bool clearError = false,
    bool clearSelected = false,
  }) => BioimpedanceState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    selected: clearSelected ? null : selected ?? this.selected,
  );
}
