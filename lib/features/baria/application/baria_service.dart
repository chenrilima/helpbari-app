import '../../../core/services/clock_service.dart';
import '../../../core/sync/sync.dart';
import '../../academy/application/knowledge_use_cases.dart';
import '../../academy/domain/entities/entities.dart';
import '../../home/domain/models/models.dart';
import '../domain/models/models.dart';
import '../domain/ports/baria_treatment_context_port.dart';
import 'baria_context_cache.dart';

abstract interface class BariaContextService {
  Future<BariaContext> buildContext();

  List<String> insights(BariaContext context);
}

class BariaService implements BariaContextService {
  BariaService({
    required this.intelligence,
    required ClockService clock,
    required SyncState Function() syncState,
    required String userId,
    KnowledgeUseCases? knowledge,
    required BariaTreatmentContextPort treatment,
    this.cacheDuration = const Duration(minutes: 5),
    BariaContextCache? cache,
  }) : _clock = clock,
       _syncState = syncState,
       _userId = userId,
       _knowledge = knowledge,
       _treatment = treatment,
       _cache = cache ?? BariaContextCache();

  final Future<TodayDashboardReadModel> Function() intelligence;
  final ClockService _clock;
  final SyncState Function() _syncState;
  final String _userId;
  final KnowledgeUseCases? _knowledge;
  final BariaTreatmentContextPort _treatment;
  final Duration cacheDuration;
  final BariaContextCache _cache;

  void invalidate() => _cache.invalidate();

  @override
  Future<BariaContext> buildContext() async {
    final now = _clock.now();
    final cached = _cache.read(
      userId: _userId,
      now: now,
      maxAge: cacheDuration,
    );
    if (cached != null) return cached;
    final values = await Future.wait<Object?>([
      _safe(intelligence),
      _knowledge == null
          ? Future<KnowledgeCatalog?>.value()
          : _safe(() => _knowledge.loadCatalog()),
      _safe(() => _treatment.load(now)),
    ]);
    final dashboard = values[0] as TodayDashboardReadModel?;
    if (dashboard == null || dashboard.userId != _userId) {
      throw StateError('BarIA context user is unavailable or mismatched.');
    }
    final catalog = values[1] as KnowledgeCatalog?;
    final context = BariaContext(
      userId: _userId,
      generatedAt: now,
      today: null,
      week: null,
      month: null,
      report: null,
      syncState: _syncState(),
      recommendedArticles: List.unmodifiable(
        (catalog?.articles ?? const <KnowledgeArticle>[]).take(3),
      ),
      relevantNotifications: const [],
      homeInsights: List.unmodifiable(
        dashboard.insights.insights.map((value) => value.message),
      ),
      treatment: values[2] as BariaTreatmentContext?,
      intelligence: dashboard,
    );
    _cache.write(context);
    return context;
  }

  @override
  List<String> insights(BariaContext context) {
    if (context.userId != _userId) return const [];
    return List.unmodifiable(
      context.intelligence?.insights.insights.map((value) => value.message) ??
          const <String>[],
    );
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }
}
