import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../profile/domain/value_objects/value_objects.dart';
import '../../../privacy/domain/entities/entities.dart';
import '../../domain/entities/entities.dart';
import '../providers/onboarding_providers.dart';
import '../states/onboarding_state.dart';
import '../widgets/onboarding_option_tile.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/onboarding_step_content.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with WidgetsBindingObserver {
  final _initialDataFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surgeryDateController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _heightController;
  late final TextEditingController _initialWeightController;
  late final TextEditingController _targetWeightController;
  bool _isHandlingAction = false;
  bool _isHydratingControllers = false;
  Timer? _draftSaveDebounce;
  ProviderSubscription<OnboardingState>? _draftSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final draft = ref.read(onboardingViewModelProvider).draft;
    _nameController = TextEditingController(text: draft.name);
    _surgeryDateController = TextEditingController(text: draft.surgeryDate);
    _currentWeightController = TextEditingController(text: draft.currentWeight);
    _waterGoalController = TextEditingController(text: draft.waterGoal);
    _birthDateController = TextEditingController(text: draft.birthDate);
    _heightController = TextEditingController(text: draft.height);
    _initialWeightController = TextEditingController(text: draft.initialWeight);
    _targetWeightController = TextEditingController(text: draft.targetWeight);
    for (final controller in _textControllers) {
      controller.addListener(_scheduleDraftSave);
    }
    _draftSubscription = ref.listenManual(
      onboardingViewModelProvider,
      (previous, next) => _hydrateControllers(next.draft),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveDebounce?.cancel();
    _draftSubscription?.close();
    for (final controller in _textControllers) {
      controller.removeListener(_scheduleDraftSave);
    }
    _nameController.dispose();
    _surgeryDateController.dispose();
    _currentWeightController.dispose();
    _waterGoalController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  List<TextEditingController> get _textControllers => [
    _nameController,
    _surgeryDateController,
    _currentWeightController,
    _waterGoalController,
    _birthDateController,
    _heightController,
    _initialWeightController,
    _targetWeightController,
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _draftSaveDebounce?.cancel();
      unawaited(
        _persistInitialData(ref.read(onboardingViewModelProvider).draft),
      );
    }
  }

  void _scheduleDraftSave() {
    if (_isHydratingControllers) return;
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(
        _persistInitialData(ref.read(onboardingViewModelProvider).draft),
      );
    });
  }

  void _hydrateControllers(OnboardingProfileDraft draft) {
    _isHydratingControllers = true;
    _hydrateController(_nameController, draft.name);
    _hydrateController(_surgeryDateController, draft.surgeryDate);
    _hydrateController(_currentWeightController, draft.currentWeight);
    _hydrateController(_waterGoalController, draft.waterGoal);
    _hydrateController(_birthDateController, draft.birthDate);
    _hydrateController(_heightController, draft.height);
    _hydrateController(_initialWeightController, draft.initialWeight);
    _hydrateController(_targetWeightController, draft.targetWeight);
    _isHydratingControllers = false;
  }

  void _hydrateController(TextEditingController controller, String value) {
    if (controller.text.isEmpty && value.isNotEmpty) {
      controller.text = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    ref.listen(onboardingViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        HBSnackBar.error(context, message: next.errorMessage!);
      }
    });

    return HBScaffold(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(
            canGoBack: !state.isFirstStep,
            canSkip: !state.isAuthenticated,
            onBack: viewModel.previous,
            onSkip: () => _handleSkip(state),
          ),
          const HBGap.lg(),
          OnboardingProgressIndicator(
            value: state.progress,
            currentStep: state.currentIndex + 1,
            totalSteps: state.totalSteps,
          ),
          const HBGap.xl(),
          _buildStep(context, state),
          const HBGap.xl(),
          _OnboardingActions(
            isLastStep: state.isLastStep,
            isSaving: state.isSaving || _isHandlingAction,
            canContinue:
                state.currentStep != OnboardingStep.documents ||
                state.draft.documentsAccepted,
            onNext: () => _handleNext(state),
            onFinish: () => _handleFinish(state),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingState state) {
    if (state.resolutionFailed) {
      return HBEmptyState(
        icon: Icons.sync_problem_outlined,
        title: 'Não foi possível restaurar seus dados',
        description:
            state.errorMessage ?? 'Verifique sua conexão e tente novamente.',
        actionLabel: 'Tentar novamente',
        onActionPressed: () =>
            ref.read(onboardingViewModelProvider.notifier).refreshForSession(),
      );
    }
    return switch (state.currentStep) {
      OnboardingStep.splash => const OnboardingStepContent(
        icon: AppIcons.health,
        title: 'HelpBari',
        description:
            'Um cuidado simples para organizar sua rotina bariátrica desde o primeiro acesso.',
        children: [
          _BenefitLine(
            icon: AppIcons.success,
            text: 'Acompanhamento diário em poucos toques',
          ),
          _BenefitLine(
            icon: AppIcons.calendar,
            text: 'Lembretes para exames, consultas e suplementos',
          ),
        ],
      ),
      OnboardingStep.welcome => const OnboardingStepContent(
        icon: AppIcons.home,
        title: 'Bem-vindo a sua rotina de cuidado',
        description:
            'Vamos configurar o essencial para o aplicativo mostrar atalhos, metas e lembretes mais relevantes.',
        children: [
          _BenefitLine(
            icon: AppIcons.water,
            text: 'Metas de água e alimentação visíveis no início',
          ),
          _BenefitLine(
            icon: AppIcons.weight,
            text: 'Histórico de peso preparado para acompanhar evolução',
          ),
        ],
      ),
      OnboardingStep.benefits => const OnboardingStepContent(
        icon: AppIcons.dashboard,
        title: 'Tudo reunido no mesmo lugar',
        description:
            'O HelpBari conecta registros de saúde, tarefas do dia e progresso para reduzir esquecimentos.',
        children: [
          _BenefitLine(
            icon: AppIcons.vitamin,
            text: 'Vitaminas e medicamentos com agenda clara',
          ),
          _BenefitLine(
            icon: AppIcons.exam,
            text: 'Exames e consultas organizados por prioridade',
          ),
          _BenefitLine(
            icon: AppIcons.meal,
            text: 'Refeições registradas com foco em proteína',
          ),
        ],
      ),
      OnboardingStep.permissions => _PermissionsStep(
        notificationsEnabled: state.draft.notificationsEnabled,
        onChanged: _handleNotificationPermission,
      ),
      OnboardingStep.goals => _GoalsStep(
        draft: state.draft,
        onToggle: ref.read(onboardingViewModelProvider.notifier).toggleTracking,
      ),
      OnboardingStep.initialData => _InitialDataStep(
        nameController: _nameController,
        surgeryDateController: _surgeryDateController,
        currentWeightController: _currentWeightController,
        waterGoalController: _waterGoalController,
        birthDateController: _birthDateController,
        heightController: _heightController,
        initialWeightController: _initialWeightController,
        targetWeightController: _targetWeightController,
        formKey: _initialDataFormKey,
        draft: state.draft,
        onDraftChanged: ref
            .read(onboardingViewModelProvider.notifier)
            .updateDraft,
      ),
      OnboardingStep.documents => _DocumentsStep(
        termsAccepted: state.draft.termsAccepted,
        privacyPolicyAccepted: state.draft.privacyPolicyAccepted,
        onTermsChanged: (value) => ref
            .read(onboardingViewModelProvider.notifier)
            .updateDraft(state.draft.copyWith(termsAccepted: value)),
        onPrivacyChanged: (value) => ref
            .read(onboardingViewModelProvider.notifier)
            .updateDraft(state.draft.copyWith(privacyPolicyAccepted: value)),
        onOpen: (document) => HBDialog.info(
          context,
          title: '${document.title} • v${document.version}',
          message: document.content,
        ),
      ),
      OnboardingStep.completion => const OnboardingStepContent(
        icon: AppIcons.success,
        title: 'Pronto para começar',
        description:
            'Sua configuração inicial foi salva. Quando houver conexão, os dados pendentes serão sincronizados com segurança.',
        children: [
          _BenefitLine(
            icon: AppIcons.profile,
            text: 'Perfil inicial preparado',
          ),
          _BenefitLine(
            icon: AppIcons.settings,
            text: 'Preferências salvas localmente',
          ),
        ],
      ),
    };
  }

  Future<void> _handleNext(OnboardingState state) async {
    if (_isHandlingAction) return;
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    if (state.currentStep == OnboardingStep.initialData) {
      if (!(_initialDataFormKey.currentState?.validate() ?? false)) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _isHandlingAction = true);
      await _persistInitialData(state.draft);
    }

    await viewModel.next();
    if (mounted && _isHandlingAction) {
      setState(() => _isHandlingAction = false);
    }
  }

  Future<void> _handleFinish(OnboardingState state) async {
    if (_isHandlingAction) return;
    setState(() => _isHandlingAction = true);
    await _persistInitialData(state.draft);
    await ref.read(onboardingViewModelProvider.notifier).complete();
    if (mounted) setState(() => _isHandlingAction = false);
  }

  Future<void> _handleSkip(OnboardingState state) async {
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    if (state.currentStep == OnboardingStep.initialData) {
      await _persistInitialData(state.draft);
    }

    await viewModel.skip();
  }

  Future<void> _persistInitialData(OnboardingProfileDraft draft) {
    return ref
        .read(onboardingViewModelProvider.notifier)
        .updateDraft(
          draft.copyWith(
            name: _nameController.text.trim(),
            surgeryDate: _surgeryDateController.text.trim(),
            currentWeight: _currentWeightController.text.trim(),
            waterGoal: _waterGoalController.text.trim(),
            birthDate: _birthDateController.text.trim(),
            height: _heightController.text.trim(),
            initialWeight: _initialWeightController.text.trim(),
            targetWeight: _targetWeightController.text.trim(),
          ),
        );
  }

  Future<void> _handleNotificationPermission(bool value) async {
    if (value) {
      await ref.read(notificationSchedulerProvider).requestPermissions();
    }
    await ref
        .read(onboardingViewModelProvider.notifier)
        .setNotificationsEnabled(value);
  }
}

class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({
    required this.termsAccepted,
    required this.privacyPolicyAccepted,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onOpen,
  });

  final bool termsAccepted;
  final bool privacyPolicyAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final ValueChanged<PrivacyDocument> onOpen;

  @override
  Widget build(BuildContext context) => OnboardingStepContent(
    icon: Icons.privacy_tip_outlined,
    title: 'Privacidade e uso dos dados',
    description:
        'Leia e aceite os documentos obrigatórios para concluir sua configuração.',
    children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: privacyPolicyAccepted,
        title: const HBText('Política de Privacidade'),
        subtitle: const HBText('Versão ${PrivacyDocuments.privacyVersion}'),
        secondary: IconButton(
          tooltip: 'Abrir Política de Privacidade',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => onOpen(PrivacyDocuments.policy),
        ),
        onChanged: (value) => onPrivacyChanged(value ?? false),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: termsAccepted,
        title: const HBText('Termos de Uso'),
        subtitle: const HBText('Versão ${PrivacyDocuments.termsVersion}'),
        secondary: IconButton(
          tooltip: 'Abrir Termos de Uso',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => onOpen(PrivacyDocuments.terms),
        ),
        onChanged: (value) => onTermsChanged(value ?? false),
      ),
      if (!termsAccepted || !privacyPolicyAccepted)
        Semantics(
          label:
              'Aceites pendentes. Aceite os Termos de Uso e a Política de Privacidade para continuar.',
          child: const HBText('Aceite os dois documentos para continuar.'),
        ),
    ],
  );
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.canGoBack,
    required this.canSkip,
    required this.onBack,
    required this.onSkip,
  });

  final bool canGoBack;
  final bool canSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppSizes.buttonMinTapTarget,
          height: AppSizes.buttonMinTapTarget,
          child: canGoBack
              ? IconButton(
                  tooltip: 'Voltar',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
        ),
        const Spacer(),
        if (canSkip)
          TextButton(onPressed: onSkip, child: const Text('Pular'))
        else
          const SizedBox(width: AppSizes.buttonMinTapTarget),
      ],
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.isLastStep,
    required this.isSaving,
    required this.canContinue,
    required this.onNext,
    required this.onFinish,
  });

  final bool isLastStep;
  final bool isSaving;
  final bool canContinue;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return HBButton(
      label: isLastStep ? 'Concluir' : 'Continuar',
      icon: isLastStep ? AppIcons.success : Icons.arrow_forward,
      isLoading: isSaving,
      onPressed: isSaving || !canContinue
          ? null
          : (isLastStep ? onFinish : onNext),
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({
    required this.notificationsEnabled,
    required this.onChanged,
  });

  final bool notificationsEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContent(
      icon: AppIcons.warning,
      title: 'Permissões importantes',
      description:
          'Ative notificações para receber lembretes de água, medicamentos, vitaminas, exames e consultas.',
      children: [
        HBCard(
          child: Row(
            children: [
              const Icon(AppIcons.info, color: AppColors.info),
              const HBGap.horizontal(AppSpacing.md),
              Expanded(
                child: HBText(
                  'Você pode alterar essa decisão depois nos ajustes do aparelho.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: notificationsEnabled,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.draft, required this.onToggle});

  final OnboardingProfileDraft draft;
  final ValueChanged<String> onToggle;

  static const _tracking = [
    (
      id: 'treatment',
      label: 'Tratamento',
      description: 'Organizar o que você precisa tomar ou acompanhar.',
      icon: AppIcons.vitamin,
    ),
    (
      id: 'water',
      label: 'Água',
      description: 'Acompanhar volume e meta diária.',
      icon: AppIcons.water,
    ),
    (
      id: 'meals',
      label: 'Alimentação',
      description: 'Registrar refeições e proteína quando informada.',
      icon: AppIcons.meal,
    ),
    (
      id: 'weight',
      label: 'Monitorar peso',
      description: 'Ver histórico e tendência de progresso.',
      icon: AppIcons.weight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContent(
      icon: AppIcons.dashboard,
      title: 'O que você deseja acompanhar?',
      description:
          'Você pode alterar essas escolhas depois. Desativar um acompanhamento não apaga seu histórico.',
      children: [
        for (final item in _tracking) ...[
          OnboardingOptionTile(
            label: item.label,
            description: item.description,
            icon: item.icon,
            isSelected: _selected(item.id),
            onTap: () => onToggle(item.id),
          ),
          const HBGap.sm(),
        ],
      ],
    );
  }

  bool _selected(String id) => switch (id) {
    'treatment' => draft.trackTreatment,
    'water' => draft.trackWater,
    'meals' => draft.trackMeals,
    'weight' => draft.trackWeight,
    _ => false,
  };
}

class _InitialDataStep extends StatelessWidget {
  const _InitialDataStep({
    required this.nameController,
    required this.surgeryDateController,
    required this.currentWeightController,
    required this.waterGoalController,
    required this.birthDateController,
    required this.heightController,
    required this.initialWeightController,
    required this.targetWeightController,
    required this.formKey,
    required this.draft,
    required this.onDraftChanged,
  });

  final TextEditingController nameController;
  final TextEditingController surgeryDateController;
  final TextEditingController currentWeightController;
  final TextEditingController waterGoalController;
  final TextEditingController birthDateController;
  final TextEditingController heightController;
  final TextEditingController initialWeightController;
  final TextEditingController targetWeightController;
  final GlobalKey<FormState> formKey;
  final OnboardingProfileDraft draft;
  final ValueChanged<OnboardingProfileDraft> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContent(
      icon: AppIcons.profile,
      title: 'Dados iniciais',
      description:
          'Essas informações ajudam a deixar metas e atalhos mais próximos da sua realidade.',
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              HBTextField(
                controller: nameController,
                label: 'Nome',
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.profile,
                inputFormatters: AppInputFormatters.text(maxLength: 120),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: AppValidators.profileName,
              ),
              const HBGap.md(),
              HBTextField(
                controller: surgeryDateController,
                label: 'Data da cirurgia',
                hint: 'dd/mm/aaaa',
                keyboardType: TextInputType.datetime,
                inputFormatters: [AppInputFormatters.date],
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.calendar,
                validator: AppValidators.date,
              ),
              const HBGap.md(),
              HBTextField(
                controller: birthDateController,
                label: 'Data de nascimento',
                hint: 'dd/mm/aaaa',
                keyboardType: TextInputType.datetime,
                inputFormatters: [AppInputFormatters.date],
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.calendar,
                validator: AppValidators.date,
              ),
              const HBGap.md(),
              HBTextField(
                controller: heightController,
                label: 'Altura em cm',
                keyboardType: TextInputType.number,
                inputFormatters: AppInputFormatters.digits(maxLength: 3),
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.profile,
                validator: AppValidators.height,
              ),
              const HBGap.md(),
              HBTextField(
                controller: currentWeightController,
                label: 'Peso atual',
                hint: 'kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: AppInputFormatters.decimal(),
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.weight,
                validator: (value) => draft.currentWeightConfirmedAsInitial
                    ? AppValidators.weight(value)
                    : AppValidators.optionalWeight(value),
              ),
              const HBGap.md(),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: draft.currentWeightConfirmedAsInitial,
                title: const Text('Usar o peso atual como peso inicial'),
                subtitle: const Text('Só será usado após esta confirmação.'),
                onChanged: (value) => onDraftChanged(
                  draft.copyWith(
                    currentWeightConfirmedAsInitial: value ?? false,
                  ),
                ),
              ),
              HBTextField(
                controller: initialWeightController,
                label: 'Peso inicial confirmado',
                hint: 'kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: AppInputFormatters.decimal(),
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.weight,
                validator: (value) =>
                    draft.currentWeightConfirmedAsInitial &&
                        (value?.trim().isEmpty ?? true)
                    ? null
                    : AppValidators.weight(value),
              ),
              const HBGap.md(),
              HBTextField(
                controller: targetWeightController,
                label: 'Peso objetivo (opcional)',
                hint: 'kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: AppInputFormatters.decimal(),
                textInputAction: TextInputAction.next,
                prefixIcon: AppIcons.weight,
                validator: AppValidators.optionalWeight,
              ),
              const HBGap.md(),
              DropdownButtonFormField<SurgeryType>(
                initialValue: SurgeryType.values.firstWhere(
                  (value) => value.name == draft.surgeryType,
                  orElse: () => SurgeryType.other,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tipo de cirurgia',
                ),
                items: SurgeryType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onDraftChanged(draft.copyWith(surgeryType: value.name));
                  }
                },
              ),
              const HBGap.md(),
              if (draft.trackWater) ...[
                HBTextField(
                  controller: waterGoalController,
                  label: 'Meta de água',
                  hint: 'ml por dia',
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.digits(maxLength: 4),
                  textInputAction: TextInputAction.done,
                  prefixIcon: AppIcons.water,
                  validator: AppValidators.waterGoal,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: draft.waterGoalConfirmed,
                  title: const Text('Confirmo esta meta diária de água'),
                  onChanged: (value) => onDraftChanged(
                    draft.copyWith(waterGoalConfirmed: value ?? false),
                  ),
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: draft.notificationsConfirmed,
                title: Text(
                  draft.notificationsEnabled
                      ? 'Confirmo ativar lembretes de vitaminas, medicamentos e consultas'
                      : 'Confirmo manter esses lembretes desativados',
                ),
                onChanged: (value) => onDraftChanged(
                  draft.copyWith(notificationsConfirmed: value ?? false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary),
          const HBGap.horizontal(AppSpacing.md),
          Expanded(
            child: HBText(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
