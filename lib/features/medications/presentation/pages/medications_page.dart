import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/medication_view_model_provider.dart';
import '../widgets/medication_adherence_chart_widget.dart';
import '../widgets/medication_tile.dart';

class MedicationsPage extends ConsumerStatefulWidget {
  const MedicationsPage({super.key});

  @override
  ConsumerState<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends ConsumerState<MedicationsPage> {
  Future<void> _delete(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir medicamento?',
      message: 'O cadastro e o histórico deste medicamento serão removidos.',
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(medicationViewModelProvider.notifier)
        .deleteMedication(id);
    if (mounted && ok) {
      HBSnackBar.success(context, message: 'Medicamento excluído.');
    } else if (mounted) {
      HBSnackBar.error(
        context,
        message:
            ref.read(medicationViewModelProvider).errorMessage ??
            'Não foi possível excluir o medicamento.',
      );
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadMedications);
  }

  Future<void> _loadMedications() async {
    await ref.read(medicationViewModelProvider.notifier).loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationViewModelProvider);

    ref.listen(medicationViewModelProvider, (previous, next) {
      if (next.syncWarning != null &&
          next.syncWarning != previous?.syncWarning) {
        HBSnackBar.warning(context, message: next.syncWarning!);
      }
    });

    return HBLoadingOverlay(
      isLoading: state.isLoading && state.hasMedications,
      message: 'Atualizando medicamentos...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Medicamentos',
          subtitle: 'Acompanhe sua rotina diária',
        ),
        children: [
          const MedicationAdherenceChartWidget(),
          const HBGap.xl(),
          if (state.isLoading && !state.hasMedications)
            const HBLoading(message: 'Carregando medicamentos...')
          else if (state.errorMessage != null && !state.hasMedications)
            HBEmptyState(
              title: 'Não foi possível carregar',
              description: state.errorMessage!,
              icon: Icons.medication_outlined,
              actionLabel: 'Tentar novamente',
              onActionPressed: _loadMedications,
            )
          else if (!state.hasMedications)
            const HBEmptyState(
              title: 'Nenhum medicamento cadastrado',
              description: 'Cadastre seus remédios para acompanhar sua rotina.',
              icon: Icons.medication_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.medications.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final medication = state.medications[index];

                return MedicationTile(
                  medication: medication,
                  status: state.statusFor(medication.id),
                  onTaken: () {
                    ref
                        .read(medicationViewModelProvider.notifier)
                        .markAsTaken(medication.id);
                  },
                  onSkipped: () {
                    ref
                        .read(medicationViewModelProvider.notifier)
                        .markAsSkipped(medication.id);
                  },
                  onEdit: () async {
                    await context.push<bool>(
                      AppRoutes.registerMedication,
                      extra: medication,
                    );
                    await _loadMedications();
                  },
                  onDelete: () => _delete(medication.id),
                );
              },
            ),
          const HBGap.xl(),
          HBButton(
            label: 'Cadastrar medicamento',
            onPressed: () {
              context.pushAndRefresh(
                AppRoutes.registerMedication,
                onRefresh: _loadMedications,
                shouldRefresh: (created) => created == true,
              );
            },
          ),
        ],
      ),
    );
  }
}
