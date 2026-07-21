import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/sync/sync.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/meal_use_cases_provider.dart';
import '../states/meal_state.dart';

class MealViewModel extends Notifier<MealState> {
  UuidService get _uuidService => ref.read(uuidServiceProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);
  ClockService get _clock => ref.read(clockServiceProvider);
  MealUseCases get _useCases => ref.read(mealUseCasesProvider);

  @override
  MealState build() {
    return const MealState();
  }

  Future<void> loadMeals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(meals: await _useCases.getAll(), isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> createMeal({
    required String name,
    required MealType type,
    required DateTime mealDate,
    String? notes,
    int? proteinGrams,
  }) async {
    final mealName = MealName.create(name);

    if (mealName == null) {
      state = state.copyWith(errorMessage: 'Nome da refeição inválido.');
      return false;
    }

    final meal = Meal(
      id: _uuidService.generate(),
      name: mealName,
      type: type,
      mealDate: MealDate(mealDate, clock: _clock),
      notes: notes,
      proteinGrams: proteinGrams,
    );

    return _persist(() => _useCases.save(meal), 'Refeição cadastrada.');
  }

  Future<bool> updateMeal(
    Meal existing, {
    required String name,
    required MealType type,
    required DateTime mealDate,
    String? notes,
    int? proteinGrams,
  }) async {
    final mealName = MealName.create(name);
    if (mealName == null) return false;
    final updated = Meal(
      id: existing.id,
      name: mealName,
      type: type,
      mealDate: MealDate(mealDate, clock: _clock),
      notes: notes,
      proteinGrams: proteinGrams,
    );
    return _persist(() => _useCases.update(updated), 'Refeição atualizada.');
  }

  Future<bool> deleteMeal(String id) =>
      _persist(() => _useCases.delete(id), 'Refeição excluída.');

  void setTypeFilter(MealType? type) =>
      state = state.copyWith(typeFilter: type, clearTypeFilter: type == null);
  void setDateFilter(DateTime? date) =>
      state = state.copyWith(dateFilter: date, clearDateFilter: date == null);
  void clearFilters() =>
      state = state.copyWith(clearTypeFilter: true, clearDateFilter: true);

  Future<bool> _persist(Future<void> Function() operation, String log) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );
    try {
      await operation();
      _logger.info(log);
      _invalidateConsumers();
      await loadMeals();
      unawaited(_syncAfterMutation());
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> _syncAfterMutation() async {
    final result = await ref.read(syncManagerProvider.notifier).syncNow();
    if (result != null && !result.isSuccess) {
      state = state.copyWith(
        syncWarning:
            'Refeição salva no aparelho. A sincronização será tentada novamente.',
      );
    }
  }

  void _invalidateConsumers() {
    ref.invalidate(mealUseCasesProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}
