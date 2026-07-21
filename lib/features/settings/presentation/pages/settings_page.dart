import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatters/app_water_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../app/bootstrap/sync_bootstrap_provider.dart';
import '../../../../app/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/setting_view_model_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(settingsViewModelProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);
    final settings = state.settings;

    ref.listen(settingsViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        HBSnackBar.error(context, message: next.errorMessage!);
      }
    });

    if (state.isLoading) {
      return const HBPage(
        appBar: HBAppBar(title: 'Configurações'),
        children: [HBLoading(message: 'Carregando configurações...')],
      );
    }

    if (!state.hasLoaded && state.errorMessage != null) {
      return HBPage(
        appBar: const HBAppBar(title: 'Configurações'),
        children: [
          HBEmptyState(
            title: 'Não foi possível carregar as configurações',
            description: state.errorMessage!,
            icon: Icons.error_outline,
            actionLabel: 'Tentar novamente',
            onActionPressed: () =>
                ref.read(settingsViewModelProvider.notifier).loadSettings(),
          ),
        ],
      );
    }

    return HBLoadingOverlay(
      isLoading: state.isSaving,
      message: 'Salvando configurações...',
      child: HBPage(
        appBar: HBAppBar(
          title: 'Configurações',
          subtitle: 'Preferências do HelpBari',
          actions: [
            IconButton(
              tooltip: 'Sincronizar configurações',
              onPressed: () => ref.read(syncBootstrapProvider).retry(),
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        children: [
          HBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText('Metas', style: Theme.of(context).textTheme.titleLarge),
                const HBGap.md(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.water),
                  title: const HBText('Meta diária de água'),
                  subtitle: HBText(
                    '${AppWaterFormatter.ml(settings.dailyWaterGoalMl)} por dia',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: state.isSaving
                      ? null
                      : () {
                          _showWaterGoalDialog(
                            context,
                            settings.dailyWaterGoalMl,
                          );
                        },
                ),
              ],
            ),
          ),
          const HBGap.lg(),
          HBCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const HBText('Privacidade e Dados'),
              subtitle: const HBText('Consentimentos, exportação e exclusão'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.privacy),
            ),
          ),
          const HBGap.lg(),
          HBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  'Lembretes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const HBGap.md(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.vitamin),
                  title: const HBText('Vitaminas'),
                  subtitle: const HBText('Preparado para lembretes futuros'),
                  value: settings.vitaminRemindersEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          ref
                              .read(settingsViewModelProvider.notifier)
                              .toggleVitaminReminders(value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.medication_outlined),
                  title: const HBText('Medicamentos'),
                  subtitle: const HBText('Preparado para lembretes futuros'),
                  value: settings.medicationRemindersEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          ref
                              .read(settingsViewModelProvider.notifier)
                              .toggleMedicationReminders(value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.calendar),
                  title: const HBText('Consultas'),
                  subtitle: const HBText('Preparado para lembretes futuros'),
                  value: settings.appointmentRemindersEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          ref
                              .read(settingsViewModelProvider.notifier)
                              .toggleAppointmentReminders(value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.medication_outlined),
                  title: const HBText('Acompanhar tratamento'),
                  value: settings.treatmentTrackingEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => _updateTracking(
                          settings,
                          treatment: value,
                        ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.water),
                  title: const HBText('Acompanhar água'),
                  value: settings.waterTrackingEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => _updateTracking(settings, water: value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.weight),
                  title: const HBText('Acompanhar peso'),
                  value: settings.weightTrackingEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => _updateTracking(settings, weight: value),
                ),
              ],
            ),
          ),
          const HBGap.lg(),
          HBCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  'Funcionalidades',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const HBGap.md(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.restaurant_outlined),
                  title: const HBText('Acompanhar refeições'),
                  value: settings.mealTrackingEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          ref
                              .read(settingsViewModelProvider.notifier)
                              .toggleMealTracking(value);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWaterGoalDialog(
    BuildContext context,
    int currentGoal,
  ) async {
    final formKey = GlobalKey<_WaterGoalDialogFormState>();

    final result = await HBDialog.custom<int>(
      context,
      title: 'Meta diária de água',
      content: _WaterGoalDialogForm(key: formKey, initialGoal: currentGoal),
      actions: [
        TextButton(
          onPressed: () => formKey.currentState?.cancel(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => formKey.currentState?.submit(),
          child: const Text('Salvar'),
        ),
      ],
    );

    if (result == null || !mounted) return;

    await ref
        .read(settingsViewModelProvider.notifier)
        .updateDailyWaterGoal(result);
    if (mounted) {
      HBSnackBar.success(
        this.context,
        message: 'Meta de água salva no aparelho.',
      );
    }
  }

  Future<void> _updateTracking(
    AppSettings settings, {
    bool? treatment,
    bool? water,
    bool? meals,
    bool? weight,
  }) => ref.read(settingsViewModelProvider.notifier).updateTrackingPreferences(
    treatment: treatment ?? settings.treatmentTrackingEnabled,
    water: water ?? settings.waterTrackingEnabled,
    meals: meals ?? settings.mealTrackingEnabled,
    weight: weight ?? settings.weightTrackingEnabled,
  );
}

class _WaterGoalDialogForm extends StatefulWidget {
  const _WaterGoalDialogForm({required this.initialGoal, super.key});

  final int initialGoal;

  @override
  State<_WaterGoalDialogForm> createState() => _WaterGoalDialogFormState();
}

class _WaterGoalDialogFormState extends State<_WaterGoalDialogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: HBTextField(
        controller: _controller,
        label: 'Meta em ml',
        hint: 'Ex: 2000',
        keyboardType: TextInputType.number,
        inputFormatters: AppInputFormatters.digits(maxLength: 4),
        textInputAction: TextInputAction.done,
        autofocus: true,
        validator: AppValidators.waterGoal,
        onFieldSubmitted: (_) => submit(),
      ),
    );
  }
}
