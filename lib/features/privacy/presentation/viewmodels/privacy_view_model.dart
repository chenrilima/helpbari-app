import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../data/services/privacy_export_file_saver.dart';
import '../providers/privacy_providers.dart';
import '../states/privacy_state.dart';

class PrivacyViewModel extends Notifier<PrivacyState> {
  @override
  PrivacyState build() => const PrivacyState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final useCases = ref.read(privacyUseCasesProvider);
      state = state.copyWith(
        consents: await useCases.getConsentHistory(),
        passwordRequired: useCases.passwordRequired,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Não foi possível carregar as informações de privacidade.',
      );
    }
  }

  Future<bool> acceptDocuments() async {
    try {
      await ref.read(privacyUseCasesProvider).acceptCurrentDocuments();
      unawaited(ref.read(syncManagerProvider.notifier).syncNow());
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Não foi possível registrar o aceite.',
      );
      return false;
    }
  }

  Future<void> exportData() async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final package = await ref.read(privacyExportServiceProvider).generate();
      final path = await savePrivacyExportFile(
        bytes: package.bytes,
        fileName: package.fileName,
      );
      state = state.copyWith(
        isExporting: false,
        exportedPath: path,
        successMessage: 'Exportação concluída e salva no dispositivo.',
      );
    } catch (_) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Não foi possível exportar seus dados.',
      );
    }
  }

  Future<bool> requestDefinitiveRemoval() async {
    try {
      await ref.read(privacyUseCasesProvider).requestDefinitiveRemoval();
      state = state.copyWith(
        successMessage: 'Solicitação registrada para análise.',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'É necessária conexão para registrar a solicitação.',
      );
      return false;
    }
  }

  Future<bool> deleteData({String? password}) =>
      _delete(account: false, password: password);
  Future<bool> deleteAccount({String? password}) =>
      _delete(account: true, password: password);

  Future<bool> _delete({required bool account, String? password}) async {
    state = state.copyWith(isDeleting: true, clearMessages: true);
    try {
      final service = await ref.read(privacyDeletionServiceProvider.future);
      if (account) {
        await service.deleteAccount(password: password);
      } else {
        await service.deleteData(password: password);
      }
      state = state.copyWith(isDeleting: false);
      return true;
    } catch (error) {
      ref
          .read(loggerServiceProvider)
          .warning('Privacy deletion failed (${error.runtimeType}).');
      state = state.copyWith(isDeleting: false, errorMessage: error.toString());
      return false;
    }
  }
}
