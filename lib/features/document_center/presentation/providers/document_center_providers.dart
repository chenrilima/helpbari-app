import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../document_intelligence/presentation/providers/document_intelligence_providers.dart';
import '../../application/document_center_service.dart';
import '../states/document_center_state.dart';
import '../viewmodels/document_center_view_model.dart';

final documentCenterServiceProvider = FutureProvider<DocumentCenterService>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('Usuário autenticado obrigatório para a Central.');
  }
  return DocumentCenterService(
    repository: await ref.read(documentProcessingRepositoryProvider.future),
    storage: ref.read(documentStorageGatewayProvider),
    processingService: ref.read(documentProcessingServiceProvider),
    clock: ref.read(clockServiceProvider),
    uuid: ref.read(uuidServiceProvider),
    logger: ref.read(loggerServiceProvider),
    userId: userId,
  );
});

final documentCenterViewModelProvider =
    NotifierProvider<DocumentCenterViewModel, DocumentCenterState>(
      DocumentCenterViewModel.new,
    );
