import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_consultation_view_model_provider.dart';

class MedicalConsultationsPage extends ConsumerStatefulWidget {
  const MedicalConsultationsPage({super.key});

  @override
  ConsumerState<MedicalConsultationsPage> createState() =>
      _MedicalConsultationsPageState();
}

class _MedicalConsultationsPageState
    extends ConsumerState<MedicalConsultationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(medicalConsultationViewModelProvider.notifier).loadHistory(),
    );
  }

  Future<void> _openRegister([MedicalConsultation? consultation]) async {
    final changed = await context.push<bool>(
      AppRoutes.registerMedicalConsultation,
      extra: consultation,
    );
    if (changed == true) {
      await ref
          .read(medicalConsultationViewModelProvider.notifier)
          .loadHistory();
    }
  }

  Future<void> _openDetails(MedicalConsultation consultation) async {
    await context.push(
      AppRoutes.medicalConsultationDetails,
      extra: consultation,
    );
    await ref.read(medicalConsultationViewModelProvider.notifier).loadHistory();
  }

  Future<void> _delete(MedicalConsultation consultation) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir consulta?',
      message: 'A exclusão será lógica e sincronizada quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(medicalConsultationViewModelProvider.notifier)
        .delete(consultation);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Consulta excluída com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(medicalConsultationViewModelProvider).errorMessage ??
            'Não foi possível excluir a consulta.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalConsultationViewModelProvider);
    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Carregando consultas realizadas...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Consultas realizadas',
          subtitle: 'Histórico de atendimentos e orientações clínicas',
        ),
        children: [
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar o histórico de consultas',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: () => ref
                  .read(medicalConsultationViewModelProvider.notifier)
                  .loadHistory(),
            )
          else if (!state.hasItems)
            HBEmptyState(
              title: 'Nenhuma consulta realizada',
              description:
                  'Cadastre manualmente ou importe um documento de atendimento.',
              icon: AppIcons.health,
              actionLabel: 'Registrar consulta',
              onActionPressed: _openRegister,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final consultation = state.items[index];
                return HBCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HBText(
                        consultation.title?.trim().isNotEmpty == true
                            ? consultation.title!
                            : 'Consulta realizada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const HBGap.sm(),
                      HBText(
                        AppDateFormatter.short(consultation.consultationAt),
                      ),
                      if (consultation.professionalName?.trim().isNotEmpty ==
                          true)
                        HBText(consultation.professionalName!),
                      if (consultation.specialty?.trim().isNotEmpty == true)
                        HBText(consultation.specialty!),
                      const HBGap.md(),
                      Row(
                        children: [
                          Expanded(
                            child: HBButton(
                              label: 'Ver detalhes',
                              onPressed: () => _openDetails(consultation),
                            ),
                          ),
                          const HBGap.md(),
                          Expanded(
                            child: HBButton(
                              label: 'Editar',
                              onPressed: () => _openRegister(consultation),
                            ),
                          ),
                        ],
                      ),
                      const HBGap.sm(),
                      HBButton(
                        label: 'Excluir',
                        onPressed: () => _delete(consultation),
                      ),
                    ],
                  ),
                );
              },
            ),
          const HBGap.xl(),
          HBButton(
            label: 'Registrar consulta',
            onPressed: () => _openRegister(),
          ),
        ],
      ),
    );
  }
}
