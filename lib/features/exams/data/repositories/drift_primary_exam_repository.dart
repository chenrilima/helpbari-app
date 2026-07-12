import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/drift_exam_local_datasource.dart';
import '../datasources/local_exam_datasource.dart';
import '../dtos/exam_dto.dart';

typedef EnsureExamCutover = Future<void> Function();
typedef HasExamCutoverMirror = bool Function();
Future<void> _noop() async {}
bool _noMirror() => false;

class DriftPrimaryExamRepository implements ExamRepository {
  const DriftPrimaryExamRepository({
    required Future<DriftExamLocalDatasource> Function() drift,
    required LocalExamDatasource fallback,
    required LoggerService logger,
    EnsureExamCutover ensureCutover = _noop,
    HasExamCutoverMirror hasCutoverMirror = _noMirror,
  }) : _drift = drift,
       _fallback = fallback,
       _logger = logger,
       _ensureCutover = ensureCutover,
       _hasCutoverMirror = hasCutoverMirror;
  final Future<DriftExamLocalDatasource> Function() _drift;
  final LocalExamDatasource _fallback;
  final LoggerService _logger;
  final EnsureExamCutover _ensureCutover;
  final HasExamCutoverMirror _hasCutoverMirror;
  Future<DriftExamLocalDatasource> _resolve() async {
    final d = await _drift();
    await _ensureCutover();
    return d;
  }

  @override
  Future<List<Exam>> getAll() async {
    try {
      return (await (await _resolve()).getAll())
          .map((e) => e.toEntity())
          .toList();
    } catch (error) {
      if (_hasCutoverMirror()) {
        throw StateError('Exames indisponíveis temporariamente.');
      }
      _logger.warning(
        'Exams Drift unavailable; legacy fallback (${error.runtimeType}).',
      );
      return (await _fallback.getAll()).map((e) => e.toEntity()).toList();
    }
  }

  Future<void> _save(Exam e) async =>
      (await _resolve()).save(ExamDto.fromEntity(e, now: DateTime.now()));
  @override
  Future<void> save(Exam e) => _save(e);
  @override
  Future<void> update(Exam e) => _save(e);
  @override
  Future<void> delete(String id) async => (await _resolve()).delete(id);
}
