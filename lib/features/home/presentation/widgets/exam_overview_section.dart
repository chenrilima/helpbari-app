import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../exams/domain/entities/entities.dart';
import '../../../exams/presentation/widgets/exam_summary_card.dart';
import '../../../home/presentation/widgets/home_section.dart';

class ExamOverviewSection extends StatelessWidget {
  const ExamOverviewSection({
    required this.latestExam,
    this.onRefresh,
    super.key,
  });

  final Exam? latestExam;
  final Future<void> Function()? onRefresh;

  Future<void> _openExams(BuildContext context) async {
    await context.push(AppRoutes.exams);
    await onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Exames',
      subtitle: 'Acompanhe seus exames realizados.',
      child: latestExam != null
          ? InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => _openExams(context),
              child: ExamSummaryCard(exam: latestExam!),
            )
          : HBEmptyState(
              title: 'Nenhum exame cadastrado',
              description: 'Cadastre seus exames para acompanhar sua saúde.',
              icon: AppIcons.health,
              onTap: () => _openExams(context),
            ),
    );
  }
}
