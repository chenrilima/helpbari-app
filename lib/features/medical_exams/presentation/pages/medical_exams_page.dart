import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_exam_view_model_provider.dart';

class MedicalExamsPage extends ConsumerStatefulWidget {
  const MedicalExamsPage({super.key});

  @override
  ConsumerState<MedicalExamsPage> createState() => _MedicalExamsPageState();
}

class _MedicalExamsPageState extends ConsumerState<MedicalExamsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(medicalExamViewModelProvider.notifier).loadHistory(),
    );
  }

  Future<void> _openRegister([MedicalExam? exam]) async {
    final changed = await context.push<bool>(
      AppRoutes.registerExam,
      extra: exam,
    );
    if (changed == true) {
      await ref.read(medicalExamViewModelProvider.notifier).loadHistory();
    }
  }

  Future<void> _openDetails(MedicalExam exam) async {
    await context.push<void>(AppRoutes.examDetails, extra: exam);
    await ref.read(medicalExamViewModelProvider.notifier).loadHistory();
  }

  Future<void> _delete(MedicalExam exam) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir exame?',
      message: 'A exclusão será lógica e sincronizada quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(medicalExamViewModelProvider.notifier)
        .delete(exam);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Exame excluído com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(medicalExamViewModelProvider).errorMessage ??
            'Não foi possível excluir o exame.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalExamViewModelProvider);
    final latestExam = state.latestExam;

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Carregando exames...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Exames',
          subtitle: 'Acompanhe seus exames laboratoriais',
        ),
        children: [
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar os exames',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: () =>
                  ref.read(medicalExamViewModelProvider.notifier).loadHistory(),
            )
          else if (!state.hasItems)
            HBEmptyState(
              title: 'Nenhum exame registrado',
              description:
                  'Cadastre manualmente ou importe uma foto de resultado de exame.',
              icon: AppIcons.health,
              actionLabel: 'Cadastrar exame',
              onActionPressed: _openRegister,
            )
          else ...[
            if (latestExam != null) ...[
              HBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HBText('Último exame'),
                    const HBGap.sm(),
                    HBText(
                      latestExam.title?.trim().isNotEmpty == true
                          ? latestExam.title!
                          : 'Exame laboratorial',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const HBGap.sm(),
                    HBText(
                      'Data: ${AppDateFormatter.short(latestExam.performedAt)}',
                    ),
                    HBText(
                      '${latestExam.activeResultsCount} marcador(es) registrado(s)',
                    ),
                  ],
                ),
              ),
              const HBGap.lg(),
            ],
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final exam = state.items[index];
                return HBCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HBText(
                        exam.title?.trim().isNotEmpty == true
                            ? exam.title!
                            : 'Exame laboratorial',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const HBGap.sm(),
                      HBText(
                        AppDateFormatter.short(exam.performedAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if ((exam.laboratoryName?.trim().isNotEmpty ?? false))
                        HBText(exam.laboratoryName!),
                      HBText('${exam.activeResultsCount} resultado(s)'),
                      const HBGap.md(),
                      Row(
                        children: [
                          Expanded(
                            child: HBButton(
                              label: 'Ver detalhes',
                              onPressed: () => _openDetails(exam),
                            ),
                          ),
                          const HBGap.md(),
                          Expanded(
                            child: HBButton(
                              label: 'Editar',
                              onPressed: () => _openRegister(exam),
                            ),
                          ),
                        ],
                      ),
                      const HBGap.sm(),
                      HBButton(
                        label: 'Excluir',
                        onPressed: () => _delete(exam),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const HBGap.xl(),
          HBButton(label: 'Novo exame', onPressed: () => _openRegister()),
        ],
      ),
    );
  }
}
