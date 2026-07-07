enum AppointmentStatus {
  scheduled,
  completed,
  canceled;

  String get label {
    return switch (this) {
      AppointmentStatus.scheduled => 'Agendada',
      AppointmentStatus.completed => 'Realizada',
      AppointmentStatus.canceled => 'Cancelada',
    };
  }
}
