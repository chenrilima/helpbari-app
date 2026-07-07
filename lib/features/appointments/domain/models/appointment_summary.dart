import '../entities/entities.dart';

class AppointmentSummary {
  const AppointmentSummary({
    required this.nextAppointment,
    required this.hasAppointments,
  });

  final Appointment? nextAppointment;
  final bool hasAppointments;
}
