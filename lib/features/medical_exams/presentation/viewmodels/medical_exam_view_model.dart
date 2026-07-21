import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/medical_exam_use_cases.dart';
import '../providers/medical_exam_use_cases_provider.dart';
import '../states/medical_exam_state.dart';

class MedicalExamViewModel extends Notifier<MedicalExamState> {
  MedicalExamUseCases get _useCases => ref.read(medicalExamUseCasesProvider);

  @override
  MedicalExamState build() => const MedicalExamState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        items: await _useCases.getHistory(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  Future<bool> save(MedicalExam exam) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.save(exam);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
      return false;
    }
  }

  Future<bool> delete(MedicalExam exam) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.delete(exam.id);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
      return false;
    }
  }

  void select(MedicalExam exam) {
    state = state.copyWith(selected: exam);
  }

  Future<void> _refresh() async {
    ref.invalidate(medicalExamUseCasesProvider);
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
