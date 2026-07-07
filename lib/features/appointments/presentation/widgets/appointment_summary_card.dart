import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class AppointmentSummaryCard extends StatelessWidget {
  const AppointmentSummaryCard({required this.appointment, super.key});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: 'Próxima consulta',
      value: appointment.title,
      description: appointment.formattedDate,
      icon: AppIcons.calendar,
    );
  }
}
