import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/academy/domain/entities/entities.dart';
import 'package:helpbari/features/baria/domain/models/models.dart';
import 'package:helpbari/features/baria/domain/services/baria_insight_engine.dart';
import 'package:helpbari/features/home/domain/models/models.dart';

void main() {
  const engine = BariaInsightEngine();

  test('generates stable ordered insights with priorities and categories', () {
    final context = _context(
      water: 500,
      goal: 2000,
      vitamins: 1,
      medications: 1,
    );

    final first = engine.generate(context);
    final second = engine.generate(context);

    expect(
      first.map((item) => item.id),
      orderedEquals(second.map((item) => item.id)),
    );
    expect(first.first.priority, BariaInsightPriority.critical);
    expect(first.first.category, BariaInsightCategory.medications);
    expect(
      first.map((item) => item.category),
      containsAll(<BariaInsightCategory>[
        BariaInsightCategory.water,
        BariaInsightCategory.vitamins,
        BariaInsightCategory.medications,
      ]),
    );
  });

  test('academy insight exposes the existing article route', () {
    final insight = engine.generate(_context(article: _article)).single;

    expect(insight.category, BariaInsightCategory.academy);
    expect(insight.action.label, 'Ler artigo');
    expect(
      insight.action.destination,
      AppRoutes.academyArticlePath('water-basics'),
    );
    expect(insight.source, 'Academia Bariátrica');
  });
}

BariaContext _context({
  int? water,
  int? goal,
  int? vitamins,
  int? medications,
  KnowledgeArticle? article,
}) {
  final now = DateTime(2026, 7, 16, 10);
  return BariaContext(
    userId: 'user-a',
    generatedAt: now,
    today: HealthDashboardAggregate(
      periodStart: now,
      periodEnd: now,
      days: <DailyHealthAggregate>[
        DailyHealthAggregate(
          date: now,
          waterMl: water,
          waterGoalMl: goal,
          mealsCount: null,
          proteinGrams: null,
          vitaminAdherence: null,
          medicationAdherence: null,
          weightKg: null,
          healthScore: const HealthScoreResult(
            score: 0,
            hydrationScore: 0,
            proteinScore: 0,
            vitaminsScore: 0,
            medicationsScore: 0,
            mealsScore: 0,
            weightProgressScore: 0,
            availableWeight: 0,
          ),
          pendingVitamins: vitamins,
          pendingMedications: medications,
        ),
      ],
      unavailableSections: const <HealthDataSection>{},
    ),
    week: null,
    month: null,
    report: null,
    syncState: const SyncState(),
    recommendedArticles: article == null
        ? const <KnowledgeArticle>[]
        : <KnowledgeArticle>[article],
  );
}

final _article = KnowledgeArticle(
  id: 'water-basics',
  title: 'Hidratação após bariátrica',
  subtitle: '',
  summary: '',
  blocks: const <KnowledgeBlock>[],
  faq: const <KnowledgeFaq>[],
  tags: const <String>['água'],
  categoryId: 'water',
  bariatricPhases: const <String>[],
  surgeryTypes: const <String>[],
  readingTimeMinutes: 2,
  relatedArticleIds: const <String>[],
  sources: const <KnowledgeReference>[],
  evidenceLevel: KnowledgeEvidenceLevel.consensus,
  lastReviewedAt: DateTime(2026),
  medicalDisclaimer: '',
);
