import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../design_system/design_system.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../../../smart_routines/domain/value_objects/local_date.dart';
import '../../../smart_routines/domain/value_objects/routine_values.dart';
import '../providers/treatment_providers.dart';

class RegisterTreatmentPage extends ConsumerStatefulWidget {
  const RegisterTreatmentPage({super.key, this.item});

  final TreatmentItemSnapshot? item;

  @override
  ConsumerState<RegisterTreatmentPage> createState() =>
      _RegisterTreatmentPageState();
}

class _RegisterTreatmentPageState extends ConsumerState<RegisterTreatmentPage> {
  static const Uuid _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _notesController;
  late RoutineCategory _category;
  late RoutinePlanMode _mode;
  late PlanDurationType _duration;
  late DateTime _startsOn;
  DateTime? _endsOn;
  late DateTime _singleDoseAt;
  late List<_ScheduleDraft> _schedules;
  late Set<int> _weekdays;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _doseController = TextEditingController(text: item?.dosage ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? RoutineCategory.medication;
    _mode = item?.mode ?? RoutinePlanMode.scheduled;
    _duration = item?.durationType ?? PlanDurationType.unknown;
    _startsOn = _date(item?.effectiveFrom) ?? DateTime.now();
    _endsOn = _date(item?.effectiveUntil);
    _singleDoseAt = DateTime.now().add(const Duration(days: 1));
    _schedules =
        item?.schedules
            .map(
              (value) => _ScheduleDraft(
                time: TimeOfDay(
                  hour: value.time.hour,
                  minute: value.time.minute,
                ),
                reminderEnabled: value.reminderEnabled,
              ),
            )
            .toList() ??
        [_ScheduleDraft(time: const TimeOfDay(hour: 8, minute: 0))];
    _weekdays = {...?item?.weekdays};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _formKey.currentState?.validate() != true) return;
    if (_mode == RoutinePlanMode.scheduled &&
        _duration != PlanDurationType.singleDose &&
        _schedules.isEmpty) {
      HBSnackBar.error(context, message: 'Adicione pelo menos um horário.');
      return;
    }
    if (_duration == PlanDurationType.bounded && _endsOn == null) {
      HBSnackBar.error(context, message: 'Informe a data de término.');
      return;
    }
    final command = TreatmentWriteCommand(
      id: widget.item?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      category: _category,
      mode: _mode,
      durationType: _mode == RoutinePlanMode.asNeeded
          ? PlanDurationType.unknown
          : _duration,
      effectiveFrom: LocalDate.fromDateTime(_startsOn),
      effectiveUntil: _duration == PlanDurationType.bounded && _endsOn != null
          ? LocalDate.fromDateTime(_endsOn!)
          : null,
      singleDoseAt: _duration == PlanDurationType.singleDose
          ? _singleDoseAt
          : null,
      weekdays: _weekdays,
      schedules:
          _mode == RoutinePlanMode.asNeeded ||
              _duration == PlanDurationType.singleDose
          ? const []
          : _schedules.map(
              (value) => TreatmentScheduleInput(
                time: TimeOfDayValue(
                  hour: value.time.hour,
                  minute: value.time.minute,
                ),
                reminderEnabled: value.reminderEnabled,
              ),
            ),
      dosage: _doseController.text,
      notes: _notesController.text,
    );
    final impact = await ref
        .read(treatmentViewModelProvider.notifier)
        .impactFor(command);
    if (!mounted) return;
    if (impact.createsRevision) {
      final confirmed = await HBDialog.confirm(
        context,
        title: 'Aplicar alterações daqui para frente?',
        message:
            'A nova programação será usada no futuro. Seu histórico anterior será preservado.',
      );
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    final success = await ref
        .read(treatmentViewModelProvider.notifier)
        .save(command);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!success) {
      HBSnackBar.error(
        context,
        message:
            ref.read(treatmentViewModelProvider).errorMessage ??
            'Não foi possível salvar o item.',
      );
      return;
    }
    HBSnackBar.success(context, message: 'Item salvo no aparelho.');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheduled = _mode == RoutinePlanMode.scheduled;
    return HBLoadingOverlay(
      isLoading: _saving,
      child: HBPage(
        appBar: HBAppBar(
          title: _editing ? 'Editar item' : 'Adicionar item',
          subtitle: 'Configure sem alterar registros anteriores',
        ),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(context, 'Identificação'),
                const HBGap.sm(),
                HBCard(
                  child: Column(
                    children: [
                      HBTextField(
                        controller: _nameController,
                        label: 'Nome do item',
                        inputFormatters: AppInputFormatters.text(
                          maxLength: 120,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Informe o nome do item.'
                            : null,
                      ),
                      const HBGap.md(),
                      DropdownButtonFormField<RoutineCategory>(
                        isExpanded: true,
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: RoutineCategory.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_categoryLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _category = value!),
                      ),
                      const HBGap.md(),
                      HBTextField(
                        controller: _doseController,
                        label: 'Dose ou descrição (opcional)',
                        inputFormatters: AppInputFormatters.text(
                          maxLength: 120,
                        ),
                      ),
                      const HBGap.md(),
                      HBTextField(
                        controller: _notesController,
                        label: 'Observações (opcional)',
                        maxLines: 3,
                        inputFormatters: AppInputFormatters.text(
                          maxLength: 500,
                        ),
                      ),
                    ],
                  ),
                ),
                const HBGap.xl(),
                _sectionTitle(context, 'Programação'),
                const HBGap.sm(),
                HBCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<RoutinePlanMode>(
                        isExpanded: true,
                        initialValue: _mode,
                        decoration: const InputDecoration(labelText: 'Uso'),
                        items: const [
                          DropdownMenuItem(
                            value: RoutinePlanMode.scheduled,
                            child: Text('Programado'),
                          ),
                          DropdownMenuItem(
                            value: RoutinePlanMode.asNeeded,
                            child: Text('Quando necessário'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _mode = value!),
                      ),
                      if (_mode == RoutinePlanMode.asNeeded) ...[
                        const HBGap.md(),
                        const HBText(
                          'Este item não criará pendências recorrentes. O uso poderá ser registrado quando acontecer.',
                        ),
                      ],
                      if (scheduled) ...[
                        const HBGap.md(),
                        DropdownButtonFormField<PlanDurationType>(
                          isExpanded: true,
                          initialValue: _duration,
                          decoration: const InputDecoration(
                            labelText: 'Duração',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: PlanDurationType.unknown,
                              child: Text('Duração não informada'),
                            ),
                            DropdownMenuItem(
                              value: PlanDurationType.continuous,
                              child: Text('Uso contínuo'),
                            ),
                            DropdownMenuItem(
                              value: PlanDurationType.bounded,
                              child: Text('Período definido'),
                            ),
                            DropdownMenuItem(
                              value: PlanDurationType.singleDose,
                              child: Text('Uso único'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _duration = value!),
                        ),
                        const HBGap.md(),
                        _DateAction(
                          label: 'Início',
                          value: _startsOn,
                          onPressed: () => _pickDate(
                            _startsOn,
                            (value) => _startsOn = value,
                          ),
                        ),
                        if (_duration == PlanDurationType.bounded) ...[
                          const HBGap.sm(),
                          _DateAction(
                            label: 'Término',
                            value: _endsOn,
                            onPressed: () => _pickDate(
                              _endsOn ?? _startsOn,
                              (value) => _endsOn = value,
                            ),
                          ),
                        ],
                        if (_duration == PlanDurationType.singleDose) ...[
                          const HBGap.sm(),
                          _DateAction(
                            label: 'Data do uso único',
                            value: _singleDoseAt,
                            onPressed: _pickSingleDose,
                          ),
                        ] else ...[
                          const HBGap.lg(),
                          _weekdaySelector(),
                          const HBGap.md(),
                          for (
                            var index = 0;
                            index < _schedules.length;
                            index++
                          )
                            _scheduleRow(index),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addTime,
                              icon: const Icon(Icons.add_alarm_outlined),
                              label: const Text('Adicionar horário'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const HBGap.xl(),
                const HBCard(
                  child: HBText(
                    'Alterações de programação valem apenas daqui para frente. O histórico permanece preservado.',
                  ),
                ),
                const HBGap.lg(),
                HBButton(
                  label: _editing ? 'Salvar alterações' : 'Salvar item',
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekdaySelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const HBText('Dias da semana (vazio significa todos os dias)'),
      const HBGap.sm(),
      Wrap(
        spacing: 6,
        children: List.generate(7, (index) {
          final day = index + 1;
          return FilterChip(
            label: Text(
              const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][index],
            ),
            selected: _weekdays.contains(day),
            onSelected: (selected) => setState(() {
              selected ? _weekdays.add(day) : _weekdays.remove(day);
            }),
          );
        }),
      ),
    ],
  );

  Widget _scheduleRow(int index) {
    final draft = _schedules[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(index),
              icon: const Icon(Icons.schedule),
              label: Text(draft.time.format(context)),
            ),
          ),
          IconButton(
            tooltip: draft.reminderEnabled
                ? 'Desativar lembrete deste horário'
                : 'Ativar lembrete deste horário',
            onPressed: () => setState(() {
              draft.reminderEnabled = !draft.reminderEnabled;
            }),
            icon: Icon(
              draft.reminderEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Remover horário',
            onPressed: _schedules.length == 1
                ? null
                : () => setState(() => _schedules.removeAt(index)),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null || !mounted) return;
    if (_schedules.any((value) => value.time == time)) {
      HBSnackBar.error(context, message: 'Esse horário já foi adicionado.');
      return;
    }
    setState(() => _schedules.add(_ScheduleDraft(time: time)));
  }

  Future<void> _pickTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _schedules[index].time,
    );
    if (time != null && mounted) setState(() => _schedules[index].time = time);
  }

  Future<void> _pickDate(
    DateTime initial,
    void Function(DateTime) update,
  ) async {
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null && mounted) setState(() => update(value));
  }

  Future<void> _pickSingleDose() async {
    await _pickDate(_singleDoseAt, (value) {
      _singleDoseAt = DateTime(
        value.year,
        value.month,
        value.day,
        _singleDoseAt.hour,
        _singleDoseAt.minute,
      );
    });
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_singleDoseAt),
    );
    if (time != null && mounted) {
      setState(() {
        _singleDoseAt = DateTime(
          _singleDoseAt.year,
          _singleDoseAt.month,
          _singleDoseAt.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  static Widget _sectionTitle(BuildContext context, String value) => Semantics(
    header: true,
    child: HBText(value, style: Theme.of(context).textTheme.titleLarge),
  );

  static String _categoryLabel(RoutineCategory value) => switch (value) {
    RoutineCategory.medication => 'Medicamento',
    RoutineCategory.vitamin => 'Vitamina',
    RoutineCategory.supplement => 'Suplemento',
    RoutineCategory.other => 'Outro',
  };

  static DateTime? _date(LocalDate? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);
}

final class _ScheduleDraft {
  _ScheduleDraft({required this.time, this.reminderEnabled = true});
  TimeOfDay time;
  bool reminderEnabled;
}

class _DateAction extends StatelessWidget {
  const _DateAction({
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined),
    label: Text(
      value == null
          ? '$label: selecionar'
          : '$label: ${value!.day.toString().padLeft(2, '0')}/'
                '${value!.month.toString().padLeft(2, '0')}/${value!.year}',
    ),
  );
}
