import '../../../water/domain/usecases/use_cases.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../medications/domain/usecases/medication_use_cases.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/baria_repository.dart';

class FakeBariaRepository implements BariaRepository {
  FakeBariaRepository({
    required this.waterUseCases,
    required this.vitaminUseCases,
    required this.medicationUseCases,
    required this.healthScore,
  });

  final WaterUseCases waterUseCases;
  final VitaminUseCases vitaminUseCases;
  final MedicationUseCases medicationUseCases;
  final double healthScore;

  final List<BariaMessage> _conversationHistory = [];

  @override
  Future<BariaInsight> getDailyInsight() async {
    final waterToday = await waterUseCases.getTodayTotalInMl();
    const waterGoal = 2000; // Default goal, can be customized
    final pendingVitamins = await vitaminUseCases.getPendingCount();
    final pendingMedications =
        (await medicationUseCases.getSummary()).pendingCount;

    final hydrationPercent = (waterToday / waterGoal * 100).toInt();
    final isWellHydrated = hydrationPercent >= 80;
    final isPendingTasks = pendingVitamins > 0 || pendingMedications > 0;

    String title;
    String message;
    double? improvement;

    if (healthScore >= 90) {
      title = 'Dia excelente! 🌟';
      message =
          'Você está seguindo sua rotina de forma consistente e '
          'cuidando bem da sua saúde. Continue assim!';
      improvement = 5.0;
    } else if (healthScore >= 75) {
      title = 'Bom progresso! 💪';
      message =
          'Você está no caminho certo. '
          '${isWellHydrated ? 'Sua hidratação está ótima!' : 'Tente beber mais água hoje.'}';
      improvement = 3.0;
    } else if (healthScore >= 60) {
      title = 'Pode melhorar 📈';
      if (isPendingTasks) {
        message =
            'Você tem $pendingVitamins vitamina(s) '
            'e $pendingMedications medicamento(s) pendente(s). Não se esqueça de tomar!';
      } else {
        message =
            'Tente completar mais tarefas hoje para melhorar seu Health Score.';
      }
      improvement = 2.0;
    } else {
      title = 'Atenção necessária ⚠️';
      message =
          'Seu Health Score está baixo. Comece pequeno: hidrate-se bem, '
          'tome seus medicamentos e vitaminas!';
      improvement = 1.0;
    }

    return BariaInsight(
      id: DateTime.now().toIso8601String(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
      healthScoreImprovement: improvement,
    );
  }

  @override
  Future<List<BariaMessage>> getConversationHistory() async {
    return _conversationHistory;
  }

  @override
  Future<void> saveMessage(BariaMessage message) async {
    _conversationHistory.add(message);
  }

  @override
  Future<String> generateResponse(String userMessage) async {
    final waterToday = await waterUseCases.getTodayTotalInMl();
    final waterGoal = 2000; // Default goal
    final pendingVitamins = await vitaminUseCases.getPendingCount();
    final pendingMedications =
        (await medicationUseCases.getSummary()).pendingCount;

    final messageLower = userMessage.toLowerCase();
    final hydrationPercent = (waterToday / waterGoal * 100).toInt();

    if (messageLower.contains('hidratação') || messageLower.contains('água')) {
      final remaining = (waterGoal - waterToday).clamp(0, 10000);
      return 'Sua hidratação hoje: $waterToday ml de $waterGoal ml '
          '($hydrationPercent% da meta). '
          '${remaining > 0 ? 'Faltam $remaining ml para atingir sua meta. Beba mais água!' : 'Parabéns! Você atingiu sua meta de hidratação! 🎉'}';
    }

    if (messageLower.contains('health score') ||
        messageLower.contains('saúde geral')) {
      return 'Seu Health Score hoje é ${healthScore.toStringAsFixed(1)}. '
          'Ele leva em conta sua hidratação, medicamentos, vitaminas, refeições e muito mais. '
          'Quanto mais tarefas você completa, melhor fica seu score!';
    }

    if (messageLower.contains('pendente') ||
        messageLower.contains('faltou') ||
        messageLower.contains('ficou pendente')) {
      final tasks = <String>[];
      if (pendingVitamins > 0) {
        tasks.add('$pendingVitamins vitamina(s)');
      }
      if (pendingMedications > 0) {
        tasks.add('$pendingMedications medicamento(s)');
      }
      if (tasks.isEmpty) {
        return 'Ótimo! Você completou todas as suas tarefas de hoje! ✨';
      }
      return 'Você ainda precisa tomar: ${tasks.join(' e ')}. '
          'Não se esqueça de registrar quando tomar!';
    }

    if (messageLower.contains('resumo') || messageLower.contains('jornada')) {
      final tasks = <String>[];
      tasks.add('Água: $waterToday/$waterGoal ml ($hydrationPercent%)');
      if (pendingVitamins == 0) {
        tasks.add('✓ Todas as vitaminas tomadas');
      } else {
        tasks.add('✗ $pendingVitamins vitamina(s) pendente(s)');
      }
      if (pendingMedications == 0) {
        tasks.add('✓ Todos os medicamentos tomados');
      } else {
        tasks.add('✗ $pendingMedications medicamento(s) pendente(s)');
      }
      tasks.add('Health Score: ${healthScore.toStringAsFixed(1)}');

      return 'Resumo da sua jornada hoje:\n\n${tasks.join('\n')}\n\n'
          'Continue acompanhando sua saúde! 💜';
    }

    if (messageLower.contains('consulta') ||
        messageLower.contains('preparar') ||
        messageLower.contains('médico')) {
      return 'Para suas próximas consultas, você pode levar:\n\n'
          '• Seu Health Score: ${healthScore.toStringAsFixed(1)}\n'
          '• Histórico de hidratação\n'
          '• Adesão a medicamentos\n'
          '• Registros de refeições\n\n'
          'Isso ajudará seu médico a entender melhor sua rotina!';
    }

    // Default response
    return 'Ótimo! Você pode me fazer perguntas sobre sua hidratação, medicamentos, '
        'vitaminas e seu progresso geral. Como posso ajudar você agora?';
  }
}
