import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../providers/meal_view_model_provider.dart';

class RegisterMealPage extends ConsumerStatefulWidget {
  const RegisterMealPage({super.key, this.meal});
  final Meal? meal;

  @override
  ConsumerState<RegisterMealPage> createState() => _RegisterMealPageState();
}

class _RegisterMealPageState extends ConsumerState<RegisterMealPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _proteinController;
  late final TextEditingController _notesController;

  MealType _selectedType = MealType.lunch;
  late DateTime _selectedDate;
  bool _isSubmitting = false;
  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.meal?.name.value ?? '',
    );
    _proteinController = TextEditingController(
      text: widget.meal?.proteinGrams?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.meal?.notes ?? '');
    _selectedType = widget.meal?.type ?? MealType.lunch;
    _selectedDate =
        widget.meal?.mealDate.value ?? ref.read(clockServiceProvider).now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    final proteinText = _proteinController.text.trim();
    final proteinGrams = proteinText.isEmpty ? null : int.tryParse(proteinText);

    setState(() => _isSubmitting = true);
    final notifier = ref.read(mealViewModelProvider.notifier);
    final success = _isEditing
        ? await notifier.updateMeal(
            widget.meal!,
            name: _nameController.text.trim(),
            type: _selectedType,
            mealDate: _selectedDate,
            proteinGrams: proteinGrams,
            notes: _notesController.text.trim(),
          )
        : await notifier.createMeal(
            name: _nameController.text.trim(),
            type: _selectedType,
            mealDate: _selectedDate,
            proteinGrams: proteinGrams,
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(mealViewModelProvider).errorMessage ??
            'Não foi possível salvar a refeição.',
      );
      return;
    }
    final warning = ref.read(mealViewModelProvider).syncWarning;
    if (warning != null) {
      HBSnackBar.warning(context, message: warning);
    } else {
      HBSnackBar.success(
        context,
        message: _isEditing
            ? 'Refeição atualizada com sucesso.'
            : 'Refeição cadastrada com sucesso.',
      );
    }

    context.pop(true);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: ref.read(clockServiceProvider).now(),
    );
    if (date == null) return;
    setState(
      () => _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDate.hour,
        _selectedDate.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando refeição...',
      child: HBPage(
        appBar: HBAppBar(
          title: _isEditing ? 'Editar refeição' : 'Cadastrar refeição',
          subtitle: 'Registre sua alimentação',
        ),
        children: [
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HBTextField(
                    controller: _nameController,
                    label: 'Nome da refeição',
                    hint: 'Ex: Frango com legumes',
                    textInputAction: TextInputAction.next,
                    validator: AppValidators.mealName,
                  ),
                  const HBGap.md(),
                  DropdownButtonFormField<MealType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de refeição',
                    ),
                    items: MealType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: HBText(type.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() => _selectedType = value);
                    },
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _proteinController,
                    label: 'Proteína em gramas',
                    hint: 'Ex: 25',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: AppValidators.protein,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 3,
                    validator: AppValidators.optionalText,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: 'Data: ${AppDateFormatter.short(_selectedDate)}',
                    onPressed: _isSubmitting ? null : _selectDate,
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _isEditing ? 'Salvar alterações' : 'Salvar refeição',
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
