import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class AppointmentState {
  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter,
    this.dateFilter,
  });

  final List<Appointment> appointments;
  final bool isLoading;
  final String? errorMessage;
  final AppointmentStatus? statusFilter;
  final DateTime? dateFilter;

  List<Appointment> get filteredAppointments => appointments.where((item) {
    final date = dateFilter;
    final value = item.date.value;
    return (statusFilter == null || item.status == statusFilter) &&
        (date == null ||
            (date.year == value.year &&
                date.month == value.month &&
                date.day == value.day));
  }).toList();

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
    String? errorMessage,
    AppointmentStatus? statusFilter,
    DateTime? dateFilter,
    bool clearError = false,
    bool clearStatusFilter = false,
    bool clearDateFilter = false,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      dateFilter: clearDateFilter ? null : dateFilter ?? this.dateFilter,
    );
  }
}
