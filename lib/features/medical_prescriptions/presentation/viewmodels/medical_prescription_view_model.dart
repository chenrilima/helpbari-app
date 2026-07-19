import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';
import '../states/medical_prescription_state.dart';

class MedicalPrescriptionViewModel extends Notifier<MedicalPrescriptionState> {
  @override
  MedicalPrescriptionState build() => const MedicalPrescriptionState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        items: await ref.read(medicalPrescriptionUseCasesProvider).getAll(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  Future<MedicalPrescription?> findDuplicate(MedicalPrescription value) => ref
      .read(medicalPrescriptionUseCasesProvider)
      .findPotentialDuplicate(value);

  Future<bool> save(MedicalPrescription value, {bool confirm = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCases = ref.read(medicalPrescriptionUseCasesProvider);
      if (confirm) {
        await useCases.confirm(value, DateTime.now().toUtc());
      } else {
        await useCases.update(value);
      }
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ref.read(medicalPrescriptionUseCasesProvider).delete(id);
      await _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: '$error');
      return false;
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
    await load();
    unawaited(ref.read(syncManagerProvider.notifier).syncNow());
  }
}
