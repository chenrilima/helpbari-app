class ReportTemplate {
  const ReportTemplate({
    required this.id,
    required this.name,
    required this.sections,
    this.includeCharts = true,
  });

  factory ReportTemplate.complete() {
    return const ReportTemplate(
      id: 'complete-medical-report',
      name: 'Relatório médico completo',
      sections: [
        ReportSection.patient,
        ReportSection.weight,
        ReportSection.water,
        ReportSection.vitamins,
        ReportSection.medications,
        ReportSection.meals,
        ReportSection.appointments,
        ReportSection.exams,
        ReportSection.healthScore,
        ReportSection.progress,
        ReportSection.charts,
      ],
    );
  }

  final String id;
  final String name;
  final List<ReportSection> sections;
  final bool includeCharts;

  bool includes(ReportSection section) {
    return sections.contains(section);
  }
}

enum ReportSection {
  patient,
  weight,
  water,
  vitamins,
  medications,
  meals,
  appointments,
  exams,
  healthScore,
  progress,
  charts,
}
