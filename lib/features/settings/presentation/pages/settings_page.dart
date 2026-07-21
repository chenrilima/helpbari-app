import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatters/app_water_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/notifications/notifications.dart';
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
    final notificationPreferences = settings.effectiveNotificationPreferences;

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
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const HBText('Lembretes do HelpBari'),
                  subtitle: HBText(
                    _permissionLabel(
                      ref.read(notificationSchedulerProvider).state.permission,
                    ),
                  ),
                  value: notificationPreferences.globalEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => _setGlobalNotifications(value),
                ),
                for (final category in NotificationCategory.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(_notificationCategoryIcon(category)),
                    title: HBText(_notificationCategoryLabel(category)),
                    subtitle: _configuredTimeLabel(
                      notificationPreferences,
                      category,
                    ),
                    value:
                        notificationPreferences.categories[category] ?? false,
                    onChanged:
                        state.isSaving || !notificationPreferences.globalEnabled
                        ? null
                        : (value) => ref
                              .read(settingsViewModelProvider.notifier)
                              .setNotificationCategory(category, value),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.calendar),
                  title: const HBText('Antecedência das consultas'),
                  subtitle: const HBText('Escolha quando deseja ser avisado'),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap:
                      notificationPreferences.categoryEnabled(
                        NotificationCategory.appointments,
                      )
                      ? _configureAppointmentLead
                      : null,
                ),
                for (final category in const [
                  NotificationCategory.water,
                  NotificationCategory.meals,
                  NotificationCategory.weight,
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_notificationCategoryIcon(category)),
                    title: HBText(
                      'Configurar ${_notificationCategoryLabel(category).toLowerCase()}',
                    ),
                    subtitle: const HBText(
                      'Nenhum horário é criado automaticamente',
                    ),
                    trailing: const Icon(Icons.schedule_outlined),
                    enabled:
                        notificationPreferences.globalEnabled &&
                        notificationPreferences.categoryEnabled(category),
                    onTap:
                        notificationPreferences.globalEnabled &&
                            notificationPreferences.categoryEnabled(category)
                        ? () => _configureNotificationTime(category)
                        : null,
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.medication_outlined),
                  title: const HBText('Acompanhar tratamento'),
                  value: settings.treatmentTrackingEnabled,
                  onChanged: state.isSaving
                      ? null
                      : (value) => _updateTracking(settings, treatment: value),
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
  }) => ref
      .read(settingsViewModelProvider.notifier)
      .updateTrackingPreferences(
        treatment: treatment ?? settings.treatmentTrackingEnabled,
        water: water ?? settings.waterTrackingEnabled,
        meals: meals ?? settings.mealTrackingEnabled,
        weight: weight ?? settings.weightTrackingEnabled,
      );

  Future<void> _setGlobalNotifications(bool enabled) async {
    if (!enabled) {
      await ref
          .read(settingsViewModelProvider.notifier)
          .setGlobalNotifications(false);
      return;
    }
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Ativar lembretes',
      message:
          'O HelpBari solicitará permissão ao sistema. Você poderá manter categorias e horários desligados separadamente.',
      confirmLabel: 'Continuar',
      type: HBDialogType.info,
    );
    if (confirmed != true || !mounted) return;
    final scheduler = ref.read(notificationSchedulerProvider);
    final granted = await scheduler.requestPermissions();
    await ref
        .read(settingsViewModelProvider.notifier)
        .setGlobalNotifications(true);
    if (!mounted) return;
    await HBDialog.info(
      context,
      title: granted ? 'Permissão concedida' : 'Permissão não concedida',
      message: granted
          ? 'Agora escolha as categorias e configure os horários desejados.'
          : 'Sua preferência foi salva, mas o sistema está bloqueando notificações. Você pode alterar isso nos ajustes do aparelho.',
    );
  }

  Future<void> _configureNotificationTime(NotificationCategory category) async {
    int? weekday;
    if (category == NotificationCategory.weight) {
      weekday = await _pickWeekday();
      if (weekday == null || !mounted) return;
    }
    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Escolha o horário do lembrete',
    );
    if (selected == null || !mounted) return;
    final scheduler = ref.read(notificationSchedulerProvider);
    final timeZone = scheduler.state.timeZone ?? 'UTC';
    await ref
        .read(settingsViewModelProvider.notifier)
        .putNotificationTime(
          NotificationTimePreference(
            id: '${category.name}-default',
            category: category,
            kind: category == NotificationCategory.weight
                ? NotificationScheduleKind.weekly
                : NotificationScheduleKind.daily,
            hour: selected.hour,
            minute: selected.minute,
            timeZone: timeZone,
            isoWeekday: weekday,
          ),
        );
  }

  Future<void> _configureAppointmentLead() async {
    const options = <int, String>{
      0: 'No horário',
      15: '15 minutos antes',
      30: '30 minutos antes',
      60: '1 hora antes',
      1440: '1 dia antes',
    };
    final leadMinutes = await HBBottomSheet.show<int>(
      context,
      title: 'Antecedência da consulta',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options.entries)
            ListTile(
              title: Text(option.value),
              onTap: () => Navigator.of(context).pop(option.key),
            ),
        ],
      ),
    );
    if (leadMinutes == null || !mounted) return;
    final scheduler = ref.read(notificationSchedulerProvider);
    await ref
        .read(settingsViewModelProvider.notifier)
        .putNotificationTime(
          NotificationTimePreference(
            id: 'appointments-lead',
            category: NotificationCategory.appointments,
            kind: NotificationScheduleKind.appointmentLead,
            hour: 0,
            minute: 0,
            timeZone: scheduler.state.timeZone ?? 'UTC',
            leadMinutes: leadMinutes,
          ),
        );
  }

  Future<int?> _pickWeekday() {
    var selected = DateTime.monday;
    const labels = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return HBBottomSheet.show<int>(
      context,
      title: 'Dia do lembrete de peso',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Dia da semana'),
              items: [
                for (var index = 0; index < labels.length; index++)
                  DropdownMenuItem(
                    value: index + 1,
                    child: Text(labels[index]),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setSheetState(() => selected = value);
              },
            ),
            const HBGap.lg(),
            HBButton(
              label: 'Escolher horário',
              onPressed: () => Navigator.of(context).pop(selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _configuredTimeLabel(
    NotificationPreferences preferences,
    NotificationCategory category,
  ) {
    final time = preferences.times
        .where((item) => item.category == category && item.enabled)
        .firstOrNull;
    if (time == null) return null;
    final clock =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return HBText(
      time.kind == NotificationScheduleKind.weekly
          ? 'Dia ${time.isoWeekday}, às $clock'
          : time.kind == NotificationScheduleKind.appointmentLead
          ? '${time.leadMinutes ?? 0} min antes'
          : 'Todos os dias, às $clock',
    );
  }

  String _notificationCategoryLabel(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.treatment => 'Tratamento',
        NotificationCategory.appointments => 'Consultas',
        NotificationCategory.water => 'Água',
        NotificationCategory.meals => 'Alimentação',
        NotificationCategory.weight => 'Peso',
      };

  IconData _notificationCategoryIcon(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.treatment => Icons.medication_outlined,
        NotificationCategory.appointments => AppIcons.calendar,
        NotificationCategory.water => AppIcons.water,
        NotificationCategory.meals => AppIcons.meal,
        NotificationCategory.weight => AppIcons.weight,
      };

  String _permissionLabel(
    NotificationPermissionState permission,
  ) => switch (permission) {
    NotificationPermissionState.granted => 'Permissão do aparelho concedida',
    NotificationPermissionState.denied => 'Permissão do aparelho não concedida',
    NotificationPermissionState.permanentlyDenied =>
      'Permissão bloqueada nos ajustes do aparelho',
    NotificationPermissionState.unknown =>
      'Permissão do aparelho ainda não confirmada',
  };
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
