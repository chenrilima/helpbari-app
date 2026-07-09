import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/meal_view_model_provider.dart';

class RegisterMealPage extends ConsumerStatefulWidget {
  const RegisterMealPage({super.key});

  @override
  ConsumerState<RegisterMealPage> createState() => _RegisterMealPageState();
}

class _RegisterMealPageState extends ConsumerState<RegisterMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _proteinController = TextEditingController();
  final _notesController = TextEditingController();

  MealType _selectedType = MealType.lunch;
  late final DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = ref.read(clockServiceProvider).now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    final proteinText = _proteinController.text.trim();
    final proteinGrams = proteinText.isEmpty ? null : int.tryParse(proteinText);

    await ref
        .read(mealViewModelProvider.notifier)
        .createMeal(
          name: _nameController.text.trim(),
          type: _selectedType,
          mealDate: _selectedDate,
          proteinGrams: proteinGrams,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    HBSnackBar.success(context, message: 'Refeição cadastrada com sucesso.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Cadastrar refeição',
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
                const HBGap.xl(),
                HBButton(label: 'Salvar refeição', onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
