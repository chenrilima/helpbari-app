import 'medical_exam_entities.dart';

class MedicalExamMarkerDefinition {
  const MedicalExamMarkerDefinition({
    required this.canonicalName,
    required this.aliases,
    required this.category,
    this.canonicalCode,
    this.commonUnits = const <String>[],
    this.supportsChart = true,
  });

  final String? canonicalCode;
  final String canonicalName;
  final List<String> aliases;
  final MedicalExamCategory category;
  final List<String> commonUnits;
  final bool supportsChart;
}

class MedicalExamMarkerCatalog {
  const MedicalExamMarkerCatalog._();

  static const markers = <MedicalExamMarkerDefinition>[
    MedicalExamMarkerDefinition(
      canonicalCode: 'hemoglobin',
      canonicalName: 'Hemoglobina',
      aliases: ['hemoglobina', 'hemoglobin', 'hb', 'hgb'],
      category: MedicalExamCategory.bloodCount,
      commonUnits: ['g/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'hematocrit',
      canonicalName: 'Hematócrito',
      aliases: ['hematócrito', 'hematocrito', 'hematocrit', 'ht', 'hct'],
      category: MedicalExamCategory.bloodCount,
      commonUnits: ['%'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'ferritin',
      canonicalName: 'Ferritina',
      aliases: ['ferritina', 'ferritin'],
      category: MedicalExamCategory.minerals,
      commonUnits: ['ng/mL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'serumIron',
      canonicalName: 'Ferro sérico',
      aliases: ['ferro', 'ferro sérico', 'ferro serico', 'serum iron'],
      category: MedicalExamCategory.minerals,
      commonUnits: ['µg/dL', 'ug/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'vitaminB12',
      canonicalName: 'Vitamina B12',
      aliases: ['vitamina b12', 'vitamin b12', 'cobalamina', 'cobalamin'],
      category: MedicalExamCategory.vitamins,
      commonUnits: ['pg/mL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'vitaminD',
      canonicalName: 'Vitamina D',
      aliases: [
        'vitamina d',
        '25-oh vitamina d',
        '25-hydroxyvitamin d',
        'calcidiol',
      ],
      category: MedicalExamCategory.vitamins,
      commonUnits: ['ng/mL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'folate',
      canonicalName: 'Ácido fólico',
      aliases: ['ácido fólico', 'acido folico', 'folato', 'folate'],
      category: MedicalExamCategory.vitamins,
      commonUnits: ['ng/mL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'calcium',
      canonicalName: 'Cálcio',
      aliases: ['cálcio', 'calcio', 'calcium'],
      category: MedicalExamCategory.minerals,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'albumin',
      canonicalName: 'Albumina',
      aliases: ['albumina', 'albumin'],
      category: MedicalExamCategory.liver,
      commonUnits: ['g/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'totalProtein',
      canonicalName: 'Proteínas totais',
      aliases: ['proteínas totais', 'proteinas totais', 'total protein'],
      category: MedicalExamCategory.liver,
      commonUnits: ['g/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'glucose',
      canonicalName: 'Glicose',
      aliases: ['glicose', 'glucose', 'fasting glucose', 'glicemia'],
      category: MedicalExamCategory.glucose,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'glycatedHemoglobin',
      canonicalName: 'Hemoglobina glicada',
      aliases: ['hemoglobina glicada', 'glycated hemoglobin', 'hba1c', 'a1c'],
      category: MedicalExamCategory.glucose,
      commonUnits: ['%'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'insulin',
      canonicalName: 'Insulina',
      aliases: ['insulina', 'insulin'],
      category: MedicalExamCategory.hormones,
      commonUnits: ['µUI/mL', 'uUI/mL', 'mUI/L'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'tsh',
      canonicalName: 'TSH',
      aliases: ['tsh', 'thyroid stimulating hormone'],
      category: MedicalExamCategory.thyroid,
      commonUnits: ['µUI/mL', 'uUI/mL', 'mUI/L'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'freeT4',
      canonicalName: 'T4 livre',
      aliases: ['t4 livre', 'free t4', 'ft4'],
      category: MedicalExamCategory.thyroid,
      commonUnits: ['ng/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'creatinine',
      canonicalName: 'Creatinina',
      aliases: ['creatinina', 'creatinine'],
      category: MedicalExamCategory.kidney,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'urea',
      canonicalName: 'Ureia',
      aliases: ['ureia', 'urea'],
      category: MedicalExamCategory.kidney,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'ast',
      canonicalName: 'AST',
      aliases: ['ast', 'tgo'],
      category: MedicalExamCategory.liver,
      commonUnits: ['U/L'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'alt',
      canonicalName: 'ALT',
      aliases: ['alt', 'tgp'],
      category: MedicalExamCategory.liver,
      commonUnits: ['U/L'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'gammaGT',
      canonicalName: 'Gama GT',
      aliases: ['gama gt', 'gamma gt', 'ggt'],
      category: MedicalExamCategory.liver,
      commonUnits: ['U/L'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'totalCholesterol',
      canonicalName: 'Colesterol total',
      aliases: ['colesterol total', 'total cholesterol'],
      category: MedicalExamCategory.lipids,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'hdl',
      canonicalName: 'HDL',
      aliases: ['hdl', 'hdl cholesterol'],
      category: MedicalExamCategory.lipids,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'ldl',
      canonicalName: 'LDL',
      aliases: ['ldl', 'ldl cholesterol'],
      category: MedicalExamCategory.lipids,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'triglycerides',
      canonicalName: 'Triglicerídeos',
      aliases: ['triglicerídeos', 'triglicerideos', 'triglycerides'],
      category: MedicalExamCategory.lipids,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'zinc',
      canonicalName: 'Zinco',
      aliases: ['zinco', 'zinc'],
      category: MedicalExamCategory.minerals,
      commonUnits: ['µg/dL', 'ug/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'magnesium',
      canonicalName: 'Magnésio',
      aliases: ['magnésio', 'magnesio', 'magnesium'],
      category: MedicalExamCategory.minerals,
      commonUnits: ['mg/dL'],
    ),
    MedicalExamMarkerDefinition(
      canonicalCode: 'parathyroidHormone',
      canonicalName: 'Paratormônio',
      aliases: ['paratormônio', 'paratormonio', 'pth', 'parathyroid hormone'],
      category: MedicalExamCategory.hormones,
      commonUnits: ['pg/mL'],
    ),
  ];

  static MedicalExamMarkerDefinition? match(String rawName) {
    final normalized = _normalize(rawName);
    for (final marker in markers) {
      if (_normalize(marker.canonicalName) == normalized) return marker;
      if (marker.aliases.any((alias) => _normalize(alias) == normalized)) {
        return marker;
      }
    }
    return null;
  }

  static String normalizeName(String rawName) =>
      match(rawName)?.canonicalName ?? rawName.trim();

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
