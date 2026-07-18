import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../../core/sync/sync.dart';
import '../../../../design_system/design_system.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_exam_view_model_provider.dart';

class RegisterMedicalExamPage extends ConsumerStatefulWidget {
  const RegisterMedicalExamPage({super.key, this.exam});

  final MedicalExam? exam;

  @override
  ConsumerState<RegisterMedicalExamPage> createState() =>
      _RegisterMedicalExamPageState();
}

class _RegisterMedicalExamPageState
    extends ConsumerState<RegisterMedicalExamPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _laboratoryController;
  late final TextEditingController _professionalController;
  late final TextEditingController _notesController;
  late DateTime _performedAt;
  bool _isSubmitting = false;
  String? _confirmedDocumentId;
  late List<_EditableResultRow> _rows;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _titleController = TextEditingController(text: exam?.title);
    _laboratoryController = TextEditingController(text: exam?.laboratoryName);
    _professionalController = TextEditingController(
      text: exam?.professionalName,
    );
    _notesController = TextEditingController(text: exam?.notes);
    _performedAt = exam?.performedAt ?? ref.read(clockServiceProvider).now();
    _rows =
        exam?.results
            .where((item) => item.deletedAt == null)
            .map(_EditableResultRow.fromEntity)
            .toList(growable: true) ??
        [_EditableResultRow.empty()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _laboratoryController.dispose();
    _professionalController.dispose();
    _notesController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockServiceProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null) return;
    setState(() {
      _performedAt = DateTime(
        date.year,
        date.month,
        date.day,
        _performedAt.hour,
        _performedAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final exam = _buildExam();
    if (!exam.hasAnyContent) {
      HBSnackBar.error(
        context,
        message: 'Informe um título ou ao menos um resultado válido.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(medicalExamViewModelProvider.notifier)
        .save(exam);
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(medicalExamViewModelProvider).errorMessage ??
            'Não foi possível salvar o exame.',
      );
      return;
    }

    HBSnackBar.success(
      context,
      message: _isEditing
          ? 'Exame atualizado com sucesso.'
          : 'Exame cadastrado com sucesso.',
    );
    context.pop(true);
  }

  MedicalExam _buildExam() {
    final existing = widget.exam;
    final now = ref.read(clockServiceProvider).now().toUtc();
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    final results = <MedicalExamResult>[];
    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index];
      final entity = row.toEntity(
        examId: existing?.id ?? ref.read(uuidServiceProvider).generate(),
        existing: existing?.results
            .where((item) => item.deletedAt == null)
            .elementAtOrNull(index),
        index: index,
        now: now,
      );
      if (entity != null) {
        results.add(entity);
      }
    }

    final examId = existing?.id ?? ref.read(uuidServiceProvider).generate();
    final normalizedResults = results
        .map((item) => item.copyWith(medicalExamId: examId))
        .toList(growable: false);

    return MedicalExam(
      id: examId,
      userId: userId,
      performedAt: _performedAt,
      title: _emptyToNull(_titleController.text),
      examCategory: _guessCategory(normalizedResults),
      laboratoryName: _emptyToNull(_laboratoryController.text),
      professionalName: _emptyToNull(_professionalController.text),
      notes: _emptyToNull(_notesController.text),
      sourceDocumentId: existing?.sourceDocumentId ?? _confirmedDocumentId,
      legacyAttachmentPath: existing?.legacyAttachmentPath,
      source: _confirmedDocumentId != null
          ? MedicalExamSource.document
          : (existing?.source ?? MedicalExamSource.manual),
      results: normalizedResults,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
      syncStatus: existing?.syncStatus ?? SyncStatus.pendingCreate,
    );
  }

  void _applyDocumentFields(
    DetectedDocumentType type,
    List<ExtractedField> fields,
  ) {
    if (type != DetectedDocumentType.medicalExamReport &&
        type != DetectedDocumentType.labResult) {
      HBSnackBar.error(
        context,
        message: 'O documento analisado não parece ser um resultado de exame.',
      );
      return;
    }

    final title = _field(fields, 'title');
    final laboratory = _field(fields, 'laboratory');
    final professional = _field(fields, 'professional');
    final performedAt = _field(fields, 'performedAt');
    if (title != null && _titleController.text.trim().isEmpty) {
      _titleController.text = title;
    }
    if (laboratory != null && _laboratoryController.text.trim().isEmpty) {
      _laboratoryController.text = laboratory;
    }
    if (professional != null && _professionalController.text.trim().isEmpty) {
      _professionalController.text = professional;
    }
    final parsedDate = _parseDate(performedAt);
    if (parsedDate != null) {
      _performedAt = parsedDate;
    }

    final grouped = <int, Map<String, String?>>{};
    for (final field in fields) {
      final match = RegExp(r'^result_(\d+)_(.+)$').firstMatch(field.key);
      if (match == null) continue;
      final index = int.parse(match.group(1)!);
      final entry = grouped.putIfAbsent(index, () => {});
      entry[match.group(2)!] =
          field.confirmedValue ?? field.normalizedValue ?? field.rawValue;
    }

    if (grouped.isNotEmpty) {
      for (final row in _rows) {
        row.dispose();
      }
      final sortedEntries = grouped.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      _rows = sortedEntries
          .map((entry) => _EditableResultRow.fromDocument(entry.value))
          .toList(growable: true);
      if (_rows.isEmpty) {
        _rows = [_EditableResultRow.empty()];
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando exame...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing ? 'Editar exame' : 'Cadastrar exame',
          subtitle: 'Registre resultados manualmente ou via documento',
        ),
        children: [
          DocumentImportCard(
            onConfirmed: _applyDocumentFields,
            onProcessingConfirmed: (processing) {
              _confirmedDocumentId = processing.documentId;
            },
          ),
          const HBGap.xl(),
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HBTextField(
                    controller: _titleController,
                    label: 'Título do exame',
                    hint: 'Ex: Check-up anual',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _laboratoryController,
                    label: 'Laboratório',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _professionalController,
                    label: 'Profissional responsável',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Data: ${AppDateFormatter.short(_performedAt)}',
                    onPressed: _pickDate,
                  ),
                  const HBGap.lg(),
                  HBSection(
                    title: 'Resultados',
                    child: Column(
                      children: [
                        for (var index = 0; index < _rows.length; index++) ...[
                          _ResultRowCard(
                            row: _rows[index],
                            index: index,
                            onRemove: _rows.length == 1
                                ? null
                                : () {
                                    final row = _rows.removeAt(index);
                                    row.dispose();
                                    setState(() {});
                                  },
                          ),
                          const HBGap.md(),
                        ],
                        HBButton(
                          label: 'Adicionar marcador',
                          onPressed: () {
                            setState(
                              () => _rows.add(_EditableResultRow.empty()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const HBGap.lg(),
                  HBTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 4,
                    inputFormatters: AppInputFormatters.text(maxLength: 500),
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing ? 'Salvar alterações' : 'Salvar exame',
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _field(List<ExtractedField> fields, String key) {
    for (final field in fields) {
      if (field.key == key) {
        return field.confirmedValue ?? field.normalizedValue ?? field.rawValue;
      }
    }
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{2,4})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final yearRaw = int.tryParse(match.group(3)!);
    if (day == null || month == null || yearRaw == null) return null;
    final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
    return DateTime(year, month, day, _performedAt.hour, _performedAt.minute);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  MedicalExamCategory? _guessCategory(List<MedicalExamResult> results) {
    final categories = <MedicalExamCategory, int>{};
    for (final result in results) {
      final category = result.category;
      if (category == null) continue;
      categories.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    if (categories.isEmpty) return null;
    return categories.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _ResultRowCard extends StatelessWidget {
  const _ResultRowCard({
    required this.row,
    required this.index,
    required this.onRemove,
  });

  final _EditableResultRow row;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HBText(
                  'Marcador ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          HBTextField(
            controller: row.nameController,
            label: 'Nome do marcador',
            inputFormatters: AppInputFormatters.text(maxLength: 120),
          ),
          const HBGap.md(),
          HBTextField(
            controller: row.valueController,
            label: 'Valor',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: AppInputFormatters.decimal(),
          ),
          const HBGap.md(),
          HBTextField(
            controller: row.unitController,
            label: 'Unidade',
            inputFormatters: AppInputFormatters.text(maxLength: 24),
          ),
          const HBGap.md(),
          HBTextField(
            controller: row.referenceController,
            label: 'Valor de referência',
            inputFormatters: AppInputFormatters.text(maxLength: 60),
          ),
        ],
      ),
    );
  }
}

class _EditableResultRow {
  _EditableResultRow({
    required this.id,
    required this.nameController,
    required this.valueController,
    required this.unitController,
    required this.referenceController,
    this.canonicalCode,
    this.category,
  });

  final String id;
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController referenceController;
  final String? canonicalCode;
  final MedicalExamCategory? category;

  factory _EditableResultRow.empty() => _EditableResultRow(
    id: UniqueKey().toString(),
    nameController: TextEditingController(),
    valueController: TextEditingController(),
    unitController: TextEditingController(),
    referenceController: TextEditingController(),
  );

  factory _EditableResultRow.fromEntity(MedicalExamResult result) =>
      _EditableResultRow(
        id: result.id,
        nameController: TextEditingController(text: result.displayName),
        valueController: TextEditingController(
          text:
              result.numericValue?.toString() ??
              result.textValue ??
              result.qualitativeValue ??
              '',
        ),
        unitController: TextEditingController(
          text: result.normalizedUnit ?? result.unit ?? '',
        ),
        referenceController: TextEditingController(
          text: result.referenceRangeText ?? '',
        ),
        canonicalCode: result.canonicalCode,
        category: result.category,
      );

  factory _EditableResultRow.fromDocument(Map<String, String?> values) {
    final categoryRaw = values['category'];
    return _EditableResultRow(
      id: UniqueKey().toString(),
      nameController: TextEditingController(text: values['name'] ?? ''),
      valueController: TextEditingController(text: values['value'] ?? ''),
      unitController: TextEditingController(text: values['unit'] ?? ''),
      referenceController: TextEditingController(
        text: values['reference'] ?? '',
      ),
      canonicalCode: values['canonical_code'],
      category: MedicalExamCategory.values
          .where((item) => item.name == categoryRaw)
          .firstOrNull,
    );
  }

  MedicalExamResult? toEntity({
    required String examId,
    required MedicalExamResult? existing,
    required int index,
    required DateTime now,
  }) {
    final rawName = nameController.text.trim();
    final rawValue = valueController.text.trim();
    final rawUnit = unitController.text.trim();
    final rawReference = referenceController.text.trim();
    if (rawName.isEmpty &&
        rawValue.isEmpty &&
        rawUnit.isEmpty &&
        rawReference.isEmpty) {
      return null;
    }

    final marker = MedicalExamMarkerCatalog.match(rawName);
    final normalizedName = marker?.canonicalName ?? rawName;
    final numericValue = _parseDouble(rawValue);
    final valueType = numericValue != null
        ? MedicalExamValueType.numeric
        : (rawValue.isEmpty
              ? MedicalExamValueType.unknown
              : MedicalExamValueType.text);

    return MedicalExamResult(
      id: existing?.id ?? UniqueKey().toString(),
      medicalExamId: examId,
      canonicalCode: canonicalCode ?? marker?.canonicalCode,
      canonicalName: normalizedName,
      displayName: rawName,
      normalizedName: normalizedName.toLowerCase(),
      category: category ?? marker?.category,
      valueType: valueType,
      numericValue: numericValue,
      textValue: numericValue == null && rawValue.isNotEmpty ? rawValue : null,
      booleanValue: null,
      qualitativeValue: null,
      unit: rawUnit.isEmpty ? null : rawUnit,
      normalizedUnit: rawUnit.isEmpty ? null : rawUnit,
      referenceRangeText: rawReference.isEmpty ? null : rawReference,
      referenceMin: null,
      referenceMax: null,
      referenceComparator: null,
      referenceContext: null,
      status: null,
      method: null,
      specimen: null,
      notes: null,
      originalText: null,
      source: marker != null
          ? MedicalExamResultSource.normalizedCatalog
          : MedicalExamResultSource.manual,
      confidence: null,
      sortOrder: index,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
      syncStatus: existing?.syncStatus ?? SyncStatus.pendingCreate,
    );
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll('.', '').replaceAll(',', '.')) ??
        double.tryParse(trimmed.replaceAll(',', '.'));
  }

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
    referenceController.dispose();
  }
}
