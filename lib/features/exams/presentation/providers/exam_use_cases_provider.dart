import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_exam_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/usecases/exam_use_cases.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => FakeExamRepository(),
);

final examUseCasesProvider = Provider<ExamUseCases>(
  (ref) => ExamUseCases(ref.read(examRepositoryProvider)),
);
