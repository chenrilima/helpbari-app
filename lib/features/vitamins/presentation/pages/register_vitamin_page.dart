import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/vitamin_view_model_provider.dart';
import '../../domain/entities/vitamin.dart';

class RegisterVitaminPage extends ConsumerStatefulWidget {
  const RegisterVitaminPage({super.key, this.vitamin});
  final Vitamin? vitamin;

  @override
  ConsumerState<RegisterVitaminPage> createState() =>
      _RegisterVitaminPageState();
}

class _RegisterVitaminPageState extends ConsumerState<RegisterVitaminPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _submitting = false;
  bool get _editing => widget.vitamin != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.vitamin?.name.value ?? '',
    );
    final time = widget.vitamin?.scheduleTime;
    if (time != null) {
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
    }
  }

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
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    setState(() => _submitting = true);
    final notifier = ref.read(vitaminViewModelProvider.notifier);
    final success = _editing
        ? await notifier.updateVitamin(
            widget.vitamin!,
            name: _nameController.text.trim(),
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
          )
        : await notifier.createVitamin(
            name: _nameController.text.trim(),
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
          );

    if (!mounted) return;

    if (!success) {
      setState(() => _submitting = false);
      HBSnackBar.error(context, message: 'Não foi possível salvar a vitamina.');
      return;
    }
    HBSnackBar.success(
      context,
      message: _editing
          ? 'Vitamina atualizada com sucesso.'
          : 'Vitamina cadastrada com sucesso.',
    );

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _selectedTime.hour.toString().padLeft(2, '0');
    final formattedMinute = _selectedTime.minute.toString().padLeft(2, '0');

    return HBLoadingOverlay(
      isLoading: _submitting,
      child: HBPage(
        appBar: HBAppBar(
          title: _editing ? 'Editar vitamina' : 'Cadastrar vitamina',
          subtitle: 'Acompanhe seus suplementos diários',
        ),
        children: [
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
                    validator: AppValidators.vitaminName,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Horário: $formattedHour:$formattedMinute',
                    onPressed: _selectTime,
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _editing ? 'Salvar alterações' : 'Salvar vitamina',
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
