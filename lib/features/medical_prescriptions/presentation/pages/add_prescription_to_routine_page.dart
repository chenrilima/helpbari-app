import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../medications/presentation/providers/medication_view_model_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_view_model_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';

class AddPrescriptionToRoutinePage extends ConsumerStatefulWidget {
  const AddPrescriptionToRoutinePage({required this.prescription, super.key});
  final MedicalPrescription prescription;
  @override
  ConsumerState<AddPrescriptionToRoutinePage> createState() =>
      _AddPrescriptionToRoutinePageState();
}

class _AddPrescriptionToRoutinePageState
    extends ConsumerState<AddPrescriptionToRoutinePage> {
  late List<MedicalPrescriptionItem> _items;
  final Map<String, bool> _selected = {};
  final Map<String, TimeOfDay> _times = {};
  final Map<String, bool> _reminders = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = [...widget.prescription.activeItems];
    for (final item in _items.where(_compatible)) {
      _selected[item.id] = false;
      _reminders[item.id] = false;
      final parsed = _parseTime(item.scheduleTimes.firstOrNull);
      if (parsed != null) _times[item.id] = parsed;
    }
  }

  @override
  Widget build(BuildContext context) => HBLoadingOverlay(
    isLoading: _saving,
    message: 'Criando rotinas selecionadas...',
    child: HBPage(
      appBar: const HBAppBar(
        title: 'Adicionar itens à rotina?',
        subtitle: 'Nada será criado sem sua confirmação',
      ),
      children: [
        for (final item in _items.where(_compatible)) ...[
          HBCard(
            child: Column(
              children: [
                CheckboxListTile(
                  value: _selected[item.id] ?? false,
                  title: Text(item.name),
                  subtitle: Text(
                    item.isLinked
                        ? 'Adicionado à rotina'
                        : _label(item.itemType),
                  ),
                  onChanged: item.isLinked
                      ? null
                      : (value) =>
                            setState(() => _selected[item.id] = value ?? false),
                ),
                if ((_selected[item.id] ?? false))
                  Column(
                    children: [
                      HBButton(
                        label: _times[item.id] == null
                            ? 'Escolher horário obrigatório'
                            : 'Horário: ${_times[item.id]!.format(context)}',
                        onPressed: () => _pickTime(item.id),
                      ),
                      CheckboxListTile(
                        value: _reminders[item.id] ?? false,
                        title: const Text('Criar lembrete neste horário'),
                        onChanged: (value) => setState(
                          () => _reminders[item.id] = value ?? false,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const HBGap.sm(),
        ],
        const HBText(
          'Revise os horários e lembretes nas telas de Medicamentos ou Vitaminas. '
          'A prescrição não altera rotinas existentes automaticamente.',
        ),
        const HBGap.lg(),
        HBButton(label: 'Criar rotinas selecionadas', onPressed: _save),
        const HBGap.sm(),
        HBButton(
          label: 'Agora não',
          onPressed: () => context.go(AppRoutes.prescriptions),
        ),
      ],
    ),
  );

  Future<void> _pickTime(String id) async {
    final value = await showTimePicker(
      context: context,
      initialTime: _times[id] ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (value != null) setState(() => _times[id] = value);
  }

  Future<void> _save() async {
    final selected = _items
        .where((item) => _selected[item.id] ?? false)
        .toList();
    if (selected.any((item) => _times[item.id] == null)) {
      HBSnackBar.error(
        context,
        message: 'Escolha o horário de cada item selecionado.',
      );
      return;
    }
    setState(() => _saving = true);
    final now = ref.read(clockServiceProvider).now().toUtc();
    for (final item in selected) {
      final time = _times[item.id]!;
      String? linkedMedicationId = item.linkedMedicationId;
      String? linkedVitaminId = item.linkedVitaminId;
      if (item.itemType == PrescriptionItemType.medication) {
        final existing = (await ref.read(medicationUseCasesProvider).getAll())
            .where(
              (value) =>
                  _normalize(value.formattedName) == _normalize(item.name),
            )
            .firstOrNull;
        if (existing != null) {
          linkedMedicationId = existing.id;
          final index = _items.indexWhere((value) => value.id == item.id);
          _items[index] = item.copyWith(
            linkedMedicationId: linkedMedicationId,
            updatedAt: now,
          );
          continue;
        }
        final id = ref.read(uuidServiceProvider).generate();
        final success = await ref
            .read(medicationViewModelProvider.notifier)
            .createMedication(
              id: id,
              scheduleReminder: _reminders[item.id] ?? false,
              name: item.name,
              hour: time.hour,
              minute: time.minute,
              dosage: _dosage(item),
              notes: item.instructions,
            );
        if (success) linkedMedicationId = id;
      } else {
        final existing = (await ref.read(vitaminUseCasesProvider).getAll())
            .where(
              (value) =>
                  _normalize(value.formattedName) == _normalize(item.name),
            )
            .firstOrNull;
        if (existing != null) {
          linkedVitaminId = existing.id;
          final index = _items.indexWhere((value) => value.id == item.id);
          _items[index] = item.copyWith(
            linkedVitaminId: linkedVitaminId,
            updatedAt: now,
          );
          continue;
        }
        final id = ref.read(uuidServiceProvider).generate();
        final success = await ref
            .read(vitaminViewModelProvider.notifier)
            .createVitamin(
              id: id,
              scheduleReminder: _reminders[item.id] ?? false,
              name: item.name,
              hour: time.hour,
              minute: time.minute,
            );
        if (success) linkedVitaminId = id;
      }
      final index = _items.indexWhere((value) => value.id == item.id);
      _items[index] = item.copyWith(
        linkedMedicationId: linkedMedicationId,
        linkedVitaminId: linkedVitaminId,
        updatedAt: now,
      );
    }
    await ref
        .read(medicalPrescriptionViewModelProvider.notifier)
        .save(widget.prescription.copyWith(items: _items, updatedAt: now));
    if (!mounted) return;
    context.go(AppRoutes.prescriptions);
  }

  bool _compatible(MedicalPrescriptionItem item) =>
      item.itemType == PrescriptionItemType.medication ||
      item.itemType == PrescriptionItemType.vitamin ||
      item.itemType == PrescriptionItemType.supplement;
  String _label(PrescriptionItemType type) =>
      type == PrescriptionItemType.medication
      ? 'Medicamento'
      : 'Vitamina ou suplemento';
  String? _dosage(MedicalPrescriptionItem item) => item.dosageValue == null
      ? null
      : '${item.dosageValue} ${item.dosageUnit ?? ''}'.trim();
  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour, minute: minute);
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
