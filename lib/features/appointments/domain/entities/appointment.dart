import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Appointment extends Entity {
  const Appointment({
    required this.id,
    required this.title,
    required this.date,
    this.doctorName,
    this.location,
    this.notes,
    this.status = AppointmentStatus.scheduled,
  });

  @override
  final String id;

  final String title;
  final AppointmentDate date;
  final String? doctorName;
  final String? location;
  final String? notes;
  final AppointmentStatus status;

  bool get isScheduled => status == AppointmentStatus.scheduled;

  bool get isCompleted => status == AppointmentStatus.completed;

  bool get isCanceled => status == AppointmentStatus.canceled;

  bool get isUpcoming => date.isUpcoming && isScheduled;

  String get formattedDate => date.formatted;

  Appointment copyWith({
    String? title,
    AppointmentDate? date,
    String? doctorName,
    String? location,
    String? notes,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
