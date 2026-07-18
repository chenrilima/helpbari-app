import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/medical_exam_use_cases.dart';
import 'medical_exam_repository_provider.dart';

final medicalExamUseCasesProvider = Provider<MedicalExamUseCases>(
  (ref) => MedicalExamUseCases(ref.watch(medicalExamRepositoryProvider)),
);
