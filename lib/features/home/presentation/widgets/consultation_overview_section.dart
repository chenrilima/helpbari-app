import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../medical_consultations/domain/entities/entities.dart';
import 'home_section.dart';

class ConsultationOverviewSection extends StatelessWidget {
  const ConsultationOverviewSection({
    required this.latestConsultation,
    required this.subtitle,
    this.onRefresh,
    super.key,
  });

  final MedicalConsultation? latestConsultation;
  final String subtitle;
  final Future<void> Function()? onRefresh;

  Future<void> _open(BuildContext context) async {
    await context.push(AppRoutes.medicalConsultations);
    await onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Consultas registradas',
      subtitle: subtitle,
      action: TextButton(
        onPressed: () => _open(context),
        child: const Text('Ver'),
      ),
      child: latestConsultation == null
          ? const HBEmptyState(
              title: 'Nenhuma consulta registrada',
              description:
                  'Salve seu último atendimento para acompanhar orientações e evolução.',
              icon: AppIcons.health,
            )
          : HBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HBText(
                    latestConsultation!.title?.trim().isNotEmpty == true
                        ? latestConsultation!.title!
                        : 'Consulta clínica',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const HBGap.sm(),
                  HBText(
                    AppDateFormatter.short(latestConsultation!.consultationAt),
                  ),
                  if (latestConsultation!.professionalName?.trim().isNotEmpty ==
                      true)
                    HBText(latestConsultation!.professionalName!),
                  if (latestConsultation!.specialty?.trim().isNotEmpty == true)
                    HBText(latestConsultation!.specialty!),
                ],
              ),
            ),
    );
  }
}
