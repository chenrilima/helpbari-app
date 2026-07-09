import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/appointment_view_model_provider.dart';

class RegisterAppointmentPage extends ConsumerStatefulWidget {
  const RegisterAppointmentPage({super.key});

  @override
  ConsumerState<RegisterAppointmentPage> createState() =>
      _RegisterAppointmentPageState();
}

class _RegisterAppointmentPageState
    extends ConsumerState<RegisterAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
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
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await ref
        .read(appointmentViewModelProvider.notifier)
        .createAppointment(
          title: _titleController.text.trim(),
          date: date,
          doctorName: _doctorController.text.trim(),
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    HBSnackBar.success(context, message: 'Consulta cadastrada com sucesso.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Cadastrar consulta',
        subtitle: 'Acompanhe suas consultas médicas',
      ),
      children: [
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
                  validator: AppValidators.title,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _doctorController,
                  label: 'Médico',
                  hint: 'Ex: Dr. João',
                  textInputAction: TextInputAction.next,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _locationController,
                  label: 'Local',
                  hint: 'Ex: Hospital ou clínica',
                  textInputAction: TextInputAction.next,
                ),
                const HBGap.md(),
                HBButton(
                  label: 'Data: ${AppDateFormatter.short(_selectedDate)}',
                  onPressed: _pickDate,
                ),
                const HBGap.md(),
                HBButton(
                  label: 'Hora: ${_selectedTime.format(context)}',
                  onPressed: _pickTime,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _notesController,
                  label: 'Observações',
                  maxLines: 3,
                ),
                const HBGap.xl(),
                HBButton(label: 'Salvar consulta', onPressed: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
