import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../academy/presentation/providers/academy_providers.dart';
import '../../application/baria_service.dart';
import '../../data/repositories/contextual_baria_repository.dart';
import '../../domain/repositories/baria_repository.dart';
import '../../domain/usecases/baria_use_cases.dart';
import '../../domain/ports/baria_treatment_context_port.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';

final bariaServiceProvider = Provider<BariaService>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  if (userId == null) {
    throw StateError('Authenticated user is required for BarIA.');
  }
  return BariaService(
    intelligence: () => ref.read(todayDashboardProvider.future),
    clock: ref.watch(clockServiceProvider),
    syncState: () => ref.read(syncManagerProvider),
    userId: userId,
    knowledge: ref.watch(knowledgeUseCasesProvider),
    treatment: QueryServiceBariaTreatmentContextPort(
      () => ref.read(treatmentAdherenceQueryServiceProvider.future),
    ),
  );
});

final bariaRepositoryProvider = Provider<BariaRepository>(
  (ref) => ContextualBariaRepository(ref.watch(bariaServiceProvider)),
);

final bariaUseCasesProvider = Provider<BariaUseCases>(
  (ref) => BariaUseCases(ref.watch(bariaRepositoryProvider)),
);
