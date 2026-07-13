import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_profile_form.dart';
import '../providers/profile_view_model_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
  bool _editing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadExisting);
  }

  Future<void> _loadExisting() async {
    await ref.read(profileViewModelProvider.notifier).loadProfile();
    final profile = ref.read(profileViewModelProvider).profile;
    if (profile == null || !mounted) return;
    setState(() {
      _editing = true;
      _nameController.text = profile.name;
      _heightController.text = profile.height.valueInCentimeters.toString();
      _initialWeightController.text = profile.initialWeight.value.toString();
      _targetWeightController.text =
          profile.targetWeight?.value.toString() ?? '';
      _birthDate = profile.birthDate.value;
      _surgeryDate = profile.surgeryDate.value;
      _selectedSurgeryType = profile.surgeryType;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) return;

    if (_birthDate == null || _surgeryDate == null) {
      HBSnackBar.warning(
        context,
        message: 'Selecione as datas para continuar.',
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final targetWeightText = _targetWeightController.text.trim();

    final form = CreateProfileForm(
      name: _nameController.text.trim(),
      email: ref.read(authSessionProvider)?.email ?? '',
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

    setState(() => _isSubmitting = true);
    await ref.read(profileViewModelProvider.notifier).saveProfile(form);

    if (!mounted) return;
    final state = ref.read(profileViewModelProvider);
    if (state.errorMessage != null) {
      setState(() => _isSubmitting = false);
      HBSnackBar.error(context, message: state.errorMessage!);
      return;
    }

    HBSnackBar.success(context, message: 'Perfil salvo no aparelho.');

    if (context.canPop()) {
      context.pop(true);
      return;
    }

    context.go(AppRoutes.home);
  }

  Future<void> _selectBirthDate() async {
    final now = ref.read(clockServiceProvider).now();

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: now,
    );

    if (date == null) return;

    setState(() => _birthDate = date);
  }

  Future<void> _selectSurgeryDate() async {
    final now = ref.read(clockServiceProvider).now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (date == null) return;

    setState(() => _surgeryDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return HBLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Salvando perfil...',
      child: HBPage(
        appBar: HBAppBar(
          title: _editing ? 'Editar perfil' : 'Completar perfil',
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
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.words,
                    autofocus: !_editing,
                    validator: AppValidators.profileName,
                  ),
                  const HBGap.md(),
                  HBTextField(
                    controller: _heightController,
                    label: 'Altura em cm',
                    hint: 'Ex: 178',
                    keyboardType: TextInputType.number,
                    inputFormatters: AppInputFormatters.digits(maxLength: 3),
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
                    inputFormatters: AppInputFormatters.decimal(),
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
                    inputFormatters: AppInputFormatters.decimal(),
                    textInputAction: TextInputAction.done,
                    validator: AppValidators.optionalWeight,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: _birthDate == null
                        ? 'Selecionar data de nascimento'
                        : 'Nascimento: ${AppDateFormatter.short(_birthDate!)}',
                    onPressed: _isSubmitting ? null : _selectBirthDate,
                  ),
                  const HBGap.md(),
                  HBButton(
                    label: _surgeryDate == null
                        ? 'Selecionar data da cirurgia'
                        : 'Cirurgia: ${AppDateFormatter.short(_surgeryDate!)}',
                    onPressed: _isSubmitting ? null : _selectSurgeryDate,
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
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedSurgeryType = value;
                            });
                          },
                  ),
                  const HBGap.xl(),
                  HBButton(
                    label: _editing ? 'Salvar alterações' : 'Salvar perfil',
                    isLoading: _isSubmitting,
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
