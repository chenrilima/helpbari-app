import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final proteinText = _proteinController.text.trim();

    await ref
        .read(mealViewModelProvider.notifier)
        .createMeal(
          name: _nameController.text.trim(),
          type: _selectedType,
          mealDate: _selectedDate,
          proteinGrams: proteinText.isEmpty ? null : int.parse(proteinText),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

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
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Informe o nome da refeição.';
                    }

                    if (text.length < 2) {
                      return 'Informe um nome válido.';
                    }

                    return null;
                  },
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
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) return null;

                    final protein = int.tryParse(text);

                    if (protein == null || protein < 0 || protein > 300) {
                      return 'Informe uma quantidade válida.';
                    }

                    return null;
                  },
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _notesController,
                  label: 'Observações',
                  maxLines: 3,
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
