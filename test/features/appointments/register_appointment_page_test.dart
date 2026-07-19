import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/service_providers.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/appointments/presentation/pages/register_appointment_page.dart';

void main() {
  testWidgets('opens date picker when editing a past appointment', (
    tester,
  ) async {
    final appointment = Appointment(
      id: 'appointment-1',
      title: 'Retorno',
      date: AppointmentDate(DateTime(2026, 7, 14, 9)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockServiceProvider.overrideWithValue(
            _FixedClock(DateTime(2026, 7, 19, 15, 30)),
          ),
        ],
        child: MaterialApp(
          home: RegisterAppointmentPage(appointment: appointment),
        ),
      ),
    );

    final dateButton = find.text('Data: 14/07/2026');
    await tester.ensureVisible(dateButton);
    await tester.tap(dateButton);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FixedClock implements ClockService {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
