import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_appointment_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => FakeAppointmentRepository(),
);

final appointmentUseCasesProvider = Provider<AppointmentUseCases>(
  (ref) => AppointmentUseCases(ref.read(appointmentRepositoryProvider)),
);
