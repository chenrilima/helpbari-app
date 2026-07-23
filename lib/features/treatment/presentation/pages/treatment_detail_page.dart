import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../providers/treatment_providers.dart';

class TreatmentDetailPage extends ConsumerStatefulWidget {
  const TreatmentDetailPage({required this.item, super.key});

  final TreatmentItemSnapshot item;

  @override
  ConsumerState<TreatmentDetailPage> createState() =>
      _TreatmentDetailPageState();
}

class _TreatmentDetailPageState extends ConsumerState<TreatmentDetailPage> {
  late Future<TreatmentDetailSnapshot> _detail;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _detail = ref.read(treatmentStoreProvider).detail(widget.item.id);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _detail;
  }

  @override
  Widget build(BuildContext context) => HBPage(
    appBar: HBAppBar(
      title: widget.item.name,
      subtitle: 'Detalhes do tratamento',
    ),
    children: [
      FutureBuilder<TreatmentDetailSnapshot>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const HBLoading(message: 'Carregando detalhes...');
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return HBEmptyState(
              title: 'Detalhes indisponíveis',
              description: 'Seus dados continuam salvos neste aparelho.',
              icon: Icons.sync_problem_outlined,
              actionLabel: 'Tentar novamente',
              onActionPressed: _refresh,
            );
          }
          final detail = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (detail.conflicts.isNotEmpty) ...[
                for (final conflict in detail.conflicts)
                  _ConflictCard(conflict: conflict, onResolved: _refresh),
                const HBGap.md(),
              ],
              _GeneralCard(item: detail.item, onPrn: _registerPrn),
              const HBGap.md(),
              _Section(
                title: 'Horários e lembretes',
                empty: detail.item.mode == RoutinePlanMode.asNeeded
                    ? 'Uso quando necessário, sem pendência recorrente.'
                    : null,
                children: detail.item.schedules
                    .map(
                      (schedule) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_outlined),
                        title: HBText(schedule.time.toString()),
                        subtitle: HBText(
                          schedule.reminderEnabled
                              ? 'Lembrete ativado'
                              : 'Lembrete desativado',
                        ),
                      ),
                    )
                    .toList(),
              ),
              const HBGap.md(),
              _Section(
                title: 'Histórico e eventos',
                empty: 'Nenhum uso registrado.',
                children: detail.events
                    .map(
                      (event) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_eventIcon(event.type)),
                        title: HBText(_eventLabel(event.type)),
                        subtitle: HBText(
                          '${_dateTime(event.occurredAt)} • ${event.origin}'
                          '${event.note == null ? '' : '\n${event.note}'}',
                        ),
                        trailing: event.isInvalidated
                            ? const HBText('Substituído')
                            : null,
                      ),
                    )
                    .toList(),
              ),
              const HBGap.md(),
              _Section(
                title: 'Revisões',
                children: detail.revisions
                    .map(
                      (revision) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history_outlined),
                        title: HBText('Revisão ${revision.revision}'),
                        subtitle: HBText(
                          'Vigência: ${revision.effectiveFrom}'
                          '${revision.effectiveUntil == null ? '' : ' a ${revision.effectiveUntil}'}',
                        ),
                      ),
                    )
                    .toList(),
              ),
              const HBGap.md(),
              _Section(
                title: 'Pausas e retomadas',
                empty: 'Nenhuma pausa registrada.',
                children: detail.pauses
                    .map(
                      (pause) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pause_circle_outline),
                        title: HBText('Pausa em ${_dateTime(pause.startsAt)}'),
                        subtitle: HBText(
                          pause.endsAt == null
                              ? 'Em andamento'
                              : 'Retomado em ${_dateTime(pause.endsAt!)}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _registerPrn() async {
    final noteController = TextEditingController();
    var usedAt = DateTime.now();
    final confirmed = await HBBottomSheet.show<bool>(
      context,
      title: 'Registrar uso',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const HBText('Horário utilizado'),
              subtitle: HBText(_dateTime(usedAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(usedAt),
                );
                if (time != null) {
                  setSheetState(
                    () => usedAt = DateTime(
                      usedAt.year,
                      usedAt.month,
                      usedAt.day,
                      time.hour,
                      time.minute,
                    ),
                  );
                }
              },
            ),
            TextField(
              controller: noteController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            const HBGap.md(),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar registro'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }
    final success = await ref
        .read(treatmentViewModelProvider.notifier)
        .registerPrnUse(
          id: widget.item.id,
          occurredAt: usedAt,
          note: noteController.text,
        );
    noteController.dispose();
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Uso registrado no histórico.');
      await _refresh();
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(treatmentViewModelProvider).errorMessage ??
            'Não foi possível registrar o uso.',
      );
    }
  }
}

class _GeneralCard extends StatelessWidget {
  const _GeneralCard({required this.item, required this.onPrn});
  final TreatmentItemSnapshot item;
  final VoidCallback onPrn;

  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          'Informações gerais',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const HBGap.sm(),
        HBText('${_category(item.category)} • ${_status(item.status)}'),
        HBText(_duration(item)),
        if (item.weekdays.isNotEmpty)
          HBText('Dias: ${item.weekdays.join(', ')}'),
        if (item.dosage != null) HBText('Dose: ${item.dosage}'),
        if (item.notes != null) HBText('Observações: ${item.notes}'),
        if (item.mode == RoutinePlanMode.asNeeded &&
            item.status == RoutineStatus.active) ...[
          const HBGap.md(),
          FilledButton.icon(
            onPressed: onPrn,
            icon: const Icon(Icons.add_task_outlined),
            label: const Text('Registrar uso'),
          ),
        ],
      ],
    ),
  );
}

class _ConflictCard extends ConsumerWidget {
  const _ConflictCard({required this.conflict, required this.onResolved});
  final TreatmentConflictSnapshot conflict;
  final Future<void> Function() onResolved;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HBText(
          'Registro precisa de revisão',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const HBGap.sm(),
        HBText('Origem: registros feitos em mais de um dispositivo.'),
        HBText('Impacto: ${conflict.impact}'),
        const HBGap.sm(),
        for (final version in conflict.versions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: HBText('${version.origin}: ${_eventLabel(version.type)}'),
            subtitle: HBText(_dateTime(version.occurredAt)),
            trailing: TextButton(
              onPressed: () async {
                final confirmed = await HBDialog.confirm(
                  context,
                  title: 'Usar esta versão?',
                  message:
                      'A outra versão será preservada no histórico como substituída.',
                );
                if (confirmed != true) return;
                final success = await ref
                    .read(treatmentViewModelProvider.notifier)
                    .resolveConflict(
                      occurrenceId: conflict.occurrenceId,
                      keepEventId: version.id,
                    );
                if (success) await onResolved();
              },
              child: const Text('Usar esta'),
            ),
          ),
        const HBText('Você pode cancelar e decidir depois.'),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.empty});
  final String title;
  final List<Widget> children;
  final String? empty;
  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(title, style: Theme.of(context).textTheme.titleMedium),
        const HBGap.sm(),
        if (children.isEmpty)
          HBText(empty ?? 'Nenhum registro.')
        else
          ...children,
      ],
    ),
  );
}

String _category(RoutineCategory value) => switch (value) {
  RoutineCategory.medication => 'Medicamento',
  RoutineCategory.vitamin => 'Vitamina',
  RoutineCategory.supplement => 'Suplemento',
  RoutineCategory.other => 'Outro',
};
String _status(RoutineStatus value) => switch (value) {
  RoutineStatus.active => 'Ativo',
  RoutineStatus.paused => 'Pausado',
  RoutineStatus.completed => 'Concluído',
  RoutineStatus.canceled => 'Cancelado',
  RoutineStatus.archived => 'Arquivado',
};
String _duration(TreatmentItemSnapshot item) => switch (item.durationType) {
  PlanDurationType.bounded =>
    'Duração: ${item.effectiveFrom} a ${item.effectiveUntil}',
  PlanDurationType.continuous => 'Duração: uso contínuo',
  PlanDurationType.unknown => 'Duração não informada',
  PlanDurationType.singleDose => 'Uso único',
};
String _eventLabel(String value) => switch (value) {
  'taken' => 'Uso registrado',
  'skipped' => 'Marcado como não utilizado',
  'correction' => 'Registro corrigido',
  'rescheduled' => 'Horário alterado',
  'canceled' => 'Evento cancelado',
  _ => 'Evento do tratamento',
};
IconData _eventIcon(String value) => switch (value) {
  'taken' => Icons.check_circle_outline,
  'skipped' => Icons.remove_circle_outline,
  'correction' => Icons.history_outlined,
  _ => Icons.event_note_outlined,
};
String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} às ${two(local.hour)}:${two(local.minute)}';
}
