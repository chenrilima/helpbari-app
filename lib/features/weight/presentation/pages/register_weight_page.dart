import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../models/create_weight_form.dart';
import '../providers/weight_view_model_provider.dart';

class RegisterWeightPage extends ConsumerStatefulWidget {
  const RegisterWeightPage({super.key});

  @override
  ConsumerState<RegisterWeightPage> createState() => _RegisterWeightPageState();
}

class _RegisterWeightPageState extends ConsumerState<RegisterWeightPage> {
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();

  final _notesController = TextEditingController();

  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();
    _recordedAt = ref.read(clockServiceProvider).now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = ref.read(clockServiceProvider).now();

    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (date == null) return;

    setState(() {
      _recordedAt = date;
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    final form = CreateWeightForm(
      weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
      recordedAt: _recordedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(weightViewModelProvider.notifier).registerWeight(form);

    if (!mounted) return;
    HBSnackBar.success(context, message: 'Peso registrado com sucesso.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Registrar peso',
        subtitle: 'Acompanhe sua evolução',
      ),
      children: [
        HBCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBTextField(
                  controller: _weightController,
                  label: 'Peso',
                  hint: 'Ex: 91.5',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: AppValidators.weight,
                ),

                const HBGap.md(),

                HBTextField(
                  controller: _notesController,
                  label: 'Observações (opcional)',
                  maxLines: 3,
                ),

                const HBGap.md(),

                HBButton(
                  label: 'Data: ${AppDateFormatter.short(_recordedAt)}',
                  onPressed: _selectDate,
                ),

                const HBGap.xl(),

                HBButton(label: 'Salvar peso', onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
