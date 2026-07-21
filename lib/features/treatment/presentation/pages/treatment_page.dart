import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../medications/presentation/providers/medication_view_model_provider.dart';
import '../../../medications/presentation/widgets/medication_tile.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../../../vitamins/presentation/providers/vitamin_view_model_provider.dart';
import '../../../vitamins/presentation/widgets/vitamin_tile.dart';

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
    Future<void>.microtask(_loadItems);
  }

  Future<TodayTreatmentReadModel> _loadToday() async {
    final service = await ref.read(
      treatmentAdherenceQueryServiceProvider.future,
    );
    return service.today(DateTime.now());
  }

  Future<void> _loadItems() async {
    await ref.read(medicationViewModelProvider.notifier).loadMedications();
    await ref.read(vitaminViewModelProvider.notifier).loadVitamins();
  }

  Future<void> _refresh() async {
    await _loadItems();
    if (!mounted) return;
    setState(() => _today = _loadToday());
  }

  Future<void> _addItem() async {
    final route = await HBBottomSheet.show<String>(
      context,
      title: 'Adicionar ao tratamento',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: const HBText('Medicamento'),
            subtitle: const HBText('Cadastre nome, horário e orientações.'),
            onTap: () => context.pop(AppRoutes.registerMedication),
          ),
          ListTile(
            leading: const Icon(Icons.local_pharmacy_outlined),
            title: const HBText('Vitamina ou suplemento'),
            subtitle: const HBText('Cadastre um item da suplementação.'),
            onTap: () => context.pop(AppRoutes.registerVitamin),
          ),
        ],
      ),
    );
    if (!mounted || route == null) return;
    await context.pushAndRefresh<bool>(route, onRefresh: _refresh);
  }

  @override
  Widget build(BuildContext context) {
    final medications = ref.watch(medicationViewModelProvider);
    final vitamins = ref.watch(vitaminViewModelProvider);
    final loading = medications.isLoading || vitamins.isLoading;

    return HBLoadingOverlay(
      isLoading:
          loading && (medications.hasMedications || vitamins.hasVitamins),
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
          if (loading && !medications.hasMedications && !vitamins.hasVitamins)
            const HBLoading(message: 'Carregando seus itens...')
          else if (!medications.hasMedications && !vitamins.hasVitamins)
            HBEmptyState(
              title: 'Nenhum item cadastrado',
              description:
                  'Adicione medicamentos, vitaminas ou suplementos para organizar seu tratamento.',
              icon: Icons.medication_outlined,
              actionLabel: 'Adicionar item',
              onActionPressed: _addItem,
            )
          else ...[
            for (final medication in medications.medications) ...[
              Semantics(
                label: 'Medicamento',
                child: MedicationTile(
                  medication: medication,
                  status: medications.statusFor(medication.id),
                  onTaken: () => ref
                      .read(medicationViewModelProvider.notifier)
                      .markAsTaken(medication.id),
                  onSkipped: () => ref
                      .read(medicationViewModelProvider.notifier)
                      .markAsSkipped(medication.id),
                  onEdit: () async {
                    await context.push<bool>(
                      AppRoutes.registerMedication,
                      extra: medication,
                    );
                    await _refresh();
                  },
                  onDelete: () => _confirmMedicationDelete(medication.id),
                ),
              ),
              const HBGap.md(),
            ],
            for (final vitamin in vitamins.vitamins) ...[
              Semantics(
                label: 'Vitamina ou suplemento',
                child: VitaminTile(
                  vitamin: vitamin,
                  status: vitamins.statusFor(vitamin.id),
                  onTaken: () => ref
                      .read(vitaminViewModelProvider.notifier)
                      .markAsTaken(vitamin.id),
                  onSkipped: () => ref
                      .read(vitaminViewModelProvider.notifier)
                      .markAsSkipped(vitamin.id),
                  onEdit: () async {
                    await context.push<bool>(
                      AppRoutes.registerVitamin,
                      extra: vitamin,
                    );
                    await _refresh();
                  },
                  onDelete: () => _confirmVitaminDelete(vitamin.id),
                ),
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

  Future<void> _confirmMedicationDelete(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir item?',
      message:
          'O item será removido da lista. O histórico clínico permanece preservado.',
    );
    if (confirmed != true) return;
    await ref.read(medicationViewModelProvider.notifier).deleteMedication(id);
    await _refresh();
  }

  Future<void> _confirmVitaminDelete(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir item?',
      message:
          'O item será removido da lista. O histórico clínico permanece preservado.',
    );
    if (confirmed != true) return;
    await ref.read(vitaminViewModelProvider.notifier).deleteVitamin(id);
    await _refresh();
  }
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
