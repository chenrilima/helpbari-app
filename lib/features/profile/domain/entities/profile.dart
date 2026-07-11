import '../../../../core/domain/entity.dart';
import '../../../../core/services/clock_service.dart';
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
    this.photoStoragePath,
    this.clock = const AppClockService(),
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
  final String? photoStoragePath;

  final String email;

  final AppDate createdAt;

  final ClockService clock;

  int get age => birthDate.age;

  int get daysSinceSurgery {
    final now = clock.now();
    return now.difference(surgeryDate.value).inDays;
  }

  Bmi get initialBmi {
    return Bmi.calculate(weight: initialWeight, height: height);
  }

  Profile copyWith({
    String? photoStoragePath,
    bool clearPhotoStoragePath = false,
  }) => Profile(
    id: id,
    name: name,
    email: email,
    createdAt: createdAt,
    birthDate: birthDate,
    height: height,
    initialWeight: initialWeight,
    targetWeight: targetWeight,
    surgeryDate: surgeryDate,
    surgeryType: surgeryType,
    photoUrl: photoUrl,
    photoStoragePath: clearPhotoStoragePath
        ? null
        : photoStoragePath ?? this.photoStoragePath,
    clock: clock,
  );
}
