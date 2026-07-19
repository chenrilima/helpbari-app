import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../appointments/presentation/widgets/appointment_summary_card.dart';
import 'home_section.dart';

class AppointmentOverviewSection extends StatelessWidget {
  const AppointmentOverviewSection({
    required this.nextAppointment,
    this.subtitle = 'Seu próximo agendamento.',
    this.onRefresh,
    super.key,
  });

  final Appointment? nextAppointment;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _openAppointments(BuildContext context) async {
    await context.pushAndRefresh(AppRoutes.appointments, onRefresh: onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Meus agendamentos',
      subtitle: subtitle,
      child: nextAppointment != null
          ? AppointmentSummaryCard(appointment: nextAppointment!)
          : HBEmptyState(
              title: 'Nenhum agendamento futuro',
              description: 'Cadastre seu próximo agendamento.',
              icon: AppIcons.calendar,
              onTap: () => _openAppointments(context),
            ),
    );
  }
}
