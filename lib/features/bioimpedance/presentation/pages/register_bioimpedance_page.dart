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
import '../../domain/entities/bioimpedance_record.dart';
import '../providers/bioimpedance_view_model_provider.dart';

class RegisterBioimpedancePage extends ConsumerStatefulWidget {
  const RegisterBioimpedancePage({super.key, this.record});

  final BioimpedanceRecord? record;

  @override
  ConsumerState<RegisterBioimpedancePage> createState() =>
      _RegisterBioimpedancePageState();
}

class _RegisterBioimpedancePageState
    extends ConsumerState<RegisterBioimpedancePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _weightController;
  late final TextEditingController _muscleMassController;
  late final TextEditingController _bodyFatMassController;
  late final TextEditingController _bodyWaterPercentageController;
  late final TextEditingController _bodyFatPercentageController;
  late final TextEditingController _bmiController;
  late final TextEditingController _deviceNameController;
  late final TextEditingController _clinicNameController;
  late final TextEditingController _professionalNameController;
  late final TextEditingController _notesController;

  late DateTime _measuredAt;
  bool _isSubmitting = false;
  bool _showOptional = false;
  String? _confirmedDocumentId;
  Map<String, ExtractedField> _documentFieldsByKey = const {};

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _weightController = TextEditingController(text: _format(record?.weightKg));
    _muscleMassController = TextEditingController(
      text: _format(record?.muscleMassKg),
    );
    _bodyFatMassController = TextEditingController(
      text: _format(record?.bodyFatMassKg),
    );
    _bodyWaterPercentageController = TextEditingController(
      text: _format(record?.bodyWaterPercentage),
    );
    _bodyFatPercentageController = TextEditingController(
      text: _format(record?.bodyFatPercentage),
    );
    _bmiController = TextEditingController(text: _format(record?.bmi));
    _deviceNameController = TextEditingController(text: record?.deviceName);
    _clinicNameController = TextEditingController(text: record?.clinicName);
    _professionalNameController = TextEditingController(
      text: record?.professionalName,
    );
    _notesController = TextEditingController(text: record?.notes);
    _measuredAt = record?.measuredAt ?? ref.read(clockServiceProvider).now();
    _showOptional =
        record?.bodyFatPercentage != null ||
        record?.bmi != null ||
        record?.deviceName != null ||
        record?.clinicName != null ||
        record?.professionalName != null ||
        record?.notes != null;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _muscleMassController.dispose();
    _bodyFatMassController.dispose();
    _bodyWaterPercentageController.dispose();
    _bodyFatPercentageController.dispose();
    _bmiController.dispose();
    _deviceNameController.dispose();
    _clinicNameController.dispose();
    _professionalNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockServiceProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null) return;
    setState(() {
      _measuredAt = DateTime(
        date.year,
        date.month,
        date.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (time == null) return;
    setState(() {
      _measuredAt = DateTime(
        _measuredAt.year,
        _measuredAt.month,
        _measuredAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final record = _buildRecord();
    if (!record.hasAnyMeasurement ||
        (record.weightKg == null &&
            record.muscleMassKg == null &&
            record.bodyFatMassKg == null &&
            record.bodyWaterPercentage == null)) {
      HBSnackBar.error(
        context,
        message: 'Informe a data e pelo menos uma medida principal.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(bioimpedanceViewModelProvider.notifier)
        .saveRecord(record);
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(bioimpedanceViewModelProvider).errorMessage ??
            'Não foi possível salvar a avaliação.',
      );
      return;
    }
    HBSnackBar.success(
      context,
      message: _isEditing
          ? 'Avaliação atualizada com sucesso.'
          : 'Avaliação salva com sucesso.',
    );
    context.pop(true);
  }

  BioimpedanceRecord _buildRecord() {
    final existing = widget.record;
    final now = ref.read(clockServiceProvider).now().toUtc();
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    final additionalMetrics = {
      ...?existing?.additionalMetrics,
      ..._documentAdditionalMetrics(),
    };
    return BioimpedanceRecord(
      id: existing?.id ?? ref.read(uuidServiceProvider).generate(),
      userId: userId,
      measuredAt: _measuredAt,
      weightKg: _parse(_weightController.text) ?? _documentDouble('weightKg'),
      muscleMassKg:
          _parse(_muscleMassController.text) ?? _documentDouble('muscleMassKg'),
      bodyFatMassKg:
          _parse(_bodyFatMassController.text) ??
          _documentDouble('bodyFatMassKg'),
      bodyWaterPercentage:
          _parse(_bodyWaterPercentageController.text) ??
          _documentDouble('bodyWaterPercentage'),
      bodyFatPercentage:
          _parse(_bodyFatPercentageController.text) ??
          _documentDouble('bodyFatPercentage'),
      skeletalMuscleMassKg: _documentDouble('skeletalMuscleMassKg'),
      leanBodyMassKg: _documentDouble('leanBodyMassKg'),
      fatFreeMassKg: _documentDouble('fatFreeMassKg'),
      visceralFatLevel: _documentDouble('visceralFatLevel'),
      basalMetabolicRateKcal: _documentDouble('basalMetabolicRateKcal'),
      metabolicAge: _documentInt('metabolicAge'),
      waistHipRatio: _documentDouble('waistHipRatio'),
      phaseAngleDegrees: _documentDouble('phaseAngleDegrees'),
      proteinPercentage: _documentDouble('proteinPercentage'),
      mineralMassKg: _documentDouble('mineralMassKg'),
      weightControlKg: _documentDouble('weightControlKg'),
      fatControlKg: _documentDouble('fatControlKg'),
      muscleControlKg: _documentDouble('muscleControlKg'),
      bmi: _parse(_bmiController.text) ?? _documentDouble('bmi'),
      deviceName: _emptyToNull(_deviceNameController.text),
      clinicName: _emptyToNull(_clinicNameController.text),
      professionalName: _emptyToNull(_professionalNameController.text),
      notes: _emptyToNull(_notesController.text),
      sourceDocumentId: existing?.sourceDocumentId ?? _confirmedDocumentId,
      source: _confirmedDocumentId != null
          ? BioimpedanceRecordSource.document
          : (existing?.source ?? BioimpedanceRecordSource.manual),
      additionalMetrics: additionalMetrics,
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
    if (type != DetectedDocumentType.bioimpedanceReport) {
      HBSnackBar.error(
        context,
        message:
            'O documento analisado não parece ser um laudo de bioimpedância.',
      );
      return;
    }
    _fill(_weightController, fields, 'weightKg');
    _fill(_muscleMassController, fields, 'muscleMassKg');
    _fill(_bodyFatMassController, fields, 'bodyFatMassKg');
    _fill(_bodyWaterPercentageController, fields, 'bodyWaterPercentage');
    _fill(_bodyFatPercentageController, fields, 'bodyFatPercentage');
    _fill(_bmiController, fields, 'bmi');
    final date = _field(fields, 'measuredAt');
    if (date != null) {
      final parsed = _parseDate(date);
      if (parsed != null) {
        setState(() => _measuredAt = parsed);
      }
    }
    setState(() {
      _documentFieldsByKey = {for (final field in fields) field.key: field};
      _showOptional = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando avaliação...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing
              ? 'Editar bioimpedância'
              : 'Cadastrar bioimpedância',
          subtitle: 'Registre avaliação manual ou via documento',
        ),
        children: [
          DocumentImportCard(
            onConfirmed: _applyDocumentFields,
            onProcessingConfirmed: (processing) =>
                _confirmedDocumentId = processing.documentId,
          ),
          const HBGap.xl(),
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HBSection(
                    title: 'Informações da avaliação',
                    child: Column(
                      children: [
                        HBButton(
                          label: 'Data: ${AppDateFormatter.short(_measuredAt)}',
                          onPressed: _pickDate,
                        ),
                        const HBGap.md(),
                        HBButton(
                          label:
                              'Hora: ${TimeOfDay.fromDateTime(_measuredAt).format(context)}',
                          onPressed: _pickTime,
                        ),
                      ],
                    ),
                  ),
                  const HBGap.lg(),
                  HBSection(
                    title: 'Dados principais',
                    child: Column(
                      children: [
                        _numberField(_weightController, 'Peso (kg)'),
                        const HBGap.md(),
                        _numberField(
                          _muscleMassController,
                          'Massa muscular (kg)',
                        ),
                        const HBGap.md(),
                        _numberField(
                          _bodyFatMassController,
                          'Massa de gordura (kg)',
                        ),
                        const HBGap.md(),
                        _numberField(
                          _bodyWaterPercentageController,
                          'Água corporal (%)',
                        ),
                      ],
                    ),
                  ),
                  const HBGap.lg(),
                  HBButton(
                    label: _showOptional
                        ? 'Ocultar informações adicionais'
                        : 'Adicionar mais informações',
                    onPressed: () =>
                        setState(() => _showOptional = !_showOptional),
                  ),
                  if (_showOptional) ...[
                    const HBGap.lg(),
                    HBSection(
                      title: 'Composição corporal e exame',
                      child: Column(
                        children: [
                          _numberField(
                            _bodyFatPercentageController,
                            'Percentual de gordura (%)',
                          ),
                          const HBGap.md(),
                          _numberField(_bmiController, 'IMC'),
                          const HBGap.md(),
                          HBTextField(
                            controller: _deviceNameController,
                            label: 'Equipamento',
                            inputFormatters: AppInputFormatters.text(
                              maxLength: 120,
                            ),
                          ),
                          const HBGap.md(),
                          HBTextField(
                            controller: _clinicNameController,
                            label: 'Clínica',
                            inputFormatters: AppInputFormatters.text(
                              maxLength: 120,
                            ),
                          ),
                          const HBGap.md(),
                          HBTextField(
                            controller: _professionalNameController,
                            label: 'Profissional',
                            inputFormatters: AppInputFormatters.text(
                              maxLength: 120,
                            ),
                          ),
                          const HBGap.md(),
                          HBTextField(
                            controller: _notesController,
                            label: 'Observações',
                            maxLines: 4,
                            inputFormatters: AppInputFormatters.text(
                              maxLength: 500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing
                        ? 'Salvar alterações'
                        : 'Salvar avaliação',
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return HBTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: AppInputFormatters.decimal(),
      validator: (_) => null,
    );
  }

  void _fill(
    TextEditingController controller,
    List<ExtractedField> fields,
    String key,
  ) {
    if (controller.text.trim().isNotEmpty) return;
    final value = _field(fields, key);
    if (value != null) controller.text = value;
  }

  String? _field(List<ExtractedField> fields, String key) {
    for (final field in fields) {
      if (field.key == key) {
        return field.confirmedValue ?? field.normalizedValue ?? field.rawValue;
      }
    }
    return null;
  }

  double? _documentDouble(String key) =>
      _parse(_documentFieldsByKey[key]?.normalizedValue ?? '');

  int? _documentInt(String key) {
    final value = _documentFieldsByKey[key]?.normalizedValue;
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.replaceAll(',', '.').split('.').first);
  }

  Map<String, BioimpedanceAdditionalMetric> _documentAdditionalMetrics() {
    const typedKeys = {
      'weightKg',
      'muscleMassKg',
      'bodyFatMassKg',
      'bodyWaterPercentage',
      'bodyFatPercentage',
      'skeletalMuscleMassKg',
      'leanBodyMassKg',
      'fatFreeMassKg',
      'visceralFatLevel',
      'basalMetabolicRateKcal',
      'metabolicAge',
      'waistHipRatio',
      'phaseAngleDegrees',
      'proteinPercentage',
      'mineralMassKg',
      'weightControlKg',
      'fatControlKg',
      'muscleControlKg',
      'bmi',
      'measuredAt',
    };
    final metrics = <String, BioimpedanceAdditionalMetric>{};
    for (final entry in _documentFieldsByKey.entries) {
      if (typedKeys.contains(entry.key)) continue;
      final field = entry.value;
      metrics[entry.key] = BioimpedanceAdditionalMetric(
        key: entry.key,
        label: field.label,
        originalValue:
            field.confirmedValue ?? field.normalizedValue ?? field.rawValue,
        numericValue: _parse(
          field.confirmedValue ?? field.normalizedValue ?? field.rawValue,
        ),
        unit: field.unit,
        confidence: field.confidence,
        sourceText: field.rawValue,
        source: BioimpedanceMetricSource.document,
      );
    }
    return metrics;
  }

  double? _parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _format(double? value) => value?.toString();

  DateTime? _parseDate(String value) {
    final parts = value.split(RegExp(r'[\/.\-]'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year < 100 ? 2000 + year : year, month, day);
  }
}
