import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/medical_consultation_use_cases.dart';
import '../providers/medical_consultation_use_cases_provider.dart';
import '../states/medical_consultation_state.dart';

class MedicalConsultationViewModel extends Notifier<MedicalConsultationState> {
  MedicalConsultationUseCases get _useCases =>
      ref.read(medicalConsultationUseCasesProvider);

  @override
  MedicalConsultationState build() => const MedicalConsultationState();

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

  Future<bool> save(MedicalConsultation consultation) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.save(consultation);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
      return false;
    }
  }

  Future<bool> delete(MedicalConsultation consultation) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.delete(consultation.id);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
      return false;
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(medicalConsultationUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
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
