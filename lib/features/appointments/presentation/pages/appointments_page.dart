import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../providers/appointment_view_model_provider.dart';
import '../widgets/appointment_summary_card.dart';
import '../widgets/appointment_tile.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appointmentViewModelProvider.notifier).loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentViewModelProvider);

    return HBPage(
      children: [
        HBText('Consultas', style: Theme.of(context).textTheme.headlineMedium),

        const HBGap.sm(),

        HBText(
          'Acompanhe suas consultas médicas.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),

        const HBGap.xl(),

        if (state.nextAppointment != null)
          AppointmentSummaryCard(appointment: state.nextAppointment!)
        else
          const HBEmptyState(
            title: 'Nenhuma consulta agendada',
            description: 'Agende sua primeira consulta.',
            icon: AppIcons.calendar,
          ),

        const HBGap.xl(),

        HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),

        const HBGap.md(),

        if (state.hasAppointments)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.appointments.length,
            separatorBuilder: (_, __) => const HBGap.md(),
            itemBuilder: (_, index) {
              final appointment = state.appointments[index];

              return AppointmentTile(
                appointment: appointment,
                onComplete: () {
                  ref
                      .read(appointmentViewModelProvider.notifier)
                      .complete(appointment.id);
                },
                onCancel: () {
                  ref
                      .read(appointmentViewModelProvider.notifier)
                      .cancel(appointment.id);
                },
              );
            },
          ),

        const HBGap.xl(),

        HBButton(
          label: 'Agendar consulta',
          onPressed: () async {
            await context.push(AppRoutes.registerAppointment);

            if (!mounted) return;

            await ref
                .read(appointmentViewModelProvider.notifier)
                .loadAppointments();
          },
        ),
      ],
    );
  }
}
