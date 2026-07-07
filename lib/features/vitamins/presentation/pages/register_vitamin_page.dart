import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../providers/vitamin_view_model_provider.dart';

class RegisterVitaminPage extends ConsumerStatefulWidget {
  const RegisterVitaminPage({super.key});

  @override
  ConsumerState<RegisterVitaminPage> createState() =>
      _RegisterVitaminPageState();
}

class _RegisterVitaminPageState extends ConsumerState<RegisterVitaminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time == null) return;

    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(vitaminViewModelProvider.notifier)
        .createVitamin(
          name: _nameController.text.trim(),
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );

    if (!mounted) return;

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _selectedTime.hour.toString().padLeft(2, '0');
    final formattedMinute = _selectedTime.minute.toString().padLeft(2, '0');

    return HBPage(
      children: [
        HBText(
          'Cadastrar vitamina',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const HBGap.sm(),
        HBText(
          'Informe o suplemento e o horário que costuma tomar.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const HBGap.xl(),
        HBCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                HBTextField(
                  controller: _nameController,
                  label: 'Nome da vitamina',
                  hint: 'Ex: B12, Ferro, Multivitamínico',
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Informe o nome da vitamina.';
                    }

                    if (text.length < 2) {
                      return 'Informe um nome válido.';
                    }

                    return null;
                  },
                ),
                const HBGap.md(),
                HBButton(
                  label: 'Horário: $formattedHour:$formattedMinute',
                  onPressed: _selectTime,
                ),
                const HBGap.xl(),
                HBButton(label: 'Salvar vitamina', onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
