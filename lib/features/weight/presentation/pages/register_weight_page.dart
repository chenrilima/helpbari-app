import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
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

  DateTime _recordedAt = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      _recordedAt = date;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final form = CreateWeightForm(
      weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
      recordedAt: _recordedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(weightViewModelProvider.notifier).registerWeight(form);

    if (!mounted) return;

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
                  validator: (value) {
                    final weight = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );

                    if (weight == null) {
                      return 'Informe um peso válido.';
                    }

                    if (weight < 20 || weight > 500) {
                      return 'Peso inválido.';
                    }

                    return null;
                  },
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
