import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/appointment_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';

class RegisterAppointmentPage extends ConsumerStatefulWidget {
  const RegisterAppointmentPage({super.key, this.appointment});
  final Appointment? appointment;

  @override
  ConsumerState<RegisterAppointmentPage> createState() =>
      _RegisterAppointmentPageState();
}

class _RegisterAppointmentPageState
    extends ConsumerState<RegisterAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _doctorController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;
  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    _titleController = TextEditingController(text: appointment?.title ?? '');
    _doctorController = TextEditingController(
      text: appointment?.doctorName ?? '',
    );
    _locationController = TextEditingController(
      text: appointment?.location ?? '',
    );
    _notesController = TextEditingController(text: appointment?.notes ?? '');
    _selectedDate =
        appointment?.date.value ??
        ref.read(clockServiceProvider).now().add(const Duration(days: 1));
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockServiceProvider).now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );

    if (date == null) return;

    setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time == null) return;

    setState(() => _selectedTime = time);
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSubmitting = true);
    final notifier = ref.read(appointmentViewModelProvider.notifier);
    final success = _isEditing
        ? await notifier.updateAppointment(
            widget.appointment!,
            title: _titleController.text.trim(),
            date: date,
            doctorName: _doctorController.text.trim(),
            location: _locationController.text.trim(),
            notes: _notesController.text.trim(),
          )
        : await notifier.createAppointment(
            title: _titleController.text.trim(),
            date: date,
            doctorName: _doctorController.text.trim(),
            location: _locationController.text.trim(),
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;

    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(appointmentViewModelProvider).errorMessage ??
            'Não foi possível salvar o agendamento.',
      );
      return;
    }
    HBSnackBar.success(
      context,
      message: _isEditing
          ? 'Agendamento atualizado com sucesso.'
          : 'Agendamento cadastrado com sucesso.',
    );

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando agendamento...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing ? 'Editar agendamento' : 'Novo agendamento',
          subtitle: 'Cadastre seus atendimentos futuros',
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
                    controller: _titleController,
                    label: 'Título',
                    hint: 'Ex: Retorno com cirurgião',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: !_isEditing,
                    validator: AppValidators.title,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _doctorController,
                    label: 'Médico',
                    hint: 'Ex: Dr. João',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.optionalText,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _locationController,
                    label: 'Local',
                    hint: 'Ex: Hospital ou clínica',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.optionalText,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Data: ${AppDateFormatter.short(_selectedDate)}',
                    onPressed: _isSubmitting ? null : _pickDate,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Hora: ${_selectedTime.format(context)}',
                    onPressed: _isSubmitting ? null : _pickTime,
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
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing
                        ? 'Salvar alterações'
                        : 'Salvar agendamento',
                    onPressed: _isSubmitting ? null : _save,
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
    final specialty = _field(fields, 'specialty');
    final professional = _field(fields, 'professional');
    final recommendations =
        _field(fields, 'recommendations') ?? _field(fields, 'summary');
    if (specialty != null && _titleController.text.trim().isEmpty) {
      _titleController.text = 'Consulta - $specialty';
    }
    if (professional != null && _doctorController.text.trim().isEmpty) {
      _doctorController.text = professional;
    }
    if (recommendations != null && _notesController.text.trim().isEmpty) {
      _notesController.text = recommendations;
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
