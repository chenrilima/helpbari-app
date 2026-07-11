import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../profile/domain/value_objects/value_objects.dart';
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

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _surgeryDateController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _heightController;
  late final TextEditingController _initialWeightController;
  late final TextEditingController _targetWeightController;

  @override
  void initState() {
    super.initState();

    final draft = ref.read(onboardingViewModelProvider).draft;
    _nameController = TextEditingController(text: draft.name);
    _surgeryDateController = TextEditingController(text: draft.surgeryDate);
    _currentWeightController = TextEditingController(text: draft.currentWeight);
    _waterGoalController = TextEditingController(text: draft.waterGoal);
    _birthDateController = TextEditingController(text: draft.birthDate);
    _heightController = TextEditingController(text: draft.height);
    _initialWeightController = TextEditingController(text: draft.initialWeight);
    _targetWeightController = TextEditingController(text: draft.targetWeight);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    ref.listen(onboardingViewModelProvider, (previous, next) {
      if (previous?.hasCompleted == false && next.hasCompleted) {
        context.go(next.isAuthenticated ? AppRoutes.home : AppRoutes.login);
      }
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
            isSaving: state.isSaving,
            onNext: () => _handleNext(state),
            onFinish: () async {
              await _persistInitialData(state.draft);
              await viewModel.complete();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingState state) {
    return switch (state.currentStep) {
      OnboardingStep.splash => const OnboardingStepContent(
        icon: AppIcons.health,
        title: 'HelpBari',
        description:
            'Um cuidado simples para organizar sua rotina bariatrica desde o primeiro acesso.',
        children: [
          _BenefitLine(
            icon: AppIcons.success,
            text: 'Acompanhamento diario em poucos toques',
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
            text: 'Metas de agua e alimentacao visiveis no inicio',
          ),
          _BenefitLine(
            icon: AppIcons.weight,
            text: 'Historico de peso preparado para acompanhar evolucao',
          ),
        ],
      ),
      OnboardingStep.benefits => const OnboardingStepContent(
        icon: AppIcons.dashboard,
        title: 'Tudo reunido no mesmo lugar',
        description:
            'O HelpBari conecta registros de saude, tarefas do dia e progresso para reduzir esquecimentos.',
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
            text: 'Refeicoes registradas com foco em proteina',
          ),
        ],
      ),
      OnboardingStep.permissions => _PermissionsStep(
        notificationsEnabled: state.draft.notificationsEnabled,
        onChanged: _handleNotificationPermission,
      ),
      OnboardingStep.goals => _GoalsStep(
        selectedObjectives: state.draft.objectives,
        onToggle: ref
            .read(onboardingViewModelProvider.notifier)
            .toggleObjective,
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
        draft: state.draft,
        onDraftChanged: ref
            .read(onboardingViewModelProvider.notifier)
            .updateDraft,
      ),
      OnboardingStep.completion => const OnboardingStepContent(
        icon: AppIcons.success,
        title: 'Pronto para comecar',
        description:
            'Sua configuracao inicial foi salva neste dispositivo. Quando a conta estiver conectada, esses dados poderao ser sincronizados com o Supabase.',
        children: [
          _BenefitLine(
            icon: AppIcons.profile,
            text: 'Perfil inicial preparado',
          ),
          _BenefitLine(
            icon: AppIcons.settings,
            text: 'Preferencias salvas localmente',
          ),
        ],
      ),
    };
  }

  Future<void> _handleNext(OnboardingState state) async {
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    if (state.currentStep == OnboardingStep.initialData) {
      await _persistInitialData(state.draft);
    }

    viewModel.next();
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
    var isEnabled = value;

    if (value) {
      final status = await Permission.notification.request();
      isEnabled = status.isGranted || status.isLimited;
    }

    await ref
        .read(onboardingViewModelProvider.notifier)
        .setNotificationsEnabled(isEnabled);
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.canGoBack,
    required this.onBack,
    required this.onSkip,
  });

  final bool canGoBack;
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
        TextButton(onPressed: onSkip, child: const Text('Pular')),
      ],
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.isLastStep,
    required this.isSaving,
    required this.onNext,
    required this.onFinish,
  });

  final bool isLastStep;
  final bool isSaving;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return HBButton(
      label: isLastStep ? 'Concluir' : 'Continuar',
      icon: isLastStep ? AppIcons.success : Icons.arrow_forward,
      isLoading: isSaving,
      onPressed: isSaving ? null : (isLastStep ? onFinish : onNext),
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
      title: 'Permissoes importantes',
      description:
          'Ative notificacoes para receber lembretes de agua, medicamentos, vitaminas, exames e consultas.',
      children: [
        HBCard(
          child: Row(
            children: [
              const Icon(AppIcons.info, color: AppColors.info),
              const HBGap.horizontal(AppSpacing.md),
              Expanded(
                child: HBText(
                  'Voce pode alterar essa decisao depois nos ajustes do aparelho.',
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
  const _GoalsStep({required this.selectedObjectives, required this.onToggle});

  final List<String> selectedObjectives;
  final ValueChanged<String> onToggle;

  static const _objectives = [
    (
      id: 'hydration',
      label: 'Beber mais agua',
      description: 'Acompanhar volume diario e lembretes.',
      icon: AppIcons.water,
    ),
    (
      id: 'protein',
      label: 'Bater proteina',
      description: 'Registrar refeicoes com foco nutricional.',
      icon: AppIcons.meal,
    ),
    (
      id: 'weight',
      label: 'Monitorar peso',
      description: 'Ver historico e tendencia de progresso.',
      icon: AppIcons.weight,
    ),
    (
      id: 'routine',
      label: 'Organizar rotina',
      description: 'Manter exames, consultas e suplementos em dia.',
      icon: AppIcons.calendar,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContent(
      icon: AppIcons.dashboard,
      title: 'Quais objetivos importam agora?',
      description:
          'Escolha uma ou mais prioridades para personalizar sua experiencia inicial.',
      children: [
        for (final objective in _objectives) ...[
          OnboardingOptionTile(
            label: objective.label,
            description: objective.description,
            icon: objective.icon,
            isSelected: selectedObjectives.contains(objective.id),
            onTap: () => onToggle(objective.id),
          ),
          const HBGap.sm(),
        ],
      ],
    );
  }
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
  final OnboardingProfileDraft draft;
  final ValueChanged<OnboardingProfileDraft> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContent(
      icon: AppIcons.profile,
      title: 'Dados iniciais',
      description:
          'Essas informacoes ajudam a deixar metas e atalhos mais proximos da sua realidade.',
      children: [
        HBTextField(
          controller: nameController,
          label: 'Nome',
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.profile,
        ),
        const HBGap.md(),
        HBTextField(
          controller: surgeryDateController,
          label: 'Data da cirurgia',
          hint: 'dd/mm/aaaa',
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.calendar,
        ),
        const HBGap.md(),
        HBTextField(
          controller: birthDateController,
          label: 'Data de nascimento',
          hint: 'dd/mm/aaaa',
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.calendar,
        ),
        const HBGap.md(),
        HBTextField(
          controller: heightController,
          label: 'Altura em cm',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.profile,
        ),
        const HBGap.md(),
        HBTextField(
          controller: currentWeightController,
          label: 'Peso atual',
          hint: 'kg',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.weight,
        ),
        const HBGap.md(),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.currentWeightConfirmedAsInitial,
          title: const Text('Usar o peso atual como peso inicial'),
          subtitle: const Text('Só será usado após esta confirmação.'),
          onChanged: (value) => onDraftChanged(
            draft.copyWith(currentWeightConfirmedAsInitial: value ?? false),
          ),
        ),
        HBTextField(
          controller: initialWeightController,
          label: 'Peso inicial confirmado',
          hint: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.weight,
        ),
        const HBGap.md(),
        HBTextField(
          controller: targetWeightController,
          label: 'Peso objetivo (opcional)',
          hint: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.weight,
        ),
        const HBGap.md(),
        DropdownButtonFormField<SurgeryType>(
          initialValue: SurgeryType.values.firstWhere(
            (value) => value.name == draft.surgeryType,
            orElse: () => SurgeryType.other,
          ),
          decoration: const InputDecoration(labelText: 'Tipo de cirurgia'),
          items: SurgeryType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onDraftChanged(draft.copyWith(surgeryType: value.name));
            }
          },
        ),
        const HBGap.md(),
        HBTextField(
          controller: waterGoalController,
          label: 'Meta de agua',
          hint: 'ml por dia',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          prefixIcon: AppIcons.water,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.waterGoalConfirmed,
          title: const Text('Confirmo esta meta diária de água'),
          onChanged: (value) => onDraftChanged(
            draft.copyWith(waterGoalConfirmed: value ?? false),
          ),
        ),
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
