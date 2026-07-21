import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../application/appointment_reminder_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/appointment_use_cases_provider.dart';
import '../states/appointment_state.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../../core/sync/sync.dart';

class AppointmentViewModel extends Notifier<AppointmentState> {
  UuidService get _uuidService => ref.read(uuidServiceProvider);
  ClockService get _clock => ref.read(clockServiceProvider);
  AppointmentReminderService get _reminders =>
      ref.read(appointmentReminderServiceProvider);
  AppointmentUseCases get _useCases => ref.read(appointmentUseCasesProvider);

  @override
  AppointmentState build() => const AppointmentState();

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        appointments: await _useCases.getAll(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> createAppointment({
    required String title,
    required DateTime date,
    String? doctorName,
    String? location,
    String? notes,
  }) async {
    final appointment = Appointment(
      id: _uuidService.generate(),
      title: title,
      date: AppointmentDate(date, clock: _clock),
      doctorName: doctorName,
      location: location,
      notes: notes,
    );

    return _persist(() => _useCases.save(appointment), appointment);
  }

  Future<bool> updateAppointment(
    Appointment existing, {
    required String title,
    required DateTime date,
    String? doctorName,
    String? location,
    String? notes,
  }) {
    final updated = Appointment(
      id: existing.id,
      title: title,
      date: AppointmentDate(date, clock: _clock),
      doctorName: doctorName,
      location: location,
      notes: notes,
      status: existing.status,
    );
    return _persist(() => _useCases.update(updated), updated);
  }

  Future<bool> complete(Appointment value) => _persist(
    () => _useCases.markAsCompleted(value.id),
    value.copyWith(status: AppointmentStatus.completed),
  );

  Future<bool> cancel(Appointment value) => _persist(
    () => _useCases.cancel(value.id),
    value.copyWith(status: AppointmentStatus.canceled),
  );
  Future<bool> delete(Appointment value) =>
      _persist(() => _useCases.delete(value.id), value, deleted: true);
  void setStatusFilter(AppointmentStatus? value) => state = state.copyWith(
    statusFilter: value,
    clearStatusFilter: value == null,
  );
  void setDateFilter(DateTime? value) =>
      state = state.copyWith(dateFilter: value, clearDateFilter: value == null);
  void clearFilters() =>
      state = state.copyWith(clearStatusFilter: true, clearDateFilter: true);

  Future<bool> _persist(
    Future<void> Function() operation,
    Appointment value, {
    bool deleted = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await operation();
      await _applyReminderBestEffort(value, deleted: deleted);
      _invalidate();
      await loadAppointments();
      unawaited(ref.read(syncManagerProvider.notifier).syncNow());
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> _applyReminderBestEffort(
    Appointment value, {
    required bool deleted,
  }) async {
    try {
      if (deleted) {
        await _reminders.cancel(value.id);
      } else {
        await _reminders.applyAfterCommit(value);
      }
    } catch (error) {
      ref
          .read(loggerServiceProvider)
          .warning(
            'Appointment notification update failed (${error.runtimeType}).',
          );
    }
  }

  void _invalidate() {
    ref.invalidate(appointmentUseCasesProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}
