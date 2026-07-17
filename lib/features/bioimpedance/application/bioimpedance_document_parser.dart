import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';

class BioimpedanceDocumentParser implements DocumentFieldParser {
  const BioimpedanceDocumentParser();

  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.bioimpedanceReport,
  };

  static const aliases = <String, List<String>>{
    'weightKg': ['peso', 'peso corporal', 'weight', 'body weight'],
    'muscleMassKg': [
      'massa muscular',
      'massa muscular total',
      'muscle mass',
    ],
    'skeletalMuscleMassKg': [
      'massa muscular esquelética',
      'massa muscular esqueletica',
      'skeletal muscle mass',
      'smm',
    ],
    'bodyFatMassKg': [
      'massa de gordura',
      'massa de gordura corporal',
      'body fat mass',
    ],
    'bodyFatPercentage': [
      'percentual de gordura',
      'percentual de gordura corporal',
      'porcentagem de gordura',
      'taxa de gordura',
      'body fat percentage',
      'pbf',
    ],
    'bodyWaterPercentage': [
      'água corporal',
      'água corporal total',
      'agua corporal',
      'body water',
      'total body water',
      'tbw',
    ],
    'bmi': ['imc', 'bmi'],
    'visceralFatLevel': ['gordura visceral', 'visceral fat'],
    'basalMetabolicRateKcal': [
      'taxa metabólica basal',
      'taxa metabolica basal',
      'basal metabolic rate',
      'bmr',
    ],
    'metabolicAge': ['idade metabólica', 'idade metabolica', 'metabolic age'],
    'waistHipRatio': [
      'relação cintura-quadril',
      'relacao cintura-quadril',
      'waist-hip ratio',
      'whr',
    ],
    'fatFreeMassKg': ['massa livre de gordura', 'fat-free mass'],
    'leanBodyMassKg': ['massa magra', 'lean body mass'],
    'phaseAngleDegrees': ['ângulo de fase', 'angulo de fase', 'phase angle'],
    'proteinPercentage': ['proteína', 'proteina', 'protein'],
    'mineralMassKg': ['minerais', 'minerals'],
    'weightControlKg': ['controle de peso', 'weight control'],
    'fatControlKg': ['controle de gordura', 'fat control'],
    'muscleControlKg': ['controle muscular', 'muscle control'],
  };

  static const labels = <String, String>{
    'weightKg': 'Peso',
    'muscleMassKg': 'Massa muscular',
    'skeletalMuscleMassKg': 'Massa muscular esquelética',
    'bodyFatMassKg': 'Massa de gordura',
    'bodyFatPercentage': 'Percentual de gordura',
    'bodyWaterPercentage': 'Água corporal',
    'bmi': 'IMC',
    'visceralFatLevel': 'Gordura visceral',
    'basalMetabolicRateKcal': 'Taxa metabólica basal',
    'metabolicAge': 'Idade metabólica',
    'waistHipRatio': 'Relação cintura-quadril',
    'fatFreeMassKg': 'Massa livre de gordura',
    'leanBodyMassKg': 'Massa magra',
    'phaseAngleDegrees': 'Ângulo de fase',
    'proteinPercentage': 'Proteína',
    'mineralMassKg': 'Minerais',
    'weightControlKg': 'Controle de peso',
    'fatControlKg': 'Controle de gordura',
    'muscleControlKg': 'Controle muscular',
  };

  @override
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  }) {
    final now = DateTime.now().toUtc();
    final fields = <ExtractedField>[];
    final normalizedText = text.replaceAll('\r', '\n');
    final sanitizedText = _sanitize(normalizedText);
    for (final entry in aliases.entries) {
      for (final alias in entry.value) {
        final extracted = _extractValueNearAlias(
          text: sanitizedText,
          alias: alias,
        );
        if (extracted == null) continue;
        final raw = extracted.value;
        final unit = extracted.unit;
        final normalized = _normalize(entry.key, raw, unit);
        fields.add(
          ExtractedField(
            id: '$processingId-${entry.key}',
            processingId: processingId,
            key: entry.key,
            label: labels[entry.key] ?? entry.key,
            rawValue: unit == null ? raw : '$raw $unit',
            normalizedValue: normalized,
            unit: _normalizedUnit(entry.key, unit),
            confidence: 0.74,
            status: FieldStatus.extracted,
            source: FieldSource.ocr,
            createdAt: now,
            updatedAt: now,
          ),
        );
        break;
      }
    }
    final measuredAt = _extractDate(processingId, sanitizedText, now);
    if (measuredAt != null) fields.add(measuredAt);
    return fields;
  }

  String _sanitize(String text) => text
      .replaceAll(RegExp(r'[\u00A0\t]+'), ' ')
      .replaceAll(RegExp(r'[ ]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');

  ({String value, String? unit})? _extractValueNearAlias({
    required String text,
    required String alias,
  }) {
    final aliasPattern = RegExp(
      '(?<!\\w)${RegExp.escape(alias)}(?!\\w)',
      caseSensitive: false,
      unicode: true,
    );
    final valuePattern = RegExp(
      r'(?<value>[+-]?\d+(?:[.,]\d{1,3})?)\s*(?<unit>kg|g|%|kcal|cm²|cm2|cm|l|litros|graus|°)?',
      caseSensitive: false,
      unicode: true,
    );
    for (final match in aliasPattern.allMatches(text)) {
      final start = match.end;
      final end = (start + 48).clamp(0, text.length);
      final window = text.substring(start, end);
      final valueMatch = valuePattern.firstMatch(window);
      if (valueMatch == null) continue;
      final value = valueMatch.namedGroup('value');
      if (value == null || value.isEmpty) continue;
      return (value: value, unit: valueMatch.namedGroup('unit')?.toLowerCase());
    }
    return null;
  }

  String? _normalize(String key, String raw, String? unit) {
    final value = _parseNumber(raw);
    if (value == null || !value.isFinite) return raw;
    final normalizedUnit = unit?.toLowerCase();
    final kgKeys = key.endsWith('Kg') || key.contains('Mass');
    if (kgKeys && normalizedUnit == 'g') {
      return (value / 1000).toStringAsFixed(2);
    }
    return value.toString();
  }

  double? _parseNumber(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    if (hasComma && hasDot) {
      return double.tryParse(cleaned.replaceAll('.', '').replaceAll(',', '.'));
    }
    if (hasComma) {
      return double.tryParse(cleaned.replaceAll(',', '.'));
    }
    return double.tryParse(cleaned);
  }

  String? _normalizedUnit(String key, String? unit) {
    if (key.endsWith('Percentage')) return '%';
    if (key.endsWith('Kg') || key.contains('Mass')) return 'kg';
    if (key.endsWith('Kcal')) return 'kcal';
    if (key.endsWith('Cm2')) return 'cm2';
    if (key.endsWith('Cm')) return 'cm';
    if (key.endsWith('Liters')) return 'L';
    if (key.endsWith('Degrees')) return 'graus';
    return unit;
  }

  ExtractedField? _extractDate(String processingId, String text, DateTime now) {
    final match = RegExp(
      r'(?:data|date)\s*[:\-]?\s*(?<value>\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.namedGroup('value');
    if (value == null) return null;
    return ExtractedField(
      id: '$processingId-measuredAt',
      processingId: processingId,
      key: 'measuredAt',
      label: 'Data da avaliação',
      rawValue: value,
      normalizedValue: value,
      confidence: 0.76,
      status: FieldStatus.extracted,
      source: FieldSource.ocr,
      createdAt: now,
      updatedAt: now,
    );
  }
}
