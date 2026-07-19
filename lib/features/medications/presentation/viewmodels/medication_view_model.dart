import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../application/medication_reminder_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/medication_use_cases_provider.dart';
import '../states/medication_state.dart';

class MedicationViewModel extends Notifier<MedicationState> {
  UuidService get _uuid => ref.read(uuidServiceProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);
  MedicationReminderService get _reminders =>
      ref.read(medicationReminderServiceProvider);
  MedicationUseCases get _useCases => ref.read(medicationUseCasesProvider);
  @override
  MedicationState build() => const MedicationState();
  Future<void> loadMedications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        _useCases.getAll(),
        _useCases.getLogs(day, day),
      ]);
      state = state.copyWith(
        medications: results[0] as List<Medication>,
        logs: results[1] as List<MedicationLog>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createMedication({
    String? id,
    bool scheduleReminder = true,
    required String name,
    required int hour,
    required int minute,
    String? dosage,
    String? notes,
  }) async {
    final n = MedicationName.create(name);
    final time = MedicationScheduleTime.create(hour: hour, minute: minute);
    if (n == null || time == null) return false;
    final m = Medication(
      id: id ?? _uuid.generate(),
      name: n,
      scheduleTime: time,
      dosage: dosage,
      notes: notes,
    );
    return _persist(() async {
      await _useCases.save(m);
      if (scheduleReminder) {
        await _notification(() => _reminders.scheduleIfEnabled(m));
      }
    });
  }

  Future<bool> updateMedication(
    Medication old, {
    required String name,
    required int hour,
    required int minute,
    String? dosage,
    String? notes,
  }) async {
    final n = MedicationName.create(name);
    final time = MedicationScheduleTime.create(hour: hour, minute: minute);
    if (n == null || time == null) return false;
    final m = old.copyWith(
      name: n,
      scheduleTime: time,
      dosage: dosage,
      notes: notes,
    );
    return _persist(() async {
      await _useCases.update(m);
      await _notification(() => _reminders.rescheduleIfEnabled(m));
    });
  }

  Future<bool> deleteMedication(String id) => _persist(() async {
    await _useCases.delete(id);
    await ref.read(medicationLogRepositoryProvider).deleteForMedication(id);
    await _notification(() => _reminders.cancel(id));
  });
  Future<void> markAsTaken(String id) => _status(id, MedicationStatus.taken);
  Future<void> markAsSkipped(String id) =>
      _status(id, MedicationStatus.skipped);
  Future<void> resetStatus(String id) => _status(id, MedicationStatus.pending);
  Future<void> _status(String id, MedicationStatus status) async {
    await _persist(() async {
      await _useCases.setDailyStatus(id, status);
    });
  }

  Future<bool> _persist(Future<void> Function() operation) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );
    try {
      await operation();
      _invalidate();
      await loadMedications();
      unawaited(_sync());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> _notification(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      _logger.warning(
        'Medication notification reconciliation failed (${e.runtimeType}).',
      );
    }
  }

  Future<void> _sync() async {
    final result = await ref.read(syncManagerProvider.notifier).syncNow();
    if (result != null && !result.isSuccess) {
      state = state.copyWith(
        syncWarning:
            'Medicamento salvo no aparelho. A sincronização será tentada novamente.',
      );
    }
  }

  void _invalidate() {
    ref.invalidate(medicationUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(medicationAdherenceChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}
