import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/exam_use_cases_provider.dart';
import '../states/exam_state.dart';

class ExamViewModel extends Notifier<ExamState> {
  late final UuidService _uuidService;
  late final ExamUseCases _useCases;

  @override
  ExamState build() {
    _useCases = ref.read(examUseCasesProvider);
    _uuidService = ref.read(uuidServiceProvider);

    return const ExamState();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);

    final items = await _useCases.getAll();

    state = state.copyWith(items: items, isLoading: false);
  }

  Future<void> createExam({
    required String name,
    required DateTime examDate,
    String? laboratory,
    String? notes,
    String? filePath,
  }) async {
    final examName = ExamName.create(name);

    if (examName == null) return;

    final exam = Exam(
      id: _uuidService.generate(),
      name: examName,
      examDate: ExamDate(examDate),
      laboratory: laboratory,
      notes: notes,
      attachmentPath: filePath,
    );

    await _useCases.save(exam);
    await loadItems();
  }
}
