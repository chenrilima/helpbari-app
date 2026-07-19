import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../providers/document_center_providers.dart';
import '../states/document_center_state.dart';

class DocumentCenterPage extends ConsumerStatefulWidget {
  const DocumentCenterPage({super.key});

  @override
  ConsumerState<DocumentCenterPage> createState() => _DocumentCenterPageState();
}

class _DocumentCenterPageState extends ConsumerState<DocumentCenterPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(documentCenterViewModelProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetails(String documentId) async {
    await context.push(AppRoutes.documentCenterDetailsPath(documentId));
    if (!mounted) return;
    await ref.read(documentCenterViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentCenterViewModelProvider);
    final viewModel = ref.read(documentCenterViewModelProvider.notifier);
    final documents = state.filtered(viewModel.now);

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Carregando documentos...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Central de Documentos',
          subtitle: 'Revise, filtre e acompanhe seus documentos clínicos',
        ),
        children: [
          HBTextField(
            controller: _searchController,
            label: 'Buscar documentos',
            hint: 'Nome do arquivo, tipo do documento ou entidade relacionada',
            prefixIcon: Icons.search,
            onChanged: viewModel.setQuery,
          ),
          const HBGap.md(),
          HBCard(
            child: Column(
              children: [
                DropdownButtonFormField<DocumentCenterStatusFilter>(
                  initialValue: state.statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: DocumentCenterStatusFilter.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: HBText(_statusLabel(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) viewModel.setStatusFilter(value);
                  },
                ),
                const HBGap.md(),
                DropdownButtonFormField<String?>(
                  initialValue: state.typeFilter?.name,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: HBText('Todos'),
                    ),
                    ...DetectedDocumentType.values.map(
                      (value) => DropdownMenuItem<String?>(
                        value: value.name,
                        child: HBText(_typeLabel(value)),
                      ),
                    ),
                  ],
                  onChanged: viewModel.setTypeFilter,
                ),
                const HBGap.md(),
                DropdownButtonFormField<DocumentCenterPeriodFilter>(
                  initialValue: state.periodFilter,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: DocumentCenterPeriodFilter.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: HBText(_periodLabel(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) viewModel.setPeriodFilter(value);
                  },
                ),
                const HBGap.md(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected:
                          state.linkageFilter ==
                          DocumentCenterLinkageFilter.all,
                      onSelected: (_) => viewModel.setLinkageFilter(
                        DocumentCenterLinkageFilter.all,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Vinculados'),
                      selected:
                          state.linkageFilter ==
                          DocumentCenterLinkageFilter.linkedOnly,
                      onSelected: (_) => viewModel.setLinkageFilter(
                        DocumentCenterLinkageFilter.linkedOnly,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Órfãos'),
                      selected:
                          state.linkageFilter ==
                          DocumentCenterLinkageFilter.orphanOnly,
                      onSelected: (_) => viewModel.setLinkageFilter(
                        DocumentCenterLinkageFilter.orphanOnly,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Agrupar por data'),
                      selected: state.groupByDate,
                      onSelected: viewModel.toggleGrouping,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const HBGap.md(),
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar os documentos',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: viewModel.load,
            )
          else if (!state.hasDocuments)
            const HBEmptyState(
              title: 'Nenhum documento importado',
              description:
                  'Quando você analisar um exame, consulta ou bioimpedância, ele aparecerá aqui.',
              icon: Icons.folder_open_outlined,
            )
          else if (documents.isEmpty)
            const HBEmptyState(
              title: 'Nenhum documento nos filtros',
              description:
                  'Ajuste a busca, o período ou os filtros de status e vínculo.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            _DocumentList(
              documents: documents,
              groupByDate: state.groupByDate,
              onTap: _openDetails,
            ),
        ],
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.groupByDate,
    required this.onTap,
  });

  final List<ManagedDocumentRecord> documents;
  final bool groupByDate;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final entries = groupByDate ? _group(documents) : {'Todos': documents};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries.entries) ...[
          if (groupByDate) ...[
            HBText(entry.key, style: Theme.of(context).textTheme.titleMedium),
            const HBGap.sm(),
          ],
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            separatorBuilder: (_, _) => const HBGap.md(),
            itemBuilder: (_, index) {
              final document = entry.value[index];
              final processing = document.latestProcessing;
              return HBCard(
                onTap: () => onTap(document.document.id),
                semanticLabel:
                    '${document.document.fileName}. ${_typeLabel(processing?.detectedType ?? DetectedDocumentType.unknown)}. ${_statusText(processing?.status)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HBText(
                      document.document.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const HBGap.xs(),
                    HBText(
                      '${_typeLabel(processing?.detectedType ?? DetectedDocumentType.unknown)} • ${_statusText(processing?.status)}',
                    ),
                    const HBGap.xs(),
                    HBText(
                      'Capturado em ${AppDateFormatter.shortWithTime(document.document.capturedAt)}',
                    ),
                    const HBGap.xs(),
                    HBText(
                      '${_fileSize(document.document.fileSize)} • ${document.extractedFieldCount} campo(s)',
                    ),
                    if (document.links.isNotEmpty) ...[
                      const HBGap.sm(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: document.links
                            .map((link) => Chip(label: Text(link.title)))
                            .toList(growable: false),
                      ),
                    ] else ...[
                      const HBGap.sm(),
                      const HBText('Documento órfão'),
                    ],
                  ],
                ),
              );
            },
          ),
          const HBGap.lg(),
        ],
      ],
    );
  }

  Map<String, List<ManagedDocumentRecord>> _group(
    List<ManagedDocumentRecord> values,
  ) {
    final result = <String, List<ManagedDocumentRecord>>{};
    for (final value in values) {
      final date = value.document.capturedAt;
      final key = AppDateFormatter.short(
        DateTime(date.year, date.month, date.day),
      );
      result.putIfAbsent(key, () => <ManagedDocumentRecord>[]).add(value);
    }
    return result;
  }
}

String _statusLabel(DocumentCenterStatusFilter value) => switch (value) {
  DocumentCenterStatusFilter.all => 'Todos',
  DocumentCenterStatusFilter.pending => 'Pendente',
  DocumentCenterStatusFilter.processing => 'Processando',
  DocumentCenterStatusFilter.requiresReview => 'Aguardando revisão',
  DocumentCenterStatusFilter.processed => 'Processado',
  DocumentCenterStatusFilter.confirmed => 'Confirmado',
  DocumentCenterStatusFilter.failed => 'Falhou',
  DocumentCenterStatusFilter.unknown => 'Desconhecido',
};

String _periodLabel(DocumentCenterPeriodFilter value) => switch (value) {
  DocumentCenterPeriodFilter.all => 'Todo o período',
  DocumentCenterPeriodFilter.last7Days => 'Últimos 7 dias',
  DocumentCenterPeriodFilter.last30Days => 'Últimos 30 dias',
  DocumentCenterPeriodFilter.last90Days => 'Últimos 90 dias',
};

String _statusText(ProcessingStatus? value) => switch (value) {
  ProcessingStatus.pending => 'Pendente',
  ProcessingStatus.processing => 'Processando',
  ProcessingStatus.processed => 'Processado',
  ProcessingStatus.requiresReview => 'Aguardando revisão',
  ProcessingStatus.confirmed => 'Confirmado',
  ProcessingStatus.failed => 'Falhou',
  null => 'Desconhecido',
};

String _typeLabel(DetectedDocumentType value) => switch (value) {
  DetectedDocumentType.labResult => 'Resultado de exame',
  DetectedDocumentType.medicalExamReport => 'Laudo de exame',
  DetectedDocumentType.medicalConsultation => 'Consulta médica',
  DetectedDocumentType.consultationNote => 'Anotação de consulta',
  DetectedDocumentType.medicalReport => 'Relatório',
  DetectedDocumentType.prescription => 'Receita',
  DetectedDocumentType.examRequest => 'Pedido de exames',
  DetectedDocumentType.bioimpedanceReport => 'Bioimpedância',
  DetectedDocumentType.unknown => 'Desconhecido',
};

String _fileSize(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  return '$value B';
}
