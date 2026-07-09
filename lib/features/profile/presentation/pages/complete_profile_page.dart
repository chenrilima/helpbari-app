import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_profile_form.dart';
import '../providers/profile_view_model_provider.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _initialWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  SurgeryType _selectedSurgeryType = SurgeryType.other;
  DateTime? _birthDate;
  DateTime? _surgeryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    if (_birthDate == null || _surgeryDate == null) {
      HBSnackBar.warning(
        context,
        message: 'Selecione as datas para continuar.',
      );
      return;
    }

    final targetWeightText = _targetWeightController.text.trim();

    final form = CreateProfileForm(
      name: _nameController.text.trim(),
      email: 'local@helpbari.app',
      birthDate: _birthDate!,
      height: int.parse(_heightController.text.trim()),
      initialWeight: double.parse(
        _initialWeightController.text.trim().replaceAll(',', '.'),
      ),
      targetWeight: targetWeightText.isEmpty
          ? null
          : double.parse(targetWeightText.replaceAll(',', '.')),
      surgeryDate: _surgeryDate!,
      surgeryType: _selectedSurgeryType,
    );

    await ref.read(profileViewModelProvider.notifier).createProfile(form);

    if (!mounted) return;

    if (context.canPop()) {
      context.pop(true);
      return;
    }

    context.go(AppRoutes.home);
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() => _birthDate = date);
  }

  Future<void> _selectSurgeryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() => _surgeryDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Completar perfil',
        subtitle: 'Personalize sua jornada',
      ),
      children: [
        HBCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  'Dados principais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const HBGap.sm(),
                HBText(
                  'Essas informações ajudarão o HelpBari a acompanhar sua evolução.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const HBGap.xl(),
                HBTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  hint: 'Ex: Carlos Henrique',
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.profileName,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _heightController,
                  label: 'Altura em cm',
                  hint: 'Ex: 178',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.height,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _initialWeightController,
                  label: 'Peso inicial',
                  hint: 'Ex: 142.5',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.weight,
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _targetWeightController,
                  label: 'Peso objetivo',
                  hint: 'Ex: 85.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: AppValidators.optionalWeight,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const HBGap.md(),
                HBButton(
                  label: _birthDate == null
                      ? 'Selecionar data de nascimento'
                      : 'Nascimento: ${AppDateFormatter.short(_birthDate!)}',
                  onPressed: _selectBirthDate,
                ),
                const HBGap.md(),
                HBButton(
                  label: _surgeryDate == null
                      ? 'Selecionar data da cirurgia'
                      : 'Cirurgia: ${AppDateFormatter.short(_surgeryDate!)}',
                  onPressed: _selectSurgeryDate,
                ),
                const HBGap.md(),
                DropdownButtonFormField<SurgeryType>(
                  initialValue: _selectedSurgeryType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de cirurgia',
                  ),
                  items: SurgeryType.values.map((type) {
                    return DropdownMenuItem<SurgeryType>(
                      value: type,
                      child: HBText(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedSurgeryType = value;
                    });
                  },
                ),
                const HBGap.xl(),
                HBButton(label: 'Salvar perfil', onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
