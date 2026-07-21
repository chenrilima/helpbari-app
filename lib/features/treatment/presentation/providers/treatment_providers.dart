import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../states/treatment_state.dart';
import '../viewmodels/treatment_view_model.dart';

final treatmentStoreProvider = Provider<UnifiedTreatmentStore>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  if (userId == null) {
    throw StateError('Authenticated user is required for treatment writes.');
  }
  return UnifiedTreatmentStore(
    database: ref.watch(appDatabaseProvider).requireValue,
    clock: ref.watch(clockServiceProvider),
    userId: userId,
  );
});

final treatmentViewModelProvider =
    NotifierProvider<TreatmentViewModel, TreatmentState>(
      TreatmentViewModel.new,
    );
