import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_exam_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return FakeExamRepository();
});

final examUseCasesProvider = Provider<ExamUseCases>((ref) {
  return ExamUseCases(ref.read(examRepositoryProvider));
});
