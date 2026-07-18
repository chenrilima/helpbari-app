import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';

class MedicalConsultationDocumentParser implements DocumentFieldParser {
  const MedicalConsultationDocumentParser();

  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.medicalConsultation,
    DetectedDocumentType.consultationNote,
  };

  @override
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  }) {
    final now = DateTime.now().toUtc();
    final fields = <ExtractedField>[];
    final rules = <({String key, String label, RegExp pattern})>[
      (
        key: 'professionalName',
        label: 'Profissional',
        pattern: RegExp(
          r'(?:M[eé]dico|Profissional|Nutricionista|Psic[oó]logo|Endocrinologista)\s*[:\-]?\s*(?<value>[^\n]+)',
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
        key: 'clinicName',
        label: 'Clínica',
        pattern: RegExp(
          r'(?:Cl[ií]nica|Hospital|Local)\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'consultationAt',
        label: 'Data da consulta',
        pattern: RegExp(
          r'(?:Data|Consulta em)\s*[:\-]?\s*(?<value>\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4})',
          caseSensitive: false,
        ),
      ),
      (
        key: 'reason',
        label: 'Motivo',
        pattern: RegExp(
          r'(?:Motivo|Queixa principal)\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'symptoms',
        label: 'Sintomas',
        pattern: RegExp(
          r'Sintomas?\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'professionalGuidance',
        label: 'Orientações',
        pattern: RegExp(
          r'Orienta(?:ç|c)[oõ]es\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'requestedExamsNotes',
        label: 'Exames solicitados',
        pattern: RegExp(
          r'(?:Exames solicitados|Solicito)\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'followUpNotes',
        label: 'Próximos passos',
        pattern: RegExp(
          r'(?:Retorno|Pr[oó]ximos passos|Acompanhamento)\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'generalNotes',
        label: 'Observações gerais',
        pattern: RegExp(
          r'(?:Resumo|Evolu(?:ç|c)[aã]o|Observa(?:ç|c)[oõ]es)\s*[:\-]\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
    ];
    for (final rule in rules) {
      for (final match in rule.pattern.allMatches(text)) {
        final value = (match.namedGroup('value') ?? '').trim();
        if (value.isEmpty) continue;
        fields.add(
          ExtractedField(
            id: '$processingId-${rule.key}-${fields.length}',
            processingId: processingId,
            key: rule.key,
            label: rule.label,
            rawValue: value,
            normalizedValue: value.replaceAll(RegExp(r'\s+'), ' ').trim(),
            confidence: 0.74,
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
}
