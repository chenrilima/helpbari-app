import '../entities/entities.dart';

class ExamSummary {
  const ExamSummary({required this.latestExam, required this.hasExams});

  final Exam? latestExam;

  final bool hasExams;
}
