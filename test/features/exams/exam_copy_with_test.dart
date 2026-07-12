import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/exams/domain/entities/entities.dart';
import 'package:helpbari/features/exams/domain/value_objects/value_objects.dart';

void main() {
  test('copyWith explicitly clears attachmentPath', () {
    final exam = Exam(
      id: 'exam',
      name: ExamName.create('Exame')!,
      examDate: ExamDate(DateTime(2026)),
      attachmentPath: 'user/exam/file.pdf',
    );
    expect(exam.copyWith(clearAttachmentPath: true).attachmentPath, isNull);
  });
}
