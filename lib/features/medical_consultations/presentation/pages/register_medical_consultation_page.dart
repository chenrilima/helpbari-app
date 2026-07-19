import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../../core/sync/sync.dart';
import '../../../../design_system/design_system.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../bioimpedance/domain/entities/entities.dart';
import '../../../bioimpedance/presentation/providers/bioimpedance_use_cases_provider.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_consultation_view_model_provider.dart';

class RegisterMedicalConsultationPage extends ConsumerStatefulWidget {
  const RegisterMedicalConsultationPage({
    super.key,
    this.consultation,
    this.appointment,
  });

  final MedicalConsultation? consultation;
  final Appointment? appointment;

  @override
  ConsumerState<RegisterMedicalConsultationPage> createState() =>
      _RegisterMedicalConsultationPageState();
}

class _RegisterMedicalConsultationPageState
    extends ConsumerState<RegisterMedicalConsultationPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _professionalController;
  late final TextEditingController _registrationController;
  late final TextEditingController _clinicController;
  late final TextEditingController _locationController;
  late final TextEditingController _reasonController;
  late final TextEditingController _symptomsController;
  late final TextEditingController _guidanceController;
  late final TextEditingController _dietController;
  late final TextEditingController _activityController;
  late final TextEditingController _supplementController;
  late final TextEditingController _medicationController;
  late final TextEditingController _requestedExamsController;
  late final TextEditingController _followUpController;
  late final TextEditingController _notesController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _bmiController;

  late DateTime _consultationAt;
  bool _isSubmitting = false;
  String? _confirmedDocumentId;
  final Set<String> _selectedExamIds = <String>{};
  final Set<String> _selectedBodyIds = <String>{};
  List<MedicalExam> _exams = const [];
  List<BioimpedanceRecord> _bodyCompositions = const [];

  bool get _isEditing => widget.consultation != null;

  @override
  void initState() {
    super.initState();
    final consultation = widget.consultation;
    final appointment = widget.appointment;
    _titleController = TextEditingController(
      text: consultation?.title ?? appointment?.title,
    );
    _specialtyController = TextEditingController(text: consultation?.specialty);
    _professionalController = TextEditingController(
      text: consultation?.professionalName ?? appointment?.doctorName,
    );
    _registrationController = TextEditingController(
      text: consultation?.professionalRegistration,
    );
    _clinicController = TextEditingController(text: consultation?.clinicName);
    _locationController = TextEditingController(
      text: consultation?.location ?? appointment?.location,
    );
    _reasonController = TextEditingController(text: consultation?.reason);
    _symptomsController = TextEditingController(text: consultation?.symptoms);
    _guidanceController = TextEditingController(
      text: consultation?.professionalGuidance,
    );
    _dietController = TextEditingController(
      text: consultation?.dietaryGuidance,
    );
    _activityController = TextEditingController(
      text: consultation?.physicalActivityGuidance,
    );
    _supplementController = TextEditingController(
      text: consultation?.supplementGuidance,
    );
    _medicationController = TextEditingController(
      text: consultation?.medicationGuidance,
    );
    _requestedExamsController = TextEditingController(
      text: consultation?.requestedExamsNotes,
    );
    _followUpController = TextEditingController(
      text: consultation?.followUpNotes,
    );
    _notesController = TextEditingController(text: consultation?.generalNotes);
    _weightController = TextEditingController(
      text: consultation?.weightKg?.toString(),
    );
    _heightController = TextEditingController(
      text: consultation?.heightCm?.toString(),
    );
    _bmiController = TextEditingController(text: consultation?.bmi?.toString());
    _consultationAt =
        consultation?.consultationAt ??
        appointment?.date.value ??
        ref.read(clockServiceProvider).now();
    _selectedExamIds.addAll(consultation?.relatedExamIds ?? const []);
    _selectedBodyIds.addAll(
      consultation?.relatedBodyCompositionIds ?? const [],
    );
    Future.microtask(_loadRelations);
  }

  Future<void> _loadRelations() async {
    final exams = await ref.read(medicalExamUseCasesProvider).getHistory();
    final body = await ref.read(bioimpedanceUseCasesProvider).getHistory();
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _bodyCompositions = body;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specialtyController.dispose();
    _professionalController.dispose();
    _registrationController.dispose();
    _clinicController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    _symptomsController.dispose();
    _guidanceController.dispose();
    _dietController.dispose();
    _activityController.dispose();
    _supplementController.dispose();
    _medicationController.dispose();
    _requestedExamsController.dispose();
    _followUpController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = ref.read(clockServiceProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: _consultationAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consultationAt),
    );
    if (time == null) return;
    setState(() {
      _consultationAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _applyDocumentFields(
    DetectedDocumentType type,
    List<ExtractedField> fields,
  ) {
    if (type != DetectedDocumentType.medicalConsultation &&
        type != DetectedDocumentType.consultationNote) {
      HBSnackBar.error(
        context,
        message: 'O documento analisado não parece ser uma consulta clínica.',
      );
      return;
    }
    _setIfEmpty(_titleController, _field(fields, 'title'));
    _setIfEmpty(_specialtyController, _field(fields, 'specialty'));
    _setIfEmpty(_professionalController, _field(fields, 'professionalName'));
    _setIfEmpty(_clinicController, _field(fields, 'clinicName'));
    _setIfEmpty(_reasonController, _field(fields, 'reason'));
    _setIfEmpty(_symptomsController, _field(fields, 'symptoms'));
    _setIfEmpty(_guidanceController, _field(fields, 'professionalGuidance'));
    _setIfEmpty(
      _requestedExamsController,
      _field(fields, 'requestedExamsNotes'),
    );
    _setIfEmpty(_followUpController, _field(fields, 'followUpNotes'));
    _setIfEmpty(_notesController, _field(fields, 'generalNotes'));
    final parsedDate = _parseDate(_field(fields, 'consultationAt'));
    if (parsedDate != null) {
      _consultationAt = parsedDate;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final consultation = _buildConsultation();
    if (!consultation.hasAnyContent) {
      HBSnackBar.error(
        context,
        message:
            'Informe ao menos um conteúdo clínico, documento ou vínculo relevante.',
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(medicalConsultationViewModelProvider.notifier)
        .save(consultation);
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(medicalConsultationViewModelProvider).errorMessage ??
            'Não foi possível salvar a consulta.',
      );
      return;
    }
    HBSnackBar.success(
      context,
      message: _isEditing
          ? 'Consulta atualizada com sucesso.'
          : 'Consulta registrada com sucesso.',
    );
    context.pop(true);
  }

  MedicalConsultation _buildConsultation() {
    final existing = widget.consultation;
    final now = ref.read(clockServiceProvider).now().toUtc();
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    return MedicalConsultation(
      id: existing?.id ?? ref.read(uuidServiceProvider).generate(),
      userId: userId,
      consultationAt: _consultationAt,
      title: _emptyToNull(_titleController.text),
      specialty: _emptyToNull(_specialtyController.text),
      professionalName: _emptyToNull(_professionalController.text),
      professionalRegistration: _emptyToNull(_registrationController.text),
      clinicName: _emptyToNull(_clinicController.text),
      location: _emptyToNull(_locationController.text),
      appointmentId: existing?.appointmentId ?? widget.appointment?.id,
      source: _confirmedDocumentId != null
          ? MedicalConsultationSource.document
          : widget.appointment != null
          ? MedicalConsultationSource.appointment
          : (existing?.source ?? MedicalConsultationSource.manual),
      sourceDocumentId: existing?.sourceDocumentId ?? _confirmedDocumentId,
      reason: _emptyToNull(_reasonController.text),
      symptoms: _emptyToNull(_symptomsController.text),
      professionalGuidance: _emptyToNull(_guidanceController.text),
      dietaryGuidance: _emptyToNull(_dietController.text),
      physicalActivityGuidance: _emptyToNull(_activityController.text),
      supplementGuidance: _emptyToNull(_supplementController.text),
      medicationGuidance: _emptyToNull(_medicationController.text),
      requestedExamsNotes: _emptyToNull(_requestedExamsController.text),
      followUpNotes: _emptyToNull(_followUpController.text),
      generalNotes: _emptyToNull(_notesController.text),
      weightKg: double.tryParse(_weightController.text.replaceAll(',', '.')),
      heightCm: double.tryParse(_heightController.text.replaceAll(',', '.')),
      bmi: double.tryParse(_bmiController.text.replaceAll(',', '.')),
      relatedExamIds: _selectedExamIds.toList(growable: false),
      relatedBodyCompositionIds: _selectedBodyIds.toList(growable: false),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
      syncStatus: existing?.syncStatus ?? SyncStatus.pendingCreate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando consulta...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing
              ? 'Editar consulta realizada'
              : 'Registrar consulta',
          subtitle: 'Histórico clínico manual ou via documento',
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
                  HBButton(
                    label:
                        'Data e hora: ${AppDateFormatter.shortWithTime(_consultationAt)}',
                    onPressed: _pickDateTime,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _titleController,
                    label: 'Título',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _specialtyController,
                    label: 'Especialidade',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _professionalController,
                    label: 'Profissional',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _registrationController,
                    label: 'Registro profissional',
                    inputFormatters: AppInputFormatters.text(maxLength: 60),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _clinicController,
                    label: 'Clínica',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _locationController,
                    label: 'Local',
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                  ),
                  const HBGap.lg(),
                  HBSection(
                    title: 'Conteúdo clínico',
                    child: Column(
                      children: [
                        HBTextField(
                          controller: _reasonController,
                          label: 'Motivo da consulta',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _symptomsController,
                          label: 'Sintomas',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _guidanceController,
                          label: 'Orientações profissionais',
                          maxLines: 3,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _dietController,
                          label: 'Orientações alimentares',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _activityController,
                          label: 'Atividade física',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _supplementController,
                          label: 'Suplementação',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _medicationController,
                          label: 'Medicação',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _requestedExamsController,
                          label: 'Exames solicitados',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _followUpController,
                          label: 'Próximos passos',
                          maxLines: 2,
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _notesController,
                          label: 'Observações gerais',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const HBGap.lg(),
                  HBSection(
                    title: 'Medidas opcionais',
                    child: Column(
                      children: [
                        HBTextField(
                          controller: _weightController,
                          label: 'Peso (kg)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _heightController,
                          label: 'Altura (cm)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const HBGap.md(),
                        HBTextField(
                          controller: _bmiController,
                          label: 'IMC',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const HBGap.lg(),
                  if (_exams.isNotEmpty)
                    _SelectableSection<MedicalExam>(
                      title: 'Exames relacionados',
                      items: _exams,
                      isSelected: (item) => _selectedExamIds.contains(item.id),
                      onToggle: (item, selected) {
                        setState(() {
                          if (selected) {
                            _selectedExamIds.add(item.id);
                          } else {
                            _selectedExamIds.remove(item.id);
                          }
                        });
                      },
                      label: (item) => item.title?.trim().isNotEmpty == true
                          ? item.title!
                          : 'Exame de ${AppDateFormatter.short(item.performedAt)}',
                    ),
                  if (_bodyCompositions.isNotEmpty) ...[
                    const HBGap.lg(),
                    _SelectableSection<BioimpedanceRecord>(
                      title: 'Bioimpedância relacionada',
                      items: _bodyCompositions,
                      isSelected: (item) => _selectedBodyIds.contains(item.id),
                      onToggle: (item, selected) {
                        setState(() {
                          if (selected) {
                            _selectedBodyIds.add(item.id);
                          } else {
                            _selectedBodyIds.remove(item.id);
                          }
                        });
                      },
                      label: (item) =>
                          'Bioimpedância de ${AppDateFormatter.short(item.measuredAt)}',
                    ),
                  ],
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing ? 'Salvar alterações' : 'Salvar consulta',
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

  void _setIfEmpty(TextEditingController controller, String? value) {
    if (value == null || controller.text.trim().isNotEmpty) return;
    controller.text = value;
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
    return DateTime(
      year,
      month,
      day,
      _consultationAt.hour,
      _consultationAt.minute,
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SelectableSection<T> extends StatelessWidget {
  const _SelectableSection({
    required this.title,
    required this.items,
    required this.isSelected,
    required this.onToggle,
    required this.label,
  });

  final String title;
  final List<T> items;
  final bool Function(T item) isSelected;
  final void Function(T item, bool selected) onToggle;
  final String Function(T item) label;

  @override
  Widget build(BuildContext context) {
    return HBSection(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items.take(8))
            FilterChip(
              label: Text(label(item)),
              selected: isSelected(item),
              onSelected: (selected) => onToggle(item, selected),
            ),
        ],
      ),
    );
  }
}
