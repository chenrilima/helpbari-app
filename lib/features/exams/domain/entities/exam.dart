import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Exam extends Entity {
  const Exam({
    required this.id,
    required this.name,
    required this.examDate,
    this.laboratory,
    this.notes,
    this.attachmentPath,
  });

  @override
  final String id;

  final ExamName name;
  final ExamDate examDate;
  final String? laboratory;
  final String? notes;
  final String? attachmentPath;

  String get formattedName => name.value;

  String get formattedDate => examDate.formatted;

  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;

  Exam copyWith({
    ExamName? name,
    ExamDate? examDate,
    String? laboratory,
    String? notes,
    String? filePath,
  }) {
    return Exam(
      id: id,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
      laboratory: laboratory ?? this.laboratory,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? attachmentPath,
    );
  }
}
