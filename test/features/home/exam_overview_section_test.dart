import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/home/presentation/widgets/exam_overview_section.dart';
import 'package:helpbari/features/medical_exams/domain/entities/entities.dart';

void main() {
  testWidgets(
    'shows migrated medical exam without results and opens exams route',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) =>
                Scaffold(body: ExamOverviewSection(latestExam: _exam())),
          ),
          GoRoute(
            path: AppRoutes.exams,
            builder: (_, _) => const Scaffold(body: Text('Exames abertos')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Check-up anual'), findsOneWidget);
      expect(find.textContaining('Laboratório Central'), findsOneWidget);

      await tester.tap(find.text('Check-up anual'));
      await tester.pumpAndSettle();

      expect(find.text('Exames abertos'), findsOneWidget);
    },
  );

  testWidgets('shows empty state when there is no medical exam', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExamOverviewSection(latestExam: null)),
      ),
    );

    expect(find.text('Nenhum exame cadastrado'), findsOneWidget);
  });
}

MedicalExam _exam() => MedicalExam(
  id: 'exam-1',
  userId: 'user-a',
  performedAt: DateTime.utc(2026, 7, 18),
  title: 'Check-up anual',
  laboratoryName: 'Laboratório Central',
  source: MedicalExamSource.imported,
  createdAt: DateTime.utc(2026, 7, 18),
  updatedAt: DateTime.utc(2026, 7, 18),
  syncStatus: SyncStatus.synced,
);
