import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../domain/entities/entities.dart';
import '../models/water_form.dart';
import '../providers/water_view_model_provider.dart';
import '../widgets/water_progress_card.dart';

class RegisterWaterPage extends ConsumerStatefulWidget {
  const RegisterWaterPage({super.key, this.record});

  final WaterRecord? record;

  @override
  ConsumerState<RegisterWaterPage> createState() => _RegisterWaterPageState();
}

class _RegisterWaterPageState extends ConsumerState<RegisterWaterPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late DateTime _recordedAt;
  bool _isSubmitting = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.record?.amount.valueInMl.toString(),
    );
    _recordedAt =
        widget.record?.recordedAt ?? ref.read(clockServiceProvider).now();
  }

  @override
  void dispose() {
    _amountController.dispose();
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
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);

    final form = WaterForm(
      amountInMl: int.parse(_amountController.text.trim()),
      recordedAt: _recordedAt,
    );
    final notifier = ref.read(waterViewModelProvider.notifier);
    final success = _isEditing
        ? await notifier.updateWater(widget.record!, form)
        : await notifier.createWater(form);
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(waterViewModelProvider).errorMessage ??
            'Não foi possível salvar o registro.',
      );
      return;
    }
    HBSnackBar.success(context, message: 'Registro de água salvo no aparelho.');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      waterViewModelProvider.select((state) => state.isLoading),
    );
    final isBusy = isLoading || _isSubmitting;
    final waterState = ref.watch(waterViewModelProvider);
    final goalMl = ref.watch(dailyWaterGoalProvider).value ?? 2000;
    return HBLoadingOverlay(
      isLoading: isBusy,
      message: 'Salvando água...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing ? 'Editar água' : 'Registrar água',
          subtitle: 'Acompanhe sua hidratação',
        ),
        children: [
          WaterProgressCard(
            currentMl: waterState.totalTodayInMl,
            goalMl: goalMl,
          ),
          const HBGap.lg(),
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HBTextField(
                    controller: _amountController,
                    label: 'Quantidade (ml)',
                    hint: 'Ex: 300',
                    keyboardType: TextInputType.number,
                    inputFormatters: AppInputFormatters.digits(maxLength: 5),
                    textInputAction: TextInputAction.done,
                    autofocus: !_isEditing,
                    validator: AppValidators.waterAmount,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Data: ${AppDateFormatter.short(_recordedAt)}',
                    onPressed: isBusy ? null : _selectDate,
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing ? 'Salvar alterações' : 'Salvar água',
                    onPressed: isBusy ? null : _submit,
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
