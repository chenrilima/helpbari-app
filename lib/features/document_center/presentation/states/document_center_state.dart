import '../../../document_intelligence/domain/entities/document_models.dart';

enum DocumentCenterStatusFilter {
  all,
  pending,
  processing,
  requiresReview,
  processed,
  confirmed,
  failed,
  unknown,
}

enum DocumentCenterLinkageFilter { all, linkedOnly, orphanOnly }

enum DocumentCenterPeriodFilter { all, last7Days, last30Days, last90Days }

class DocumentCenterState {
  const DocumentCenterState({
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
    this.query = '',
    this.statusFilter = DocumentCenterStatusFilter.all,
    this.typeFilter,
    this.linkageFilter = DocumentCenterLinkageFilter.all,
    this.periodFilter = DocumentCenterPeriodFilter.all,
    this.groupByDate = true,
  });

  final List<ManagedDocumentRecord> documents;
  final bool isLoading;
  final String? errorMessage;
  final String query;
  final DocumentCenterStatusFilter statusFilter;
  final DetectedDocumentType? typeFilter;
  final DocumentCenterLinkageFilter linkageFilter;
  final DocumentCenterPeriodFilter periodFilter;
  final bool groupByDate;

  bool get hasDocuments => documents.isNotEmpty;

  List<ManagedDocumentRecord> filtered(DateTime now) {
    final normalizedQuery = query.trim().toLowerCase();
    final start = switch (periodFilter) {
      DocumentCenterPeriodFilter.all => null,
      DocumentCenterPeriodFilter.last7Days => now.subtract(
        const Duration(days: 7),
      ),
      DocumentCenterPeriodFilter.last30Days => now.subtract(
        const Duration(days: 30),
      ),
      DocumentCenterPeriodFilter.last90Days => now.subtract(
        const Duration(days: 90),
      ),
    };
    return documents
        .where((document) {
          final processing = document.latestProcessing;
          if (statusFilter != DocumentCenterStatusFilter.all) {
            final matchesStatus = switch (statusFilter) {
              DocumentCenterStatusFilter.pending =>
                processing?.status == ProcessingStatus.pending,
              DocumentCenterStatusFilter.processing =>
                processing?.status == ProcessingStatus.processing,
              DocumentCenterStatusFilter.requiresReview =>
                processing?.status == ProcessingStatus.requiresReview,
              DocumentCenterStatusFilter.processed =>
                processing?.status == ProcessingStatus.processed,
              DocumentCenterStatusFilter.confirmed =>
                processing?.status == ProcessingStatus.confirmed,
              DocumentCenterStatusFilter.failed =>
                processing?.status == ProcessingStatus.failed,
              DocumentCenterStatusFilter.unknown => processing == null,
              DocumentCenterStatusFilter.all => true,
            };
            if (!matchesStatus) return false;
          }
          if (typeFilter != null && processing?.detectedType != typeFilter) {
            return false;
          }
          if (linkageFilter == DocumentCenterLinkageFilter.linkedOnly &&
              document.isOrphan) {
            return false;
          }
          if (linkageFilter == DocumentCenterLinkageFilter.orphanOnly &&
              !document.isOrphan) {
            return false;
          }
          if (start != null && document.document.capturedAt.isBefore(start)) {
            return false;
          }
          if (normalizedQuery.isEmpty) return true;
          final haystack = <String>[
            document.document.fileName,
            document.document.mimeType,
            processing?.detectedType.name ?? '',
            processing?.status.name ?? '',
            for (final link in document.links) ...[
              link.title,
              link.subtitle ?? '',
              link.type.name,
            ],
          ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  DocumentCenterState copyWith({
    List<ManagedDocumentRecord>? documents,
    bool? isLoading,
    String? errorMessage,
    String? query,
    DocumentCenterStatusFilter? statusFilter,
    DetectedDocumentType? typeFilter,
    bool clearTypeFilter = false,
    DocumentCenterLinkageFilter? linkageFilter,
    DocumentCenterPeriodFilter? periodFilter,
    bool? groupByDate,
    bool clearError = false,
  }) => DocumentCenterState(
    documents: documents ?? this.documents,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    query: query ?? this.query,
    statusFilter: statusFilter ?? this.statusFilter,
    typeFilter: clearTypeFilter ? null : typeFilter ?? this.typeFilter,
    linkageFilter: linkageFilter ?? this.linkageFilter,
    periodFilter: periodFilter ?? this.periodFilter,
    groupByDate: groupByDate ?? this.groupByDate,
  );
}
