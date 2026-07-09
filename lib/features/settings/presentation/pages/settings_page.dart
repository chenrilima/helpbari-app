import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
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

    if (state.isLoading) {
      return const HBPage(
        appBar: HBAppBar(title: 'Configurações'),
        children: [HBLoading(message: 'Carregando configurações...')],
      );
    }

    return HBPage(
      appBar: const HBAppBar(
        title: 'Configurações',
        subtitle: 'Preferências do HelpBari',
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
                subtitle: HBText('${settings.dailyWaterGoalMl} ml por dia'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showWaterGoalDialog(context, settings.dailyWaterGoalMl);
                },
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
                onChanged: (value) {
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
                onChanged: (value) {
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
                onChanged: (value) {
                  ref
                      .read(settingsViewModelProvider.notifier)
                      .toggleAppointmentReminders(value);
                },
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
                onChanged: (value) {
                  ref
                      .read(settingsViewModelProvider.notifier)
                      .toggleMealTracking(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showWaterGoalDialog(
    BuildContext context,
    int currentGoal,
  ) async {
    final controller = TextEditingController(text: currentGoal.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Meta diária de água'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meta em ml',
              hintText: 'Ex: 2000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());

                if (value == null || value < 500 || value > 6000) {
                  HBSnackBar.warning(
                    context,
                    message: 'Informe uma meta entre 500 ml e 6000 ml.',
                  );

                  return;
                }

                Navigator.of(context).pop(value);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await ref
        .read(settingsViewModelProvider.notifier)
        .updateDailyWaterGoal(result);
  }
}
