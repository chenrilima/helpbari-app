import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/medication_view_model_provider.dart';
import '../widgets/medication_tile.dart';

class MedicationsPage extends ConsumerStatefulWidget {
  const MedicationsPage({super.key});

  @override
  ConsumerState<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends ConsumerState<MedicationsPage> {
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

    return HBPage(
      appBar: const HBAppBar(
        title: 'Medicamentos',
        subtitle: 'Acompanhe sua rotina diária',
      ),
      children: [
        if (!state.hasMedications)
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
            separatorBuilder: (_, __) => const HBGap.md(),
            itemBuilder: (_, index) {
              final medication = state.medications[index];

              return MedicationTile(
                medication: medication,
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
    );
  }
}
