import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _initialWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
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
