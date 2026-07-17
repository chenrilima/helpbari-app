import '../domain/entities/document_models.dart';
import '../domain/repositories/document_intelligence_contracts.dart';

class DeterministicDocumentClassifier implements DocumentClassifier {
  const DeterministicDocumentClassifier();

  static const _signals = <DetectedDocumentType, Set<String>>{
    DetectedDocumentType.labResult: {
      'resultado',
      'laboratório',
      'laboratorio',
      'valor de referência',
      'hemograma',
      'glicose',
      'colesterol',
    },
    DetectedDocumentType.consultationNote: {
      'consulta',
      'retorno',
      'profissional',
      'especialidade',
      'orientações',
      'orientacoes',
      'evolução',
      'evolucao',
    },
    DetectedDocumentType.medicalReport: {
      'relatório',
      'relatorio',
      'laudo',
      'parecer',
      'nutricional',
    },
    DetectedDocumentType.prescription: {
      'receita',
      'prescrição',
      'prescricao',
      'posologia',
      'comprimido',
      'uso oral',
    },
    DetectedDocumentType.examRequest: {
      'solicito',
      'pedido de exame',
      'exames solicitados',
      'requisição',
      'requisicao',
    },
    DetectedDocumentType.bioimpedanceReport: {
      'bioimpedância',
      'bioimpedancia',
      'body composition',
      'inbody',
      'tanita',
      'massa muscular',
      'body fat',
      'phase angle',
      'água corporal',
      'agua corporal',
    },
  };

  @override
  DocumentCandidateResult classify(String text) {
    final normalized = _normalize(text);
    var detected = DetectedDocumentType.unknown;
    var hits = 0;
    for (final entry in _signals.entries) {
      final current = entry.value.where(normalized.contains).length;
      if (current > hits) {
        detected = entry.key;
        hits = current;
      }
    }
    if (hits == 0) {
      return const DocumentCandidateResult(
        type: DetectedDocumentType.unknown,
        confidence: 0,
        fields: [],
      );
    }
    final confidence = (0.45 + (hits * 0.15)).clamp(0, 0.95).toDouble();
    return DocumentCandidateResult(
      type: detected,
      confidence: confidence,
      fields: const [],
    );
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
