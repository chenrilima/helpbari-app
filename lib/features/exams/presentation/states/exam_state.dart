import '../../domain/entities/entities.dart';

class ExamState {
  const ExamState({this.items = const [], this.isLoading = false});

  final List<Exam> items;
  final bool isLoading;

  bool get hasItems => items.isNotEmpty;

  ExamState copyWith({List<Exam>? items, bool? isLoading}) {
    return ExamState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
