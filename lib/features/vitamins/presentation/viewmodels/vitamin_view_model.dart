import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/vitamin_use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/vitamin_use_cases_provider.dart';
import '../states/vitamin_state.dart';

class VitaminViewModel extends Notifier<VitaminState> {
  UuidService get _uuid => ref.read(uuidServiceProvider);
  VitaminUseCases get _useCases => ref.read(vitaminUseCasesProvider);
  @override
  VitaminState build() => const VitaminState();
  Future<void> loadVitamins() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _useCases.getAll(),
        _useCases.getLogs(
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day),
        ),
      ]);
      state = state.copyWith(
        vitamins: results[0] as List<Vitamin>,
        logs: results[1] as List<VitaminLog>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createVitamin({
    String? id,
    bool scheduleReminder = true,
    required String name,
    required int hour,
    required int minute,
  }) async {
    final n = VitaminName.create(name);
    final time = VitaminScheduleTime.create(hour: hour, minute: minute);
    if (n == null || time == null) return false;
    final v = Vitamin(id: id ?? _uuid.generate(), name: n, scheduleTime: time);
    return _persist(() async {
      await _useCases.save(v);
    });
  }

  Future<bool> updateVitamin(
    Vitamin old, {
    required String name,
    required int hour,
    required int minute,
  }) async {
    final n = VitaminName.create(name);
    final time = VitaminScheduleTime.create(hour: hour, minute: minute);
    if (n == null || time == null) return false;
    final v = old.copyWith(name: n, scheduleTime: time);
    return _persist(() async {
      await _useCases.update(v);
    });
  }

  Future<bool> deleteVitamin(String id) => _persist(() async {
    await _useCases.delete(id);
    await ref.read(vitaminLogRepositoryProvider).deleteForVitamin(id);
  });
  Future<void> markAsTaken(String id) => _status(id, VitaminStatus.taken);
  Future<void> markAsSkipped(String id) => _status(id, VitaminStatus.skipped);
  Future<void> resetStatus(String id) => _status(id, VitaminStatus.pending);
  Future<void> _status(String id, VitaminStatus status) async {
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
      await loadVitamins();
      unawaited(_sync());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> _sync() async {
    final result = await ref.read(syncManagerProvider.notifier).syncNow();
    if (result != null && !result.isSuccess) {
      state = state.copyWith(
        syncWarning:
            'Vitamina salva no aparelho. A sincronização será tentada novamente.',
      );
    }
  }

  void _invalidate() {
    ref.invalidate(vitaminUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(vitaminAdherenceChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}
