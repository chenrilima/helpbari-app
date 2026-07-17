import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../design_system/design_system.dart';
import '../providers/medication_view_model_provider.dart';
import '../../domain/entities/medication.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';

class RegisterMedicationPage extends ConsumerStatefulWidget {
  const RegisterMedicationPage({super.key, this.medication});
  final Medication? medication;

  @override
  ConsumerState<RegisterMedicationPage> createState() =>
      _RegisterMedicationPageState();
}

class _RegisterMedicationPageState
    extends ConsumerState<RegisterMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _submitting = false;
  bool get _editing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.medication?.name.value ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.medication?.dosage ?? '',
    );
    _notesController = TextEditingController(
      text: widget.medication?.notes ?? '',
    );
    final time = widget.medication?.scheduleTime;
    if (time != null) {
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time == null) return;

    setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _submitting = true);
    final notifier = ref.read(medicationViewModelProvider.notifier);
    final success = _editing
        ? await notifier.updateMedication(
            widget.medication!,
            name: _nameController.text.trim(),
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
            dosage: _dosageController.text.trim(),
            notes: _notesController.text.trim(),
          )
        : await notifier.createMedication(
            name: _nameController.text.trim(),
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
            dosage: _dosageController.text.trim(),
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;

    if (!success) {
      setState(() => _submitting = false);
      HBSnackBar.error(
        context,
        message: 'Não foi possível salvar o medicamento.',
      );
      return;
    }
    HBSnackBar.success(context, message: 'Medicamento salvo no aparelho.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');

    return HBLoadingOverlay(
      isLoading: _submitting,
      child: HBPage(
        appBar: HBAppBar(
          title: _editing ? 'Editar medicamento' : 'Cadastrar medicamento',
          subtitle: 'Configure sua rotina de remédios',
        ),
        children: [
          DocumentImportCard(onConfirmed: _applyDocumentFields),
          const HBGap.xl(),
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HBTextField(
                    controller: _nameController,
                    label: 'Nome do medicamento',
                    hint: 'Ex: Omeprazol, Losartana',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.words,
                    autofocus: !_editing,
                    validator: AppValidators.medicationName,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _dosageController,
                    label: 'Dosagem',
                    hint: 'Ex: 20 mg, 1 comprimido',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    validator: AppValidators.optionalText,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Horário: $hour:$minute',
                    onPressed: _submitting ? null : _selectTime,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    inputFormatters: AppInputFormatters.text(maxLength: 500),
                    textCapitalization: TextCapitalization.sentences,
                    validator: AppValidators.optionalText,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _editing
                        ? 'Salvar alterações'
                        : 'Salvar medicamento',
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDocumentFields(
    DetectedDocumentType type,
    List<ExtractedField> fields,
  ) {
    final medication = _field(fields, 'medication');
    final dosage = _field(fields, 'dosage');
    final frequency = _field(fields, 'frequency');
    if (medication != null && _nameController.text.trim().isEmpty) {
      _nameController.text = medication;
    }
    if (dosage != null && _dosageController.text.trim().isEmpty) {
      _dosageController.text = dosage;
    }
    if (frequency != null && _notesController.text.trim().isEmpty) {
      _notesController.text = frequency;
    }
  }

  String? _field(List<ExtractedField> fields, String key) {
    for (final field in fields) {
      if (field.key == key) {
        return field.confirmedValue ?? field.normalizedValue ?? field.rawValue;
      }
    }
    return null;
  }
}
