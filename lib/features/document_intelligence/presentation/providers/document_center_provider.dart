import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../medical_prescriptions/presentation/providers/medical_prescription_providers.dart';
import '../../data/repositories/drift_document_center_repository.dart';
import '../../domain/entities/document_center_entry.dart';

final documentCenterProvider = FutureProvider<List<DocumentCenterEntry>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final prescriptions = await ref
      .watch(medicalPrescriptionUseCasesProvider)
      .getAll();
  final links = <String, String>{
    for (final value in prescriptions)
      if (value.sourceDocumentId != null) value.sourceDocumentId!: value.id,
  };
  return DriftDocumentCenterRepository(
    (await ref.watch(appDatabaseProvider.future)).documentIntelligenceDao,
  ).getAll(userId: userId, prescriptionIdsByDocument: links);
});
