import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/service_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../providers/exam_view_model_provider.dart';
import '../states/exam_state.dart';
import '../widgets/exam_summary_card.dart';
import '../widgets/exam_tile.dart';
import '../../domain/entities/entities.dart';

class ExamsPage extends ConsumerStatefulWidget {
  const ExamsPage({super.key});

  @override
  ConsumerState<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends ConsumerState<ExamsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(examViewModelProvider.notifier).loadItems(),
    );
  }

  Future<void> _load() => ref.read(examViewModelProvider.notifier).loadItems();
  Future<void> _edit(Exam e) async {
    final changed = await context.push<bool>(AppRoutes.registerExam, extra: e);
    if (changed == true) await _load();
  }

  Future<void> _delete(Exam e) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir exame?',
      message: 'O exame e seu anexo serão removidos.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref.read(examViewModelProvider.notifier).deleteExam(e);
    if (!mounted) return;
    if (ok) {
      HBSnackBar.success(context, message: 'Exame excluído.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(examViewModelProvider).errorMessage ??
            'Não foi possível excluir.',
      );
    }
  }

  Future<void> _filterDate() async {
    final now = ref.read(clockServiceProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: ref.read(examViewModelProvider).dateFilter ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
      ref.read(examViewModelProvider.notifier).setDateFilter(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examViewModelProvider);
    final items = state.filteredItems;

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Atualizando exames...',
      child: HBPage(
        appBar: const HBAppBar(title: 'Exames'),
        children: [
          HBText(
            'Acompanhe seus exames realizados.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),

          const HBGap.xl(),

          if (state.attachmentStatus == ExamAttachmentStatus.failed) ...[
            HBEmptyState(
              title: 'Anexo aguardando envio',
              description:
                  state.attachmentError ??
                  'O exame foi salvo e o anexo poderá ser reenviado.',
              icon: Icons.cloud_off_outlined,
              actionLabel: 'Tentar upload novamente',
              onActionPressed: ref
                  .read(examViewModelProvider.notifier)
                  .uploadPendingAttachment,
            ),
            const HBGap.lg(),
          ],

          if (state.latestExam != null)
            ExamSummaryCard(exam: state.latestExam!)
          else
            const HBEmptyState(
              title: 'Nenhum exame cadastrado',
              description: 'Cadastre seu primeiro exame.',
              icon: AppIcons.health,
            ),

          const HBGap.xl(),

          HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),

          const HBGap.md(),

          HBButton(
            label: state.dateFilter == null
                ? 'Filtrar por data'
                : AppDateFormatter.short(state.dateFilter!),
            onPressed: _filterDate,
          ),
          if (state.dateFilter != null) ...[
            const HBGap.sm(),
            HBButton(
              label: 'Limpar filtro',
              onPressed: ref
                  .read(examViewModelProvider.notifier)
                  .clearDateFilter,
            ),
          ],
          const HBGap.md(),

          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar os exames',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _load,
            )
          else if (!state.hasItems)
            const HBEmptyState(
              title: 'Nenhum exame cadastrado',
              description: 'Cadastre seu primeiro exame.',
              icon: AppIcons.health,
            )
          else if (items.isEmpty)
            const HBEmptyState(
              title: 'Nenhum exame nesta data',
              description: 'Selecione outra data.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final exam = items[index];
                return ExamTile(
                  exam: exam,
                  onView: () =>
                      context.push(AppRoutes.examDetails, extra: exam),
                  onEdit: () => _edit(exam),
                  onDelete: () => _delete(exam),
                );
              },
            ),

          const HBGap.xl(),

          HBButton(
            label: 'Cadastrar exame',
            onPressed: () {
              context.pushAndRefresh(
                AppRoutes.registerExam,
                onRefresh: () {
                  return ref.read(examViewModelProvider.notifier).loadItems();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
