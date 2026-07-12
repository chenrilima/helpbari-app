import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/medication_view_model_provider.dart';
import '../../domain/entities/medication.dart';

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
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

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
    HBSnackBar.success(
      context,
      message: _editing
          ? 'Medicamento atualizado com sucesso.'
          : 'Medicamento cadastrado com sucesso.',
    );

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
                    validator: AppValidators.medicationName,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _dosageController,
                    label: 'Dosagem',
                    hint: 'Ex: 20 mg, 1 comprimido',
                    textInputAction: TextInputAction.next,
                    validator: AppValidators.optionalText,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Horário: $hour:$minute',
                    onPressed: _selectTime,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 3,
                    validator: AppValidators.optionalText,
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
}
