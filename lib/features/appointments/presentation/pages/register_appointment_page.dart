import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time == null) return;

    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _save() async {
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
          title: _titleController.text,
          date: date,
          doctorName: _doctorController.text,
          location: _locationController.text,
          notes: _notesController.text,
        );

    if (!mounted) return;

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        HBText(
          'Nova consulta',
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const HBGap.xl(),

        HBTextField(controller: _titleController, label: 'Título'),

        const HBGap.md(),

        HBTextField(controller: _doctorController, label: 'Médico'),

        const HBGap.md(),

        HBTextField(controller: _locationController, label: 'Local'),

        const HBGap.md(),

        HBButton(
          label:
              'Data: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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

        HBButton(label: 'Salvar', onPressed: _save),
      ],
    );
  }
}
