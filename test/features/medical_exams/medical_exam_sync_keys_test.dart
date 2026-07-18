import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/exams/data/repositories/exam_sync_repository.dart';
import 'package:helpbari/features/medical_exams/data/repositories/medical_exam_sync_repository.dart';

void main() {
  test('legacy exams sync key and medical exams sync key stay distinct', () {
    expect(ExamSyncRepository.key, 'exams');
    expect(MedicalExamSyncRepository.key, 'medical_exams');
    expect(ExamSyncRepository.key, isNot(MedicalExamSyncRepository.key));
  });
}
