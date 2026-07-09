import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../data/repositories/report_file_saver.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/medical_report_providers.dart';
import '../states/medical_report_state.dart';

class MedicalReportViewModel extends Notifier<MedicalReportState> {
  late final MedicalReportUseCases _useCases;
  late final LoggerService _logger;

  @override
  MedicalReportState build() {
    _useCases = ref.read(medicalReportUseCasesProvider);
    _logger = ref.read(loggerServiceProvider);

    return const MedicalReportState();
  }

  Future<GeneratedMedicalReport?> generate() async {
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final report = await _useCases.generateCompleteReport();

      state = state.copyWith(report: report, isGenerating: false);

      return report;
    } catch (error, stackTrace) {
      _logger.error(
        'Erro ao gerar relatório médico.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Não foi possível gerar o relatório.',
      );

      return null;
    }
  }

  Future<String?> download() async {
    final report = state.report ?? await generate();

    if (report == null) return null;

    state = state.copyWith(isDownloading: true, clearError: true);

    try {
      final savedPath = await saveReportFile(
        bytes: report.bytes,
        fileName: report.fileName,
      );

      state = state.copyWith(
        report: report.copyWith(savedPath: savedPath),
        isDownloading: false,
      );

      return savedPath;
    } catch (error, stackTrace) {
      _logger.error(
        'Erro ao baixar relatório médico.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isDownloading: false,
        errorMessage: 'Não foi possível baixar o relatório.',
      );

      return null;
    }
  }

  Future<bool> share() async {
    final report = state.report ?? await generate();

    if (report == null) return false;

    state = state.copyWith(isSharing: true, clearError: true);

    try {
      await Printing.sharePdf(bytes: report.bytes, filename: report.fileName);
      state = state.copyWith(isSharing: false);

      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Erro ao compartilhar relatório médico.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSharing: false,
        errorMessage: 'Não foi possível compartilhar o relatório.',
      );

      return false;
    }
  }

  Future<bool> print() async {
    final report = state.report ?? await generate();

    if (report == null) return false;

    state = state.copyWith(isPrinting: true, clearError: true);

    try {
      await Printing.layoutPdf(
        name: report.fileName,
        onLayout: (_) async => report.bytes,
      );
      state = state.copyWith(isPrinting: false);

      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Erro ao imprimir relatório médico.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isPrinting: false,
        errorMessage: 'Não foi possível imprimir o relatório.',
      );

      return false;
    }
  }
}
