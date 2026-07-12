import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/appointments/presentation/providers/appointment_view_model_provider.dart';
import 'package:helpbari/features/appointments/presentation/states/appointment_state.dart';

void main() {
  test('filters by date and status', () {
    final state = AppointmentState(
      appointments: [
        _appointment(
          'scheduled',
          AppointmentStatus.scheduled,
          DateTime(2026, 8, 1),
        ),
        _appointment(
          'completed',
          AppointmentStatus.completed,
          DateTime(2026, 8, 1),
        ),
        _appointment('old', AppointmentStatus.completed, DateTime(2026, 7, 1)),
      ],
      statusFilter: AppointmentStatus.completed,
      dateFilter: DateTime(2026, 8, 1),
    );
    expect(state.filteredAppointments.map((item) => item.id), ['completed']);
  });

  test('view model rebuilds after sync invalidation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appointmentViewModelProvider);
    container.invalidate(appointmentViewModelProvider);
    expect(container.read(appointmentViewModelProvider).isLoading, isFalse);
  });
}

Appointment _appointment(String id, AppointmentStatus status, DateTime date) =>
    Appointment(id: id, title: id, date: AppointmentDate(date), status: status);
