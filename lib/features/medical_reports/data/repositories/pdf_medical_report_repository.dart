import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/formatters/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

class PdfMedicalReportRepository implements MedicalReportRepository {
  const PdfMedicalReportRepository();

  static const _primary = PdfColor.fromInt(0xFF6D5DF6);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _surface = PdfColor.fromInt(0xFFF8FAFC);
  static const _ink = PdfColor.fromInt(0xFF0F172A);

  @override
  Future<GeneratedMedicalReport> generate({
    required MedicalReportSnapshot snapshot,
    required ReportTemplate template,
  }) async {
    final document = pw.Document(
      title: template.name,
      author: 'HelpBari',
      creator: 'HelpBari',
      subject: 'Relatório médico',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(snapshot, context.pageNumber),
        footer: (context) => _footer(context.pageNumber, context.pagesCount),
        build: (context) => [
          _cover(snapshot),
          if (template.includes(ReportSection.patient)) ...[
            _sectionTitle('Dados do paciente'),
            _patient(snapshot),
          ],
          if (template.includes(ReportSection.healthScore)) ...[
            _sectionTitle('Health Score'),
            _healthScore(snapshot),
          ],
          if (template.includeCharts &&
              template.includes(ReportSection.charts)) ...[
            _sectionTitle('Gráficos'),
            _charts(snapshot),
          ],
          if (template.includes(ReportSection.weight)) ...[
            _sectionTitle('Peso'),
            _weight(snapshot),
          ],
          if (template.includes(ReportSection.water)) ...[
            _sectionTitle('Água'),
            _water(snapshot),
          ],
          if (template.includes(ReportSection.vitamins)) ...[
            _sectionTitle('Vitaminas'),
            _vitamins(snapshot),
          ],
          if (template.includes(ReportSection.medications)) ...[
            _sectionTitle('Medicamentos'),
            _medications(snapshot),
          ],
          if (template.includes(ReportSection.meals)) ...[
            _sectionTitle('Alimentação'),
            _meals(snapshot),
          ],
          if (template.includes(ReportSection.appointments)) ...[
            _sectionTitle('Consultas'),
            _appointments(snapshot),
          ],
          if (template.includes(ReportSection.exams)) ...[
            _sectionTitle('Exames'),
            _exams(snapshot),
          ],
          if (template.includes(ReportSection.progress)) ...[
            _sectionTitle('Evolução'),
            _progress(snapshot),
          ],
          _attachments(snapshot),
        ],
      ),
    );

    final bytes = await document.save();

    return GeneratedMedicalReport(
      bytes: Uint8List.fromList(bytes),
      fileName: _fileName(snapshot),
      generatedAt: snapshot.generatedAt,
      template: template,
    );
  }

  pw.Widget _header(MedicalReportSnapshot snapshot, int pageNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'HelpBari',
            style: pw.TextStyle(
              color: _primary,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.Text(
            snapshot.profile?.name ?? 'Relatório médico',
            style: const pw.TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(int pageNumber, int pageCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border)),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página $pageNumber de $pageCount',
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
      ),
    );
  }

  pw.Widget _cover(MedicalReportSnapshot snapshot) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            snapshot.template.name,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Gerado em ${AppDateFormatter.shortWithTime(snapshot.generatedAt)}',
            style: const pw.TextStyle(color: _muted, fontSize: 11),
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Health Score ${snapshot.dailySummary.healthScore.score}'),
              _pill('${snapshot.weightHistory.length} registros de peso'),
              _pill('${snapshot.exams.length} exames'),
              _pill('${snapshot.appointments.length} consultas'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _patient(MedicalReportSnapshot snapshot) {
    final profile = snapshot.profile;

    if (profile == null) {
      return _empty('Perfil ainda não preenchido.');
    }

    return _keyValueGrid([
      ('Nome', profile.name),
      ('E-mail', profile.email),
      ('Idade', '${profile.age} anos'),
      ('Altura', profile.height.formatted),
      ('Peso inicial', AppWeightFormatter.kg(profile.initialWeight.value)),
      ('Meta de peso', _optionalWeight(profile.targetWeight?.value)),
      ('Cirurgia', profile.surgeryType.label),
      ('Data da cirurgia', AppDateFormatter.short(profile.surgeryDate.value)),
    ]);
  }

  pw.Widget _healthScore(MedicalReportSnapshot snapshot) {
    final score = snapshot.dailySummary.healthScore;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _scoreCard(score.score),
        pw.SizedBox(height: 12),
        _metricBars([
          ('Água', score.hydrationScore),
          ('Proteína', score.proteinScore),
          ('Vitaminas', score.vitaminsScore),
          ('Medicamentos', score.medicationsScore),
          ('Refeições', score.mealsScore),
          ('Peso', score.weightProgressScore),
        ]),
      ],
    );
  }

  pw.Widget _charts(MedicalReportSnapshot snapshot) {
    return pw.Column(
      children: [
        _chartCard(title: 'Evolução de peso', child: _weightChart(snapshot)),
        pw.SizedBox(height: 12),
        _chartCard(
          title: 'Progresso diário',
          child: _metricBars([
            ('Água', snapshot.dailySummary.hydration.progress),
            ('Proteína', snapshot.dailySummary.protein.progress),
            (
              'Health Score',
              snapshot.dailySummary.healthScore.score.clamp(0, 100) / 100,
            ),
          ]),
        ),
      ],
    );
  }

  pw.Widget _weight(MedicalReportSnapshot snapshot) {
    final latest = snapshot.latestWeight;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _keyValueGrid([
          ('Peso atual', latest?.formattedWeight ?? 'Sem registro'),
          (
            'Peso inicial',
            _optionalWeight(snapshot.profile?.initialWeight.value),
          ),
          ('Meta', _optionalWeight(snapshot.profile?.targetWeight?.value)),
          ('Registros', snapshot.weightHistory.length.toString()),
        ]),
        pw.SizedBox(height: 12),
        _table(
          headers: ['Data', 'Peso', 'Observações'],
          rows: snapshot.weightHistory
              .take(12)
              .map(
                (record) => [
                  AppDateFormatter.short(record.recordedAt.value),
                  record.formattedWeight,
                  record.notes?.value ?? '-',
                ],
              )
              .toList(),
          emptyText: 'Nenhum peso registrado.',
        ),
      ],
    );
  }

  pw.Widget _water(MedicalReportSnapshot snapshot) {
    return _keyValueGrid([
      ('Hoje', AppWaterFormatter.ml(snapshot.totalWaterTodayInMl)),
      ('Meta', AppWaterFormatter.ml(snapshot.dailySummary.waterGoalMl)),
      (
        'Restante',
        AppWaterFormatter.ml(snapshot.dailySummary.hydration.remainingMl),
      ),
      ('Registros', snapshot.waterHistory.length.toString()),
    ]);
  }

  pw.Widget _vitamins(MedicalReportSnapshot snapshot) {
    return _table(
      headers: ['Vitamina', 'Horário', 'Status'],
      rows: snapshot.vitamins
          .map(
            (vitamin) => [
              vitamin.formattedName,
              vitamin.formattedTime,
              vitamin.status.label,
            ],
          )
          .toList(),
      emptyText: 'Nenhuma vitamina cadastrada.',
    );
  }

  pw.Widget _medications(MedicalReportSnapshot snapshot) {
    return _table(
      headers: ['Medicamento', 'Dose', 'Horário', 'Status'],
      rows: snapshot.medications
          .map(
            (medication) => [
              medication.formattedName,
              medication.dosage ?? '-',
              medication.formattedTime,
              medication.statusDescription,
            ],
          )
          .toList(),
      emptyText: 'Nenhum medicamento cadastrado.',
    );
  }

  pw.Widget _meals(MedicalReportSnapshot snapshot) {
    return _table(
      headers: ['Refeição', 'Tipo', 'Data', 'Proteína'],
      rows: snapshot.meals
          .take(12)
          .map(
            (meal) => [
              meal.formattedName,
              meal.formattedType,
              meal.formattedDate,
              meal.formattedProtein,
            ],
          )
          .toList(),
      emptyText: 'Nenhuma refeição cadastrada.',
    );
  }

  pw.Widget _appointments(MedicalReportSnapshot snapshot) {
    return _table(
      headers: ['Consulta', 'Data', 'Profissional', 'Local'],
      rows: snapshot.appointments
          .map(
            (appointment) => [
              appointment.title,
              appointment.formattedDate,
              appointment.doctorName ?? '-',
              appointment.location ?? '-',
            ],
          )
          .toList(),
      emptyText: 'Nenhuma consulta cadastrada.',
    );
  }

  pw.Widget _exams(MedicalReportSnapshot snapshot) {
    return _table(
      headers: ['Exame', 'Data', 'Laboratório', 'Anexo'],
      rows: snapshot.exams
          .map(
            (exam) => [
              exam.formattedName,
              exam.formattedDate,
              exam.laboratory ?? '-',
              exam.hasAttachment ? 'Sim' : 'Não',
            ],
          )
          .toList(),
      emptyText: 'Nenhum exame cadastrado.',
    );
  }

  pw.Widget _progress(MedicalReportSnapshot snapshot) {
    final progress = snapshot.dailySummary.weightProgress;

    if (progress == null) {
      return _empty('Evolução disponível após peso atual e meta preenchidos.');
    }

    return _keyValueGrid([
      ('Peso eliminado', AppWeightFormatter.kg(progress.weightLostKg)),
      ('Restante', AppWeightFormatter.kg(progress.remainingKg)),
      ('Progresso', '${(progress.progress * 100).round()}%'),
      ('Meta atingida', progress.isTargetReached ? 'Sim' : 'Não'),
    ]);
  }

  pw.Widget _attachments(MedicalReportSnapshot snapshot) {
    if (snapshot.attachments.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Anexos'),
        _table(
          headers: ['Arquivo', 'Tipo', 'Origem'],
          rows: snapshot.attachments
              .map(
                (attachment) => [
                  attachment.name,
                  attachment.type.name.toUpperCase(),
                  attachment.path,
                ],
              )
              .toList(),
          emptyText: '',
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 22, bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _keyValueGrid(List<(String, String)> values) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (item) => pw.Container(
              width: 246,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.$1,
                    style: const pw.TextStyle(color: _muted, fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    item.$2,
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required String emptyText,
  }) {
    if (rows.isEmpty) {
      return _empty(emptyText);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: _surface),
      headerStyle: pw.TextStyle(
        color: _ink,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(color: _ink, fontSize: 9),
      border: pw.TableBorder.all(color: _border),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(7),
    );
  }

  pw.Widget _scoreCard(int score) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Pontuação geral',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '$score/100',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          pw.Text(
            _scoreLabel(score),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metricBars(List<(String, double)> values) {
    return pw.Column(
      children: values
          .map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 90,
                    child: pw.Text(
                      item.$1,
                      style: const pw.TextStyle(color: _ink, fontSize: 9),
                    ),
                  ),
                  pw.Expanded(child: _progressBar(item.$2)),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 34,
                    child: pw.Text(
                      '${(item.$2.clamp(0, 1) * 100).round()}%',
                      style: const pw.TextStyle(color: _muted, fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _chartCard({required String title, required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _ink,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  pw.Widget _progressBar(double value) {
    final progress = (value.clamp(0, 1) * 1000).round();
    final remaining = 1000 - progress;

    return pw.Container(
      height: 8,
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Row(
        children: [
          if (progress > 0)
            pw.Expanded(
              flex: progress,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
              ),
            ),
          if (remaining > 0) pw.Expanded(flex: remaining, child: pw.SizedBox()),
        ],
      ),
    );
  }

  pw.Widget _weightChart(MedicalReportSnapshot snapshot) {
    final records = snapshot.weightHistory.take(8).toList().reversed.toList();

    if (records.isEmpty) {
      return _empty('Sem registros suficientes para gráfico de peso.');
    }

    final values = records.map((record) => record.weight.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max == min ? 1 : max - min;

    return pw.SizedBox(
      height: 110,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: records
            .map(
              (record) => pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        record.weight.value.toStringAsFixed(1),
                        style: const pw.TextStyle(color: _muted, fontSize: 8),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 24 + ((record.weight.value - min) / range) * 62,
                        decoration: pw.BoxDecoration(
                          color: _primary,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        AppDateFormatter.short(
                          record.recordedAt.value,
                        ).substring(0, 5),
                        style: const pw.TextStyle(color: _muted, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _pill(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(100),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Text(
        label,
        style: const pw.TextStyle(color: _ink, fontSize: 10),
      ),
    );
  }

  pw.Widget _empty(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: _muted, fontSize: 10),
      ),
    );
  }

  String _optionalWeight(double? value) {
    if (value == null) return 'Não informado';

    return AppWeightFormatter.kg(value);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Bom';

    return 'Em evolução';
  }

  String _fileName(MedicalReportSnapshot snapshot) {
    final date = snapshot.generatedAt;
    final stamp =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';

    return 'relatorio_medico_helpbari_$stamp.pdf';
  }
}
