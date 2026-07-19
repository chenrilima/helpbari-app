import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/medical_prescriptions/application/medical_prescription_document_parser.dart';

void main() {
  const parser = MedicalPrescriptionDocumentParser();

  test('extracts multiple items, vitamin, interval, times and duration', () {
    final fields = parser.parse(
      processingId: 'processing-1',
      text: '''
Médico: Dra. Ana Silva
CRM: SP 12345
Data: 19/07/2026
1. Omeprazol 20 mg - Tomar a cada 8 horas às 08:00 e 16:00 por 7 dias
2. Vitamina B12 1000 mcg - Tomar uma vez ao dia
''',
    );
    String? value(String key) => fields
        .where((field) => field.key == key)
        .map((field) => field.normalizedValue)
        .firstOrNull;
    expect(value('professional_name'), contains('Ana Silva'));
    expect(value('item_0.name'), 'Omeprazol');
    expect(value('item_0.frequency_type'), 'everyHours');
    expect(
      fields.where((field) => field.key == 'item_0.schedule_time'),
      hasLength(2),
    );
    expect(value('item_0.duration_value'), '7');
    expect(value('item_1.item_type'), 'vitamin');
  });

  test(
    'extracts weekly, monthly, continuous and as-needed without inventing times',
    () {
      final fields = parser.parse(
        processingId: 'processing-2',
        text: '''
1. Produto A - usar semanalmente
2. Produto B - usar mensalmente
3. Produto C - uso contínuo se necessário
''',
      );
      expect(
        fields.where((field) => field.key.endsWith('schedule_time')),
        isEmpty,
      );
      expect(fields.any((field) => field.normalizedValue == 'weekly'), isTrue);
      expect(fields.any((field) => field.normalizedValue == 'monthly'), isTrue);
      expect(
        fields.any((field) => field.normalizedValue == 'continuous'),
        isTrue,
      );
      expect(fields.any((field) => field.key.endsWith('as_needed')), isTrue);
    },
  );

  test('empty or invalid text does not invent clinical data', () {
    expect(parser.parse(processingId: 'p', text: ''), isEmpty);
    expect(
      parser
          .parse(processingId: 'p', text: 'Prescrição\nPaciente: João')
          .where((field) => field.key.startsWith('item_')),
      isEmpty,
    );
  });
}
