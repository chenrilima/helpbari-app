import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Profile extends Entity {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.birthDate,
    required this.height,
    required this.initialWeight,
    required this.surgeryDate,
    required this.surgeryType,
    this.targetWeight,
    this.photoUrl,
  });

  @override
  final String id;

  final String name;

  final AppDate birthDate;

  final Height height;

  final Weight initialWeight;

  final Weight? targetWeight;

  final AppDate surgeryDate;

  final SurgeryType surgeryType;

  final String? photoUrl;

  final String email;

  final AppDate createdAt;

  int get age => birthDate.age;

  int get daysSinceSurgery {
    final now = DateTime.now();
    return now.difference(surgeryDate.value).inDays;
  }

  Bmi get initialBmi {
    return Bmi.calculate(weight: initialWeight, height: height);
  }
}
