import '../../../../core/formatters/formatters.dart';
import '../../application/baria_service.dart';
import '../../../home/domain/models/models.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/baria_repository.dart';

class ContextualBariaRepository implements BariaRepository {
  ContextualBariaRepository(this._service);

  final BariaContextService _service;
  final List<BariaMessage> _conversationHistory = [];
  static const _notice =
      'Este é um indicador de acompanhamento e não substitui avaliação clínica.';

  @override
  Future<BariaContext> getContext() => _service.buildContext();

  @override
  Future<BariaInsight> getDailyInsight() async {
    final context = await getContext();
    final insights = _service.insights(context);
    final message = insights.isEmpty
        ? 'Não há dados suficientes para gerar um insight hoje.'
        : insights.first;
    return BariaInsight(
      id: '${context.userId}:${context.generatedAt.toIso8601String()}',
      title: insights.isEmpty
          ? 'Continue registrando'
          : 'Resumo determinístico',
      message: '$message $_notice',
      createdAt: context.generatedAt,
    );
  }

  @override
  Future<List<BariaMessage>> getConversationHistory() async =>
      List.unmodifiable(_conversationHistory);

  @override
  Future<void> saveMessage(BariaMessage message) async {
    _conversationHistory.add(message);
  }

  @override
  Future<String> generateResponse(String userMessage) async {
    final context = await getContext();
    final query = _normalize(userMessage);
    if (!context.hasAnyData) {
      return _missing('dados da sua rotina');
    }
    if (_contains(query, ['agua', 'hidratacao', 'meta'])) {
      return _water(context);
    }
    if (_contains(query, ['semana', 'semanal'])) {
      return _period(context.week, 'semana');
    }
    if (_contains(query, ['mes', 'mensal', 'historico'])) {
      return _period(context.month, 'mês');
    }
    if (_contains(query, ['peso', 'perdi', 'emagreci', 'evolucao'])) {
      return _weight(context);
    }
    if (_contains(query, ['vitamina', 'esqueci'])) {
      return _vitamins(context);
    }
    if (_contains(query, ['medicamento', 'remedio'])) {
      return _medications(context);
    }
    if (_contains(query, ['pendente', 'offline', 'sincronizacao', 'sync'])) {
      return _pending(context);
    }
    if (_contains(query, ['consulta', 'medico'])) {
      return _appointment(context);
    }
    if (_contains(query, ['exame'])) {
      return _exams(context);
    }
    if (_contains(query, ['refeicao', 'comida', 'proteina'])) {
      return _meals(context);
    }
    if (_contains(query, ['health score', 'score', 'saude geral'])) {
      return _score(context);
    }
    if (_contains(query, ['perfil', 'cirurgia', 'bariatrica'])) {
      return _profile(context);
    }
    final insights = _service.insights(context);
    return insights.isEmpty
        ? 'Não há dados suficientes para responder com segurança. Tente perguntar sobre água, peso, refeições, vitaminas, medicamentos, consultas, exames ou sincronização. $_notice'
        : '${insights.join(' ')} $_notice';
  }

  String _water(BariaContext context) {
    final day = context.todayData;
    final current = day?.waterMl;
    final goal = day?.waterGoalMl;
    if (current == null || goal == null || goal <= 0) {
      return _missing('água e meta de hoje');
    }
    final remaining = (goal - current).clamp(0, goal);
    return remaining == 0
        ? 'Você registrou $current ml de uma meta de $goal ml hoje. A meta registrada foi atingida. $_notice'
        : 'Você registrou $current ml de uma meta de $goal ml hoje. Faltam $remaining ml. $_notice';
  }

  String _period(HealthDashboardAggregate? aggregate, String label) {
    if (aggregate == null) return _missing('histórico da $label');
    final water = aggregate.days
        .map((day) => day.waterMl)
        .whereType<int>()
        .toList();
    final meals = aggregate.days
        .map((day) => day.mealsCount)
        .whereType<int>()
        .toList();
    final scores = aggregate.days
        .where((day) => day.healthScore.hasData)
        .map((day) => day.healthScore.score)
        .toList();
    if (water.isEmpty && meals.isEmpty && scores.isEmpty) {
      return _missing('registros da $label');
    }
    final parts = <String>[];
    if (water.isNotEmpty) {
      parts.add(
        'média de água de ${water.reduce((a, b) => a + b) ~/ water.length} ml nos dias registrados',
      );
    }
    if (meals.isNotEmpty) {
      parts.add('${meals.reduce((a, b) => a + b)} refeições registradas');
    }
    if (scores.isNotEmpty) {
      parts.add(
        'Health Score médio de ${scores.reduce((a, b) => a + b) ~/ scores.length}',
      );
    }
    return 'Na sua $label: ${parts.join(', ')}. $_notice';
  }

  String _weight(BariaContext context) {
    final report = context.report;
    final current = report?.latestWeight;
    final initial = report?.profile?.initialWeight.value;
    if (current == null || initial == null) {
      return _missing('peso inicial e peso atual');
    }
    final difference = initial - current.weight.value;
    final direction = difference > 0
        ? 'redução de ${AppWeightFormatter.kg(difference)}'
        : difference < 0
        ? 'aumento de ${AppWeightFormatter.kg(difference.abs())}'
        : 'peso mantido';
    return 'Peso atual: ${current.formattedWeight}. Em relação ao peso inicial, há $direction. $_notice';
  }

  String _vitamins(BariaContext context) {
    final pending = context.todayData?.pendingVitamins;
    if (pending == null) return _missing('vitaminas de hoje');
    return pending == 0
        ? 'Não há vitamina pendente registrada hoje. $_notice'
        : 'Há $pending vitamina(s) pendente(s) hoje. $_notice';
  }

  String _medications(BariaContext context) {
    final pending = context.todayData?.pendingMedications;
    if (pending == null) return _missing('medicamentos de hoje');
    return pending == 0
        ? 'Não há medicamento pendente registrado hoje. $_notice'
        : 'Há $pending medicamento(s) pendente(s) hoje. $_notice';
  }

  String _pending(BariaContext context) {
    final count = context.pendingOfflineOperations;
    if (count == null) return _missing('estado da última sincronização');
    final last = context.lastSyncAt;
    final when = last == null
        ? 'sem horário disponível'
        : AppDateFormatter.shortWithTime(last);
    return count == 0
        ? 'A última sincronização não deixou operações com falha ($when). $_notice'
        : 'Há $count operação(ões) com falha aguardando nova tentativa. Última sincronização: $when. $_notice';
  }

  String _appointment(BariaContext context) {
    final appointment = context.today?.nextAppointment;
    if (appointment == null) return _missing('próxima consulta');
    return 'Sua próxima consulta é ${appointment.title}, em ${appointment.formattedDate}. $_notice';
  }

  String _exams(BariaContext context) {
    final exam = context.today?.latestExam;
    if (exam == null) return _missing('exames');
    return 'Seu exame mais recente registrado é ${exam.formattedName}, de ${exam.formattedDate}. $_notice';
  }

  String _meals(BariaContext context) {
    final count = context.todayData?.mealsCount;
    final protein = context.todayData?.proteinGrams;
    if (count == null) return _missing('refeições de hoje');
    return 'Hoje há $count refeição(ões) registrada(s)${protein == null ? '' : ', com $protein g de proteína informada'}. $_notice';
  }

  String _score(BariaContext context) {
    final score = context.todayData?.healthScore;
    if (score == null || !score.hasData) {
      return _missing('Health Score de hoje');
    }
    return 'Seu Health Score de acompanhamento hoje é ${score.score}/100. ${score.compositionExplanation} $_notice';
  }

  String _profile(BariaContext context) {
    final profile = context.today?.profile;
    if (profile == null) return _missing('perfil bariátrico');
    return 'Perfil de ${profile.name}: cirurgia ${profile.surgeryType.label} registrada em ${AppDateFormatter.short(profile.surgeryDate.value)}. $_notice';
  }

  String _missing(String subject) =>
      'Não há dados suficientes sobre $subject. $_notice';
  bool _contains(String value, List<String> terms) => terms.any(value.contains);
  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàãâ]'), 'a')
      .replaceAll(RegExp('[éê]'), 'e')
      .replaceAll(RegExp('[í]'), 'i')
      .replaceAll(RegExp('[óôõ]'), 'o')
      .replaceAll(RegExp('[ú]'), 'u')
      .replaceAll('ç', 'c');
}
