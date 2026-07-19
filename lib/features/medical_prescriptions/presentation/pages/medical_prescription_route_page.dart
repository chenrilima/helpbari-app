import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';
import 'add_prescription_to_routine_page.dart';
import 'medical_prescription_details_page.dart';
import 'register_medical_prescription_page.dart';

enum MedicalPrescriptionRouteMode { details, edit, review, addToRoutine }

class MedicalPrescriptionRoutePage extends ConsumerWidget {
  const MedicalPrescriptionRoutePage({
    required this.id,
    required this.mode,
    super.key,
  });
  final String id;
  final MedicalPrescriptionRouteMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
    future: ref.read(medicalPrescriptionUseCasesProvider).getById(id),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const HBPage(
          appBar: HBAppBar(title: 'Prescrição'),
          children: [Center(child: CircularProgressIndicator())],
        );
      }
      final value = snapshot.data;
      if (value == null) {
        return const HBPage(
          appBar: HBAppBar(title: 'Prescrição'),
          children: [
            HBEmptyState(
              title: 'Prescrição não encontrada',
              description:
                  'O registro pode ter sido removido ou ainda não sincronizou.',
            ),
          ],
        );
      }
      return _page(value);
    },
  );

  Widget _page(MedicalPrescription value) => switch (mode) {
    MedicalPrescriptionRouteMode.details => MedicalPrescriptionDetailsPage(
      prescription: value,
    ),
    MedicalPrescriptionRouteMode.edit => RegisterMedicalPrescriptionPage(
      prescription: value,
    ),
    MedicalPrescriptionRouteMode.review => RegisterMedicalPrescriptionPage(
      prescription: value,
      importDocument: true,
    ),
    MedicalPrescriptionRouteMode.addToRoutine => AddPrescriptionToRoutinePage(
      prescription: value,
    ),
  };
}
