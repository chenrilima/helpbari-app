import '../../../../core/domain/entity.dart';

class Exam extends Entity {
  const Exam({required this.id, required this.title});

  @override
  final String id;

  final String title;
}
