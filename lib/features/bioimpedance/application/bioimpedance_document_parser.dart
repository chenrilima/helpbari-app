import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';

class BioimpedanceDocumentParser implements DocumentFieldParser {
  const BioimpedanceDocumentParser();

  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.bioimpedanceReport,
  };

  static const aliases = <String, List<String>>{
    'weightKg': ['peso', 'weight'],
    'muscleMassKg': ['massa muscular', 'muscle mass'],
    'skeletalMuscleMassKg': [
      'massa muscular esquelética',
      'massa muscular esqueletica',
      'skeletal muscle mass',
      'smm',
    ],
    'bodyFatMassKg': ['massa de gordura', 'body fat mass'],
    'bodyFatPercentage': [
      'percentual de gordura',
      'porcentagem de gordura',
      'body fat percentage',
      'pbf',
    ],
    'bodyWaterPercentage': [
      'água corporal',
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
    for (final entry in aliases.entries) {
      for (final alias in entry.value) {
        final pattern = RegExp(
          '${RegExp.escape(alias)}\\s*[:\\-]?\\s*(?<value>[+-]?\\d+[\\d.,]*)\\s*(?<unit>kg|g|%|kcal|cm²|cm2|cm|l|litros|graus|°)?',
          caseSensitive: false,
          unicode: true,
        );
        final match = pattern.firstMatch(normalizedText);
        if (match == null) continue;
        final raw = match.namedGroup('value') ?? '';
        final unit = match.namedGroup('unit');
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
    final measuredAt = _extractDate(processingId, normalizedText, now);
    if (measuredAt != null) fields.add(measuredAt);
    return fields;
  }

  String? _normalize(String key, String raw, String? unit) {
    final value = double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    if (value == null || !value.isFinite) return raw;
    final normalizedUnit = unit?.toLowerCase();
    final kgKeys = key.endsWith('Kg') || key.contains('Mass');
    if (kgKeys && normalizedUnit == 'g') {
      return (value / 1000).toStringAsFixed(2);
    }
    return value.toString();
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
      r'(?:data|date)\s*[:\-]\s*(?<value>\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4})',
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
