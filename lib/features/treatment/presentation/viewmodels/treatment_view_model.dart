import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/bootstrap/notification_bootstrap_provider.dart';
import '../../../../core/errors/presentation_error_mapper.dart';
import '../../../../core/sync/sync.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../providers/treatment_providers.dart';
import '../states/treatment_state.dart';

final class TreatmentViewModel extends Notifier<TreatmentState> {
  UnifiedTreatmentStore get _store => ref.read(treatmentStoreProvider);

  @override
  TreatmentState build() => const TreatmentState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(items: await _store.listItems(), isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: PresentationErrorMapper.message(
          error,
          fallback: 'Não foi possível carregar seu tratamento.',
        ),
      );
    }
  }

  Future<TreatmentChangeImpact> impactFor(TreatmentWriteCommand command) =>
      _store.impactFor(command);

  Future<bool> save(TreatmentWriteCommand command) => _mutate(
    () => _store.write(command),
    fallback: 'Não foi possível salvar o item.',
  );

  Future<bool> pause(String id) => _mutate(
    () => _store.pause(id),
    fallback: 'Não foi possível pausar o item.',
  );

  Future<bool> resume(String id) => _mutate(
    () => _store.resume(id),
    fallback: 'Não foi possível retomar o item.',
  );

  Future<bool> complete(String id) => _mutate(
    () => _store.complete(id),
    fallback: 'Não foi possível concluir o item.',
  );

  Future<bool> delete(String id) => _mutate(
    () => _store.softDelete(id),
    fallback: 'Não foi possível excluir o item.',
  );

  Future<bool> registerPrnUse({
    required String id,
    required DateTime occurredAt,
    String? note,
  }) => _mutate(
    () => _store.registerPrnUse(
      routineId: id,
      occurredAt: occurredAt,
      note: note,
    ),
    fallback: 'Não foi possível registrar o uso.',
  );

  Future<bool> resolveConflict({
    required String occurrenceId,
    required String keepEventId,
  }) => _mutate(
    () => _store.resolveConflict(
      occurrenceId: occurrenceId,
      keepEventId: keepEventId,
    ),
    fallback: 'Não foi possível resolver o conflito.',
  );

  Future<bool> _mutate(
    Future<void> Function() operation, {
    required String fallback,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await operation();
      ref.invalidate(treatmentAdherenceQueryServiceProvider);
      await load();
      ref.read(notificationBootstrapProvider).reconcileTreatmentChange();
      unawaited(
        ref
            .read(syncManagerProvider.notifier)
            .syncNow()
            .catchError((Object _, StackTrace _) => null),
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: PresentationErrorMapper.message(
          error,
          fallback: fallback,
        ),
      );
      return false;
    }
  }
}
