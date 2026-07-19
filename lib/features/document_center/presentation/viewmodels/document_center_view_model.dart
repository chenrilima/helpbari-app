import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../privacy/presentation/providers/privacy_providers.dart';
import '../../application/document_center_service.dart';
import '../providers/document_center_providers.dart';
import '../states/document_center_state.dart';

class DocumentCenterViewModel extends Notifier<DocumentCenterState> {
  StreamSubscription<List<ManagedDocumentRecord>>? _subscription;

  @override
  DocumentCenterState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const DocumentCenterState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = await ref.read(documentCenterServiceProvider.future);
      final items = await service.getDocuments();
      await _subscription?.cancel();
      _subscription = service.watchDocuments().listen((documents) {
        state = state.copyWith(documents: documents, isLoading: false);
      });
      state = state.copyWith(documents: items, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setStatusFilter(DocumentCenterStatusFilter value) {
    state = state.copyWith(statusFilter: value);
  }

  void setTypeFilter(String? value) {
    if (value == null || value.isEmpty) {
      state = state.copyWith(clearTypeFilter: true);
      return;
    }
    state = state.copyWith(
      typeFilter: DetectedDocumentType.values.byName(value),
    );
  }

  void setLinkageFilter(DocumentCenterLinkageFilter value) {
    state = state.copyWith(linkageFilter: value);
  }

  void setPeriodFilter(DocumentCenterPeriodFilter value) {
    state = state.copyWith(periodFilter: value);
  }

  void toggleGrouping(bool value) {
    state = state.copyWith(groupByDate: value);
  }

  Future<void> deleteDocument(String documentId) async {
    await _mutate((service) => service.deleteDocument(documentId));
  }

  Future<void> retryDocument(String documentId) async {
    await _mutate((service) => service.retryProcessing(documentId));
  }

  Future<void> reprocessDocument(String documentId) async {
    await _mutate((service) => service.reprocessDocument(documentId));
  }

  Future<void> _mutate(
    Future<dynamic> Function(DocumentCenterService service) action,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = await ref.read(documentCenterServiceProvider.future);
      await action(service);
      await _refreshAfterMutation();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  Future<void> _refreshAfterMutation() async {
    ref.invalidate(documentCenterServiceProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(privacyExportServiceProvider);
    state = state.copyWith(isLoading: false);
    unawaited(ref.read(syncManagerProvider.notifier).syncNow());
    await load();
  }

  DateTime get now => ref.read(clockServiceProvider).now();
}
