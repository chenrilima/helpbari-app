import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/bioimpedance_record.dart';
import '../../domain/usecases/bioimpedance_use_cases.dart';
import '../providers/bioimpedance_use_cases_provider.dart';
import '../states/bioimpedance_state.dart';

class BioimpedanceViewModel extends Notifier<BioimpedanceState> {
  BioimpedanceUseCases get _useCases => ref.read(bioimpedanceUseCasesProvider);

  @override
  BioimpedanceState build() => const BioimpedanceState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        items: await _useCases.getHistory(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> saveRecord(BioimpedanceRecord record) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.save(record);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> deleteRecord(BioimpedanceRecord record) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.delete(record.id);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  void select(BioimpedanceRecord record) {
    state = state.copyWith(selected: record);
  }

  Future<void> _refresh() async {
    ref.invalidate(bioimpedanceUseCasesProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
    state = state.copyWith(
      items: await _useCases.getHistory(),
      isLoading: false,
    );
    unawaited(ref.read(syncManagerProvider.notifier).syncNow());
  }
}
