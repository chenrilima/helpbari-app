import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_profile_form.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/value_objects/value_objects.dart';
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
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null || _surgeryDate == null) return;

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

    context.go(AppRoutes.profile);
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
      children: [
        HBCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  'Complete seu perfil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const HBGap.sm(),
                HBText(
                  'Essas informações ajudarão o HelpBari a acompanhar sua evolução de forma personalizada.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const HBGap.xl(),
                HBTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  hint: 'Ex: Carlos Henrique',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Informe seu nome.';
                    }

                    if (text.length < 3) {
                      return 'Informe um nome válido.';
                    }

                    return null;
                  },
                ),
                const HBGap.md(),
                HBTextField(
                  controller: _heightController,
                  label: 'Altura em cm',
                  hint: 'Ex: 178',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final height = int.tryParse(value?.trim() ?? '');

                    if (height == null) {
                      return 'Informe sua altura em centímetros.';
                    }

                    if (height < 80 || height > 250) {
                      return 'Informe uma altura válida.';
                    }

                    return null;
                  },
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
                  validator: (value) {
                    final weight = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );

                    if (weight == null) {
                      return 'Informe seu peso inicial.';
                    }

                    if (weight < 20 || weight > 500) {
                      return 'Informe um peso válido.';
                    }

                    return null;
                  },
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
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) return null;

                    final weight = double.tryParse(text.replaceAll(',', '.'));

                    if (weight == null) {
                      return 'Informe um peso objetivo válido.';
                    }

                    if (weight < 20 || weight > 500) {
                      return 'Informe um peso objetivo válido.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const HBGap.md(),
                HBButton(
                  label: _birthDate == null
                      ? 'Selecionar data de nascimento'
                      : 'Nascimento: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                  onPressed: _selectBirthDate,
                ),
                const HBGap.md(),
                HBButton(
                  label: _surgeryDate == null
                      ? 'Selecionar data da cirurgia'
                      : 'Cirurgia: ${_surgeryDate!.day}/${_surgeryDate!.month}/${_surgeryDate!.year}',
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
