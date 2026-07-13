import '../../domain/entities/entities.dart';

abstract interface class KnowledgeContentDatasource {
  Future<KnowledgeCatalog> loadCatalog();
}
