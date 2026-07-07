import '../../domain/entities/entities.dart';

class AppointmentState {
  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
  });

  final List<Appointment> appointments;
  final bool isLoading;

  bool get hasAppointments => appointments.isNotEmpty;

  Appointment? get nextAppointment {
    try {
      return appointments.firstWhere((appointment) => appointment.isUpcoming);
    } catch (_) {
      return null;
    }
  }

  AppointmentState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
