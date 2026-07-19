import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';

class MedicalPrescriptionDocumentParser implements DocumentFieldParser {
  const MedicalPrescriptionDocumentParser();

  @override
  Set<DetectedDocumentType> get supportedTypes => {
    DetectedDocumentType.prescription,
  };

  @override
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  }) {
    final normalized = text.replaceAll('\r', '');
    if (normalized.trim().isEmpty) return const [];
    final now = DateTime.now().toUtc();
    final fields = <ExtractedField>[];

    void add(
      String key,
      String label,
      String value, [
      double confidence = .72,
    ]) {
      final clean = value.trim();
      if (clean.isEmpty) return;
      fields.add(
        ExtractedField(
          id: '$processingId-$key-${fields.length}',
          processingId: processingId,
          key: key,
          label: label,
          rawValue: clean,
          normalizedValue: clean.replaceAll(RegExp(r'\s+'), ' '),
          confidence: confidence,
          status: confidence < .6
              ? FieldStatus.uncertain
              : FieldStatus.extracted,
          source: FieldSource.ocr,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    _capture(
      normalized,
      _professionalPattern,
      (value) => add('professional_name', 'Profissional', value, .76),
    );
    _capture(
      normalized,
      _specialtyPattern,
      (value) => add('professional_specialty', 'Especialidade', value, .7),
    );
    _capture(
      normalized,
      _registrationPattern,
      (value) =>
          add('professional_registration', 'Registro profissional', value, .78),
    );
    _capture(
      normalized,
      _datePattern,
      (value) => add('prescribed_at', 'Data da prescrição', value, .75),
    );
    _capture(
      normalized,
      _validityPattern,
      (value) => add('valid_until', 'Validade', value, .68),
    );

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    var itemIndex = 0;
    for (var index = 0; index < lines.length; index++) {
      final candidate = _item(lines[index]);
      if (candidate == null) continue;
      final prefix = 'item_$itemIndex';
      add('$prefix.name', 'Item ${itemIndex + 1} — nome', candidate.name, .7);
      if (candidate.dosageValue != null) {
        add('$prefix.dosage_value', 'Dose', candidate.dosageValue!, .72);
      }
      if (candidate.dosageUnit != null) {
        add('$prefix.dosage_unit', 'Unidade', candidate.dosageUnit!, .72);
      }
      final nextLineInstruction =
          index + 1 < lines.length &&
              _looksInstruction(lines[index + 1]) &&
              !RegExp(r'^\d+[.)\-]\s*').hasMatch(lines[index + 1])
          ? lines[index + 1]
          : null;
      final instruction = candidate.trailing ?? nextLineInstruction;
      if (instruction != null && instruction.isNotEmpty) {
        add('$prefix.instructions', 'Instruções', instruction, .62);
        final frequency = _frequency(instruction);
        if (frequency != null) {
          add(
            '$prefix.frequency_type',
            'Tipo de frequência',
            frequency.type,
            .68,
          );
          if (frequency.value != null) {
            add('$prefix.frequency_value', 'Frequência', frequency.value!, .68);
          }
        }
        for (final time in _times(instruction)) {
          add('$prefix.schedule_time', 'Horário', time, .82);
        }
        final duration = _duration(instruction);
        if (duration != null) {
          add('$prefix.duration_value', 'Duração', duration.value, .72);
          add(
            '$prefix.duration_unit',
            'Unidade da duração',
            duration.unit,
            .72,
          );
        }
        if (_asNeeded.hasMatch(instruction)) {
          add('$prefix.as_needed', 'Se necessário', 'true', .88);
        }
      }
      add('$prefix.item_type', 'Tipo provável', _itemType(candidate.name), .55);
      itemIndex++;
    }
    return fields;
  }

  void _capture(String text, RegExp pattern, void Function(String) add) {
    final value = pattern.firstMatch(text)?.namedGroup('value');
    if (value != null) add(value);
  }

  ({String name, String? dosageValue, String? dosageUnit, String? trailing})?
  _item(String line) {
    final numbered = RegExp(r'^\d+[.)\-]\s*').hasMatch(line);
    if (_header.hasMatch(line) || (_looksInstruction(line) && !numbered)) {
      return null;
    }
    final match = _itemPattern.firstMatch(line);
    if (match == null) return null;
    final name = match.namedGroup('name')?.trim() ?? '';
    if (name.length < 3) return null;
    return (
      name: name,
      dosageValue: match.namedGroup('dose'),
      dosageUnit: match.namedGroup('unit'),
      trailing: match.namedGroup('trailing')?.trim(),
    );
  }

  bool _looksInstruction(String value) => RegExp(
    r'\b(tomar|usar|aplicar|ingerir|a cada|vez(?:es)? ao dia|diariamente|se necess[aá]rio|uso cont[ií]nuo)\b',
    caseSensitive: false,
  ).hasMatch(value);

  ({String type, String? value})? _frequency(String value) {
    if (RegExp(r'uso cont[ií]nuo', caseSensitive: false).hasMatch(value)) {
      return (type: 'continuous', value: null);
    }
    final hours = RegExp(
      r'a cada\s+(\d+)\s*h(?:oras?)?',
      caseSensitive: false,
    ).firstMatch(value);
    if (hours != null) return (type: 'everyHours', value: hours.group(1));
    final times = RegExp(
      r'(\d+)\s*vez(?:es)?\s+ao\s+dia',
      caseSensitive: false,
    ).firstMatch(value);
    if (times != null) return (type: 'timesDaily', value: times.group(1));
    if (RegExp(
      r'1\s*vez\s+ao\s+dia|uma\s+vez\s+ao\s+dia|diariamente',
      caseSensitive: false,
    ).hasMatch(value)) {
      return (type: 'onceDaily', value: '1');
    }
    if (RegExp(
      r'\bsemanal(?:mente)?\b',
      caseSensitive: false,
    ).hasMatch(value)) {
      return (type: 'weekly', value: '1');
    }
    if (RegExp(r'\bmensal(?:mente)?\b', caseSensitive: false).hasMatch(value)) {
      return (type: 'monthly', value: '1');
    }
    return null;
  }

  List<String> _times(String value) => RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b')
      .allMatches(value)
      .map((match) => '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}')
      .toList(growable: false);

  ({String value, String unit})? _duration(String value) {
    final match = RegExp(
      r'por\s+(\d+)\s*(dia|dias|semana|semanas|m[eê]s|meses)',
      caseSensitive: false,
    ).firstMatch(value);
    return match == null
        ? null
        : (value: match.group(1)!, unit: match.group(2)!.toLowerCase());
  }

  String _itemType(String name) {
    final value = name.toLowerCase();
    if (RegExp(r'\b(vitamina|vit\.?\s*[a-k]|b12|d3)\b').hasMatch(value)) {
      return 'vitamin';
    }
    if (RegExp(
      r'\b(prote[ií]na|whey|col[aá]geno|creatina|suplemento)\b',
    ).hasMatch(value)) {
      return 'supplement';
    }
    return 'other';
  }

  static final _professionalPattern = RegExp(
    r'(?:M[eé]dico|Profissional|Dr\.?|Dra\.?)\s*[:\-]?\s*(?<value>[^\n]+)',
    caseSensitive: false,
  );
  static final _specialtyPattern = RegExp(
    r'Especialidade\s*[:\-]\s*(?<value>[^\n]+)',
    caseSensitive: false,
  );
  static final _registrationPattern = RegExp(
    r'(?:CRM|CRN|Registro)\s*[:\-]?\s*(?<value>[A-Z]{0,2}\s*\d+[A-Z0-9\-/]*)',
    caseSensitive: false,
  );
  static final _datePattern = RegExp(
    r'(?:Data|Prescrito em)\s*[:\-]\s*(?<value>\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4})',
    caseSensitive: false,
  );
  static final _validityPattern = RegExp(
    r'Validade\s*[:\-]\s*(?<value>[^\n]+)',
    caseSensitive: false,
  );
  static final _itemPattern = RegExp(
    r'^(?:\d+[.)\-]\s*|Medicamento\s*[:\-]\s*|Uso oral\s*[:\-]\s*)?(?<name>[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ0-9 +\-]{2,60}?)(?:\s+(?<dose>\d+(?:[,.]\d+)?)\s*(?<unit>mg|mcg|g|ml|UI|U|comprimidos?|c[aá]psulas?))?(?:\s*[-–]\s*(?<trailing>.+))?$',
    caseSensitive: false,
  );
  static final _header = RegExp(
    r'^(receita|prescri[cç][aã]o|paciente|profissional|m[eé]dico|especialidade|crm|crn|data|validade)\b',
    caseSensitive: false,
  );
  static final _asNeeded = RegExp(
    r'\b(se necess[aá]rio|sos|quando necess[aá]rio)\b',
    caseSensitive: false,
  );
}
