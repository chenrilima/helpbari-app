import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/medication_view_model_provider.dart';

class RegisterMedicationPage extends ConsumerStatefulWidget {
  const RegisterMedicationPage({super.key});

  @override
  ConsumerState<RegisterMedicationPage> createState() =>
      _RegisterMedicationPageState();
}

class _RegisterMedicationPageState
    extends ConsumerState<RegisterMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

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
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(medicationViewModelProvider.notifier)
        .createMedication(
          name: _nameController.text.trim(),
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          dosage: _dosageController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    HBSnackBar.success(context, message: 'Medicamento cadastrado com sucesso.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');

    return HBPage(
      appBar: const HBAppBar(
        title: 'Cadastrar medicamento',
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
                ),
                const HBGap.xl(),
                HBButton(label: 'Salvar medicamento', onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
