import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/appointment_state.dart';
import '../viewmodels/appointment_view_model.dart';

final appointmentViewModelProvider =
    NotifierProvider<AppointmentViewModel, AppointmentState>(
      AppointmentViewModel.new,
    );
