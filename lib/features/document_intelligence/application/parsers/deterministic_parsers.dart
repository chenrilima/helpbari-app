import '../../domain/entities/document_models.dart';
import '../../domain/repositories/document_intelligence_contracts.dart';

abstract class DeterministicFieldParser implements DocumentFieldParser {
  const DeterministicFieldParser();

  List<({String key, String label, RegExp pattern})> get rules;

  @override
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  }) {
    final now = DateTime.now().toUtc();
    final fields = <ExtractedField>[];
    for (final rule in rules) {
      final matches = rule.pattern.allMatches(text);
      for (final match in matches) {
        final value = (match.namedGroup('value') ?? '').trim();
        if (value.isEmpty) continue;
        fields.add(
          ExtractedField(
            id: '$processingId-${rule.key}-${fields.length}',
            processingId: processingId,
            key: rule.key,
            label: rule.label,
            rawValue: value,
            normalizedValue: _normalize(value),
            confidence: 0.72,
            status: FieldStatus.extracted,
            source: FieldSource.ocr,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }
    return fields;
  }

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class LabResultParser extends DeterministicFieldParser {
  const LabResultParser();
  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.labResult,
  };
  @override
  List<({String key, String label, RegExp pattern})> get rules => [
    (
      key: 'laboratory',
      label: 'Laboratório',
      pattern: RegExp(
        r'Laborat[oó]rio\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'exam_name',
      label: 'Exame',
      pattern: RegExp(
        r'(?:Exame|Material)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'date',
      label: 'Data',
      pattern: RegExp(
        r'Data\s*[:\-]\s*(?<value>\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4})',
        caseSensitive: false,
      ),
    ),
    (
      key: 'result',
      label: 'Resultado',
      pattern: RegExp(
        r'(?<value>[A-Za-zÀ-ÿ][^\n:]{2,50}\s*[:\-]\s*[<>]?\s*\d+[\d,.]*\s*[A-Za-z%/µμ]*)',
        caseSensitive: false,
      ),
    ),
  ];
}

class ConsultationNoteParser extends DeterministicFieldParser {
  const ConsultationNoteParser();
  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.consultationNote,
  };
  @override
  List<({String key, String label, RegExp pattern})> get rules => [
    (
      key: 'professional',
      label: 'Profissional',
      pattern: RegExp(
        r'(?:M[eé]dico|Profissional)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'specialty',
      label: 'Especialidade',
      pattern: RegExp(
        r'Especialidade\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'recommendations',
      label: 'Orientações',
      pattern: RegExp(
        r'Orienta(?:ç|c)[oõ]es\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
  ];
}

class MedicalReportParser extends DeterministicFieldParser {
  const MedicalReportParser();
  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.medicalReport,
  };
  @override
  List<({String key, String label, RegExp pattern})> get rules => [
    (
      key: 'title',
      label: 'Título',
      pattern: RegExp(
        r'(?:Relat[oó]rio|Laudo)\s*[:\-]?\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'summary',
      label: 'Resumo',
      pattern: RegExp(
        r'(?:Conclus[aã]o|Resumo)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
  ];
}

class PrescriptionParser extends DeterministicFieldParser {
  const PrescriptionParser();
  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.prescription,
  };
  @override
  List<({String key, String label, RegExp pattern})> get rules => [
    (
      key: 'medication',
      label: 'Medicamento',
      pattern: RegExp(
        r'(?:Medicamento|Uso oral)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'dosage',
      label: 'Dose',
      pattern: RegExp(
        r'(?:Dose|Posologia)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
    (
      key: 'frequency',
      label: 'Frequência',
      pattern: RegExp(
        r'(?:Frequ[eê]ncia|Tomar)\s*[:\-]?\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
  ];
}

class ExamRequestParser extends DeterministicFieldParser {
  const ExamRequestParser();
  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.examRequest,
  };
  @override
  List<({String key, String label, RegExp pattern})> get rules => [
    (
      key: 'requested_exams',
      label: 'Exames solicitados',
      pattern: RegExp(
        r'(?:Solicito|Exames solicitados)\s*[:\-]\s*(?<value>[^\n]+)',
        caseSensitive: false,
      ),
    ),
  ];
}
