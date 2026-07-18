import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/supabase/storage/supabase_storage_provider.dart';
import '../../../bioimpedance/application/bioimpedance_document_parser.dart';
import '../../../medical_consultations/application/medical_consultation_document_parser.dart';
import '../../../medical_exams/application/medical_exam_document_parser.dart';
import '../../application/deterministic_document_classifier.dart';
import '../../application/document_processing_service.dart';
import '../../application/parsers/deterministic_parsers.dart';
import '../../data/datasources/ml_kit_document_text_extractor.dart';
import '../../data/repositories/drift_document_processing_repository.dart';
import '../../data/repositories/supabase_document_storage_gateway.dart';
import '../../domain/repositories/document_intelligence_contracts.dart';

final documentTextExtractorProvider = Provider<DocumentTextExtractor>((ref) {
  final extractor = MlKitDocumentTextExtractor();
  ref.onDispose(extractor.close);
  return extractor;
});

final documentProcessingServiceProvider = Provider<DocumentProcessingService>((
  ref,
) {
  return DocumentProcessingService(
    extractor: ref.watch(documentTextExtractorProvider),
    classifier: const DeterministicDocumentClassifier(),
    parsers: const [
      LabResultParser(),
      ConsultationNoteParser(),
      MedicalReportParser(),
      PrescriptionParser(),
      ExamRequestParser(),
      BioimpedanceDocumentParser(),
      MedicalExamDocumentParser(),
      MedicalConsultationDocumentParser(),
    ],
  );
});

final documentProcessingRepositoryProvider =
    FutureProvider<DocumentProcessingRepository>((ref) async {
      final database = await ref.watch(appDatabaseProvider.future);
      return DriftDocumentProcessingRepository(
        database.documentIntelligenceDao,
      );
    });

final documentStorageGatewayProvider = Provider<DocumentStorageGateway>((ref) {
  return SupabaseDocumentStorageGateway(ref.watch(supabaseStorageProvider));
});
