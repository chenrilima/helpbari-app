import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/service_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
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

  Future<void> _load() =>
      ref.read(appointmentViewModelProvider.notifier).loadAppointments();
  Future<void> _edit(Appointment value) async {
    final changed = await context.push<bool>(
      AppRoutes.registerAppointment,
      extra: value,
    );
    if (changed == true) await _load();
  }

  Future<bool> _confirm(String title, String message) async =>
      await HBDialog.confirm(
        context,
        title: title,
        message: message,
        confirmLabel: 'Confirmar',
      ) ==
      true;
  Future<void> _mutate(
    String title,
    String message,
    Future<bool> Function() action,
  ) async {
    if (!await _confirm(title, message) || !mounted) return;
    final success = await action();
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Consulta atualizada com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(appointmentViewModelProvider).errorMessage ??
            'Não foi possível atualizar a consulta.',
      );
    }
  }

  Future<void> _pickFilterDate() async {
    final now = ref.read(clockServiceProvider).now();
    final value = await showDatePicker(
      context: context,
      initialDate: ref.read(appointmentViewModelProvider).dateFilter ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) {
      ref.read(appointmentViewModelProvider.notifier).setDateFilter(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentViewModelProvider);
    final appointments = state.filteredAppointments;

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Atualizando consultas...',
      child: HBPage(
        appBar: const HBAppBar(title: 'Consultas'),
        children: [
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

          HBCard(
            child: Column(
              children: [
                DropdownButtonFormField<AppointmentStatus?>(
                  initialValue: state.statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<AppointmentStatus?>(
                      value: null,
                      child: HBText('Todos'),
                    ),
                    ...AppointmentStatus.values.map(
                      (status) => DropdownMenuItem<AppointmentStatus?>(
                        value: status,
                        child: HBText(status.label),
                      ),
                    ),
                  ],
                  onChanged: ref
                      .read(appointmentViewModelProvider.notifier)
                      .setStatusFilter,
                ),
                const HBGap.md(),
                HBButton(
                  label: state.dateFilter == null
                      ? 'Filtrar por data'
                      : AppDateFormatter.short(state.dateFilter!),
                  onPressed: _pickFilterDate,
                ),
                if (state.statusFilter != null || state.dateFilter != null) ...[
                  const HBGap.sm(),
                  HBButton(
                    label: 'Limpar filtros',
                    onPressed: ref
                        .read(appointmentViewModelProvider.notifier)
                        .clearFilters,
                  ),
                ],
              ],
            ),
          ),

          const HBGap.md(),

          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar as consultas',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _load,
            )
          else if (!state.hasAppointments)
            const HBEmptyState(
              title: 'Nenhuma consulta encontrada',
              description: 'Agende sua primeira consulta.',
              icon: AppIcons.calendar,
            )
          else if (appointments.isEmpty)
            const HBEmptyState(
              title: 'Nenhuma consulta nos filtros',
              description: 'Ajuste a data ou o status selecionado.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final appointment = appointments[index];

                return AppointmentTile(
                  appointment: appointment,
                  onComplete: () => _mutate(
                    'Concluir consulta?',
                    'O lembrete será cancelado.',
                    () => ref
                        .read(appointmentViewModelProvider.notifier)
                        .complete(appointment),
                  ),
                  onCancel: () => _mutate(
                    'Cancelar consulta?',
                    'O lembrete será cancelado.',
                    () => ref
                        .read(appointmentViewModelProvider.notifier)
                        .cancel(appointment),
                  ),
                  onEdit: () => _edit(appointment),
                  onDelete: () => _mutate(
                    'Excluir consulta?',
                    'A consulta será removida e sincronizada.',
                    () => ref
                        .read(appointmentViewModelProvider.notifier)
                        .delete(appointment),
                  ),
                );
              },
            ),

          const HBGap.xl(),

          HBButton(
            label: 'Agendar consulta',
            onPressed: () {
              context.pushAndRefresh(
                AppRoutes.registerAppointment,
                onRefresh: () {
                  return ref
                      .read(appointmentViewModelProvider.notifier)
                      .loadAppointments();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
