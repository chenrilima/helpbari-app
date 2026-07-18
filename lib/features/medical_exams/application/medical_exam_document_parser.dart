import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';
import '../domain/entities/entities.dart';

class MedicalExamDocumentParser implements DocumentFieldParser {
  const MedicalExamDocumentParser();

  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.medicalExamReport,
    DetectedDocumentType.labResult,
  };

  @override
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  }) {
    final now = DateTime.now().toUtc();
    final sanitized = _sanitize(text);
    final fields = <ExtractedField>[
      ..._extractMetadata(processingId, sanitized, now),
      ..._extractResults(processingId, sanitized, now),
    ];
    return fields;
  }

  List<ExtractedField> _extractMetadata(
    String processingId,
    String text,
    DateTime now,
  ) {
    final fields = <ExtractedField>[];
    final metadataRules = <({String key, String label, RegExp pattern})>[
      (
        key: 'laboratory',
        label: 'Laboratório',
        pattern: RegExp(
          r'(?:laborat[oó]rio|lab)\s*[:\-]?\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'professional',
        label: 'Profissional',
        pattern: RegExp(
          r'(?:m[eé]dico|profissional|respons[aá]vel t[eé]cnico)\s*[:\-]?\s*(?<value>[^\n]+)',
          caseSensitive: false,
        ),
      ),
      (
        key: 'performedAt',
        label: 'Data do exame',
        pattern: RegExp(
          r'(?:data|coleta|emiss[aã]o|resultado)\s*[:\-]?\s*(?<value>\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4})',
          caseSensitive: false,
        ),
      ),
    ];

    for (final rule in metadataRules) {
      final match = rule.pattern.firstMatch(text);
      final value = match?.namedGroup('value')?.trim();
      if (value == null || value.isEmpty) continue;
      fields.add(
        ExtractedField(
          id: '$processingId-${rule.key}',
          processingId: processingId,
          key: rule.key,
          label: rule.label,
          rawValue: value,
          normalizedValue: value,
          confidence: 0.76,
          status: FieldStatus.extracted,
          source: FieldSource.ocr,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return fields;
  }

  List<ExtractedField> _extractResults(
    String processingId,
    String text,
    DateTime now,
  ) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final fields = <ExtractedField>[];
    final usedNames = <String>{};
    var index = 0;

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed == null) continue;
      final marker = MedicalExamMarkerCatalog.match(parsed.name);
      final normalizedName = marker?.canonicalName ?? parsed.name.trim();
      final dedupeKey =
          '${normalizedName.toLowerCase()}|${parsed.value}|${parsed.unit ?? ''}';
      if (!usedNames.add(dedupeKey)) continue;

      fields.addAll([
        _field(
          processingId: processingId,
          key: 'result_${index}_name',
          label: 'Marcador ${index + 1}',
          rawValue: parsed.name,
          normalizedValue: normalizedName,
          confidence: 0.8,
          now: now,
        ),
        _field(
          processingId: processingId,
          key: 'result_${index}_value',
          label: 'Valor ${index + 1}',
          rawValue: parsed.value,
          normalizedValue: parsed.value,
          confidence: 0.8,
          now: now,
        ),
      ]);

      if (parsed.unit != null) {
        fields.add(
          _field(
            processingId: processingId,
            key: 'result_${index}_unit',
            label: 'Unidade ${index + 1}',
            rawValue: parsed.unit!,
            normalizedValue: parsed.unit!,
            confidence: 0.74,
            now: now,
          ),
        );
      }

      if (parsed.reference != null) {
        fields.add(
          _field(
            processingId: processingId,
            key: 'result_${index}_reference',
            label: 'Referência ${index + 1}',
            rawValue: parsed.reference!,
            normalizedValue: parsed.reference!,
            confidence: 0.68,
            now: now,
          ),
        );
      }

      if (marker != null) {
        fields.addAll([
          _field(
            processingId: processingId,
            key: 'result_${index}_canonical_code',
            label: 'Código ${index + 1}',
            rawValue: marker.canonicalCode ?? '',
            normalizedValue: marker.canonicalCode,
            confidence: 0.9,
            now: now,
          ),
          _field(
            processingId: processingId,
            key: 'result_${index}_category',
            label: 'Categoria ${index + 1}',
            rawValue: marker.category.name,
            normalizedValue: marker.category.name,
            confidence: 0.9,
            now: now,
          ),
        ]);
      }

      index++;
    }

    if (index > 0) {
      fields.insert(
        0,
        _field(
          processingId: processingId,
          key: 'title',
          label: 'Título',
          rawValue: 'Exame laboratorial',
          normalizedValue: 'Exame laboratorial',
          confidence: 0.6,
          now: now,
        ),
      );
    }

    return fields;
  }

  ({String name, String value, String? unit, String? reference})? _parseLine(
    String line,
  ) {
    final match = RegExp(
      r'^(?<name>[A-Za-zÀ-ÿ0-9()\/\-\s]{3,60}?)\s+(?<value>[<>]?\s*-?\d+(?:[.,]\d+)?)\s*(?<unit>[A-Za-z%µμ/²0-9\.]+)?(?:\s+(?<reference>(?:\d+(?:[.,]\d+)?\s*[-a]\s*\d+(?:[.,]\d+)?|<[^\s]+|>[^\s]+|at[eé][^\n]+|valor[^\n]+)))?$',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(line);
    final name = match?.namedGroup('name')?.trim();
    final value = match?.namedGroup('value')?.trim();
    if (name == null || value == null) return null;
    if (name.length < 3) return null;
    if (!_looksLikeMarker(name)) return null;
    return (
      name: name,
      value: value.replaceAll(' ', ''),
      unit: match?.namedGroup('unit')?.trim(),
      reference: match?.namedGroup('reference')?.trim(),
    );
  }

  bool _looksLikeMarker(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('resultado') ||
        normalized.contains('refer') ||
        normalized.contains('material') ||
        normalized.contains('método') ||
        normalized.contains('metodo')) {
      return false;
    }
    return MedicalExamMarkerCatalog.match(value) != null ||
        RegExp(
          r'(hemog|hemat|ferrit|vitamina|folat|c[aá]lcio|album|glic|insul|tsh|creat|ure|ast|alt|gama|colesterol|hdl|ldl|trig|zinco|magn|pth)',
          caseSensitive: false,
        ).hasMatch(value);
  }

  ExtractedField _field({
    required String processingId,
    required String key,
    required String label,
    required String rawValue,
    required String? normalizedValue,
    required double confidence,
    required DateTime now,
  }) => ExtractedField(
    id: '$processingId-$key',
    processingId: processingId,
    key: key,
    label: label,
    rawValue: rawValue,
    normalizedValue: normalizedValue,
    confidence: confidence,
    status: FieldStatus.extracted,
    source: FieldSource.ocr,
    createdAt: now,
    updatedAt: now,
  );

  String _sanitize(String text) => text
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[\u00A0\t]+'), ' ')
      .replaceAll(RegExp(r'[ ]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
}
