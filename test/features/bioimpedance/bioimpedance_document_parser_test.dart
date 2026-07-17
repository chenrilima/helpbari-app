import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/bioimpedance/application/bioimpedance_document_parser.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';

void main() {
  const parser = BioimpedanceDocumentParser();

  test(
    'extracts core bioimpedance fields with aliases and normalized units',
    () {
      final fields = parser.parse(
        processingId: 'processing-1',
        text: '''
Laudo de Bioimpedância
Data: 17/07/2026
Peso: 82,4 kg
Massa muscular: 31,2 kg
Água corporal: 49,8 %
IMC: 28,1
''',
      );

      expect(
        parser.supportedTypes,
        contains(DetectedDocumentType.bioimpedanceReport),
      );
      expect(_value(fields, 'weightKg'), '82.4');
      expect(_unit(fields, 'weightKg'), 'kg');
      expect(_value(fields, 'muscleMassKg'), '31.2');
      expect(_value(fields, 'bodyWaterPercentage'), '49.8');
      expect(_unit(fields, 'bodyWaterPercentage'), '%');
      expect(_value(fields, 'bmi'), '28.1');
      expect(_value(fields, 'measuredAt'), '17/07/2026');
    },
  );

  test('converts gram-based mass values to kilograms', () {
    final fields = parser.parse(
      processingId: 'processing-2',
      text: 'Body fat mass: 18300 g',
    );

    expect(_value(fields, 'bodyFatMassKg'), '18.30');
    expect(_unit(fields, 'bodyFatMassKg'), 'kg');
  });
}

String? _value(List<ExtractedField> fields, String key) {
  final field = fields.where((item) => item.key == key).single;
  return field.normalizedValue;
}

String? _unit(List<ExtractedField> fields, String key) {
  final field = fields.where((item) => item.key == key).single;
  return field.unit;
}
