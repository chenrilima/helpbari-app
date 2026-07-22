import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../providers/treatment_providers.dart';

class TreatmentPage extends ConsumerStatefulWidget {
  const TreatmentPage({super.key});

  @override
  ConsumerState<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends ConsumerState<TreatmentPage> {
  late Future<TodayTreatmentReadModel> _today;

  @override
  void initState() {
    super.initState();
    _today = _loadToday();
    Future<void>.microtask(
      () => ref.read(treatmentViewModelProvider.notifier).load(),
    );
  }

  Future<TodayTreatmentReadModel> _loadToday() async {
    final service = await ref.read(
      treatmentAdherenceQueryServiceProvider.future,
    );
    return service.today(DateTime.now());
  }

  Future<void> _refresh() async {
    await ref.read(treatmentViewModelProvider.notifier).load();
    if (!mounted) return;
    final today = _loadToday();
    setState(() {
      _today = today;
    });
  }

  Future<void> _addItem() async {
    await context.pushAndRefresh<bool>(
      AppRoutes.registerTreatment,
      onRefresh: _refresh,
      shouldRefresh: (result) => result == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final treatment = ref.watch(treatmentViewModelProvider);
    final loading = treatment.isLoading;

    return HBLoadingOverlay(
      isLoading: loading && treatment.items.isNotEmpty,
      message: 'Atualizando tratamento...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Tratamento',
          subtitle: 'O que você precisa tomar ou acompanhar',
        ),
        children: [
          Semantics(
            header: true,
            child: HBText(
              'Hoje',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const HBGap.sm(),
          FutureBuilder<TodayTreatmentReadModel>(
            future: _today,
            builder: (context, snapshot) => _TodayCard(snapshot: snapshot),
          ),
          const HBGap.xl(),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: HBText(
                    'Itens',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar item'),
              ),
            ],
          ),
          const HBGap.sm(),
          if (loading && treatment.items.isEmpty)
            const HBLoading(message: 'Carregando seus itens...')
          else if (treatment.errorMessage != null && treatment.items.isEmpty)
            HBEmptyState(
              title: 'Não foi possível carregar os itens',
              description: treatment.errorMessage!,
              icon: Icons.sync_problem_outlined,
              actionLabel: 'Tentar novamente',
              onActionPressed: _refresh,
            )
          else if (treatment.items.isEmpty)
            HBEmptyState(
              title: 'Nenhum item cadastrado',
              description:
                  'Adicione medicamentos, vitaminas ou suplementos para organizar seu tratamento.',
              icon: Icons.medication_outlined,
              actionLabel: 'Adicionar item',
              onActionPressed: _addItem,
            )
          else ...[
            for (final item in treatment.items) ...[
              _TreatmentItemCard(
                item: item,
                onOpen: () async {
                  final changed = await context.push<bool>(
                    AppRoutes.treatmentDetail,
                    extra: item,
                  );
                  if (changed == true && mounted) await _refresh();
                },
                onEdit: () async {
                  final changed = await context.push<bool>(
                    AppRoutes.registerTreatment,
                    extra: item,
                  );
                  if (changed == true && mounted) await _refresh();
                },
                onPause: () => _confirmLifecycle(item, _Lifecycle.pause),
                onResume: () => _confirmLifecycle(item, _Lifecycle.resume),
                onComplete: () => _confirmLifecycle(item, _Lifecycle.complete),
                onDelete: () => _confirmLifecycle(item, _Lifecycle.delete),
              ),
              const HBGap.md(),
            ],
          ],
          const HBGap.lg(),
          const HBCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_outlined),
              title: HBText('Histórico preservado'),
              subtitle: HBText(
                'Os registros permanecem vinculados ao item e às revisões do tratamento.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLifecycle(
    TreatmentItemSnapshot item,
    _Lifecycle action,
  ) async {
    final (title, message) = switch (action) {
      _Lifecycle.pause => (
        'Pausar item?',
        'As próximas programações serão interrompidas até você retomar. O histórico será preservado.',
      ),
      _Lifecycle.resume => (
        'Retomar item?',
        'As próximas programações voltarão a aparecer. O período de pausa será preservado.',
      ),
      _Lifecycle.complete => (
        'Concluir item?',
        'Não serão criadas novas programações. O histórico será preservado.',
      ),
      _Lifecycle.delete => (
        'Excluir item?',
        'O item será removido da lista. O histórico clínico permanece preservado.',
      ),
    };
    final confirmed = await HBDialog.confirm(
      context,
      title: title,
      message: message,
    );
    if (confirmed != true) return;
    final notifier = ref.read(treatmentViewModelProvider.notifier);
    final success = switch (action) {
      _Lifecycle.pause => await notifier.pause(item.id),
      _Lifecycle.resume => await notifier.resume(item.id),
      _Lifecycle.complete => await notifier.complete(item.id),
      _Lifecycle.delete => await notifier.delete(item.id),
    };
    if (!mounted) return;
    if (!success) {
      HBSnackBar.error(
        context,
        message:
            ref.read(treatmentViewModelProvider).errorMessage ??
            'Não foi possível atualizar o item.',
      );
    }
    await _refresh();
  }
}

enum _Lifecycle { pause, resume, complete, delete }

class _TreatmentItemCard extends StatelessWidget {
  const _TreatmentItemCard({
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onDelete,
  });

  final TreatmentItemSnapshot item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${_category(item.category)}: ${item.name}',
    child: HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onOpen,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_icon(item.category)),
            title: HBText(item.name),
            subtitle: HBText(_summary(item)),
            trailing: PopupMenuButton<_Lifecycle>(
              tooltip: 'Ações do item',
              onSelected: (value) => switch (value) {
                _Lifecycle.pause => onPause(),
                _Lifecycle.resume => onResume(),
                _Lifecycle.complete => onComplete(),
                _Lifecycle.delete => onDelete(),
              },
              itemBuilder: (_) => [
                if (item.status == RoutineStatus.active)
                  const PopupMenuItem(
                    value: _Lifecycle.pause,
                    child: Text('Pausar'),
                  ),
                if (item.status == RoutineStatus.paused)
                  const PopupMenuItem(
                    value: _Lifecycle.resume,
                    child: Text('Retomar'),
                  ),
                if (item.status == RoutineStatus.active ||
                    item.status == RoutineStatus.paused)
                  const PopupMenuItem(
                    value: _Lifecycle.complete,
                    child: Text('Concluir'),
                  ),
                const PopupMenuItem(
                  value: _Lifecycle.delete,
                  child: Text('Excluir'),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(label: Text(_status(item.status))),
              Chip(label: Text(_duration(item))),
              if (item.mode == RoutinePlanMode.asNeeded)
                const Chip(label: Text('Quando necessário')),
            ],
          ),
          const HBGap.sm(),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              children: [
                TextButton(
                  onPressed: onOpen,
                  child: const Text('Ver detalhes'),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static String _summary(TreatmentItemSnapshot item) {
    if (item.mode == RoutinePlanMode.asNeeded) {
      return item.dosage ?? 'Uso quando necessário';
    }
    final times = item.schedules
        .map((value) => value.time.toString())
        .join(', ');
    return [
      item.dosage,
      if (times.isNotEmpty) times,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
  }

  static String _category(RoutineCategory value) => switch (value) {
    RoutineCategory.medication => 'Medicamento',
    RoutineCategory.vitamin => 'Vitamina',
    RoutineCategory.supplement => 'Suplemento',
    RoutineCategory.other => 'Outro',
  };
  static IconData _icon(RoutineCategory value) => switch (value) {
    RoutineCategory.medication => Icons.medication_outlined,
    RoutineCategory.vitamin => Icons.local_pharmacy_outlined,
    RoutineCategory.supplement => Icons.science_outlined,
    RoutineCategory.other => Icons.more_horiz,
  };
  static String _status(RoutineStatus value) => switch (value) {
    RoutineStatus.active => 'Ativo',
    RoutineStatus.paused => 'Pausado',
    RoutineStatus.completed => 'Concluído',
    RoutineStatus.canceled => 'Cancelado',
    RoutineStatus.archived => 'Arquivado',
  };
  static String _duration(TreatmentItemSnapshot item) =>
      switch (item.durationType) {
        PlanDurationType.bounded => 'Período definido',
        PlanDurationType.continuous => 'Uso contínuo',
        PlanDurationType.unknown => 'Duração não informada',
        PlanDurationType.singleDose => 'Uso único',
      };
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.snapshot});

  final AsyncSnapshot<TodayTreatmentReadModel> snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const HBCard(
        child: HBLoading(message: 'Carregando itens de hoje...'),
      );
    }
    if (snapshot.hasError) {
      return const HBCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.cloud_off_outlined),
          title: HBText('Itens de hoje indisponíveis'),
          subtitle: HBText('Seus cadastros continuam disponíveis abaixo.'),
        ),
      );
    }
    final model = snapshot.data!;
    if (model.occurrences.isEmpty) {
      return const HBCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.event_available_outlined),
          title: HBText('Nenhum item previsto para hoje'),
          subtitle: HBText(
            'Itens quando necessário não aparecem como pendência.',
          ),
        ),
      );
    }
    return HBCard(
      child: Column(
        children: [
          for (final occurrence in model.occurrences)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_categoryIcon(occurrence.category)),
              title: HBText(occurrence.title),
              subtitle: HBText(
                TimeOfDay.fromDateTime(
                  occurrence.scheduledFor.toLocal(),
                ).format(context),
              ),
              trailing: HBText(_stateLabel(occurrence.operationalState)),
            ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(RoutineCategory category) => switch (category) {
    RoutineCategory.medication => Icons.medication_outlined,
    RoutineCategory.vitamin => Icons.local_pharmacy_outlined,
    RoutineCategory.supplement => Icons.science_outlined,
    RoutineCategory.other => Icons.more_horiz,
  };

  static String _stateLabel(TreatmentOccurrenceState state) => switch (state) {
    TreatmentOccurrenceState.future => 'Mais tarde',
    TreatmentOccurrenceState.due || TreatmentOccurrenceState.open => 'Pendente',
    TreatmentOccurrenceState.resolved => 'Concluído',
    TreatmentOccurrenceState.missed => 'Sem registro',
    TreatmentOccurrenceState.canceled => 'Cancelado',
    TreatmentOccurrenceState.requiresReview => 'Revisar',
  };
}
