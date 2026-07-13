import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../models/create_weight_form.dart';
import '../providers/weight_view_model_provider.dart';
import '../../domain/entities/entities.dart';

class RegisterWeightPage extends ConsumerStatefulWidget {
  const RegisterWeightPage({super.key, this.record});
  final WeightRecord? record;

  @override
  ConsumerState<RegisterWeightPage> createState() => _RegisterWeightPageState();
}

class _RegisterWeightPageState extends ConsumerState<RegisterWeightPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  late DateTime _recordedAt;
  bool _isSubmitting = false;
  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.record?.weight.value.toString(),
    );
    _notesController = TextEditingController(
      text: widget.record?.notes?.value ?? '',
    );
    _recordedAt =
        widget.record?.recordedAt.value ?? ref.read(clockServiceProvider).now();
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
    if (_isSubmitting) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final form = CreateWeightForm(
      weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
      recordedAt: _recordedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isSubmitting = true);
    final notifier = ref.read(weightViewModelProvider.notifier);
    final success = _isEditing
        ? await notifier.updateWeight(widget.record!, form)
        : await notifier.registerWeight(form);

    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(weightViewModelProvider).errorMessage ??
            'Não foi possível salvar o peso.',
      );
      return;
    }
    HBSnackBar.success(
      context,
      message: _isEditing
          ? 'Peso atualizado com sucesso.'
          : 'Peso registrado com sucesso.',
    );

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando peso...',
      child: HBPage(
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
                    inputFormatters: AppInputFormatters.decimal(),
                    textInputAction: TextInputAction.next,
                    autofocus: !_isEditing,
                    validator: AppValidators.weight,
                  ),

                  const HBGap.md(),

                  HBTextField(
                    controller: _notesController,
                    label: 'Observações (opcional)',
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    inputFormatters: AppInputFormatters.text(maxLength: 500),
                    textCapitalization: TextCapitalization.sentences,
                    onFieldSubmitted: (_) => _submit(),
                    validator: AppValidators.optionalText,
                  ),

                  const HBGap.md(),

                  HBButton(
                    label: 'Data: ${AppDateFormatter.short(_recordedAt)}',
                    onPressed: _selectDate,
                  ),

                  const HBGap.xl(),

                  HBButton(
                    label: _isEditing ? 'Salvar alterações' : 'Salvar peso',
                    onPressed: _isSubmitting ? null : _submit,
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
