import '../../domain/value_objects/value_objects.dart';

class CreateProfileForm {
  const CreateProfileForm({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.height,
    required this.initialWeight,
    required this.targetWeight,
    required this.surgeryDate,
    required this.surgeryType,
  });

  final String name;
  final String email;
  final DateTime birthDate;
  final int height;
  final double initialWeight;
  final double? targetWeight;
  final DateTime surgeryDate;
  final SurgeryType surgeryType;
}
