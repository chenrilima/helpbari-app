import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/media/media.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../providers/exam_attachment_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/exam_use_cases_provider.dart';
import '../states/exam_state.dart';

class ExamViewModel extends Notifier<ExamState> {
  UuidService get _uuidService => ref.read(uuidServiceProvider);
  ExamUseCases get _useCases => ref.read(examUseCasesProvider);

  @override
  ExamState build() => const ExamState();

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(items: await _useCases.getAll(), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createExam({
    required String name,
    required DateTime examDate,
    String? laboratory,
    String? notes,
    MediaFile? attachment,
  }) async {
    final examName = ExamName.create(name);

    if (examName == null) return false;

    final exam = Exam(
      id: _uuidService.generate(),
      name: examName,
      examDate: ExamDate(examDate),
      laboratory: laboratory,
      notes: notes,
    );
    final ok = await _persist(() => _useCases.save(exam));
    if (ok && attachment != null) {
      state = state.copyWith(
        selectedExam: exam,
        pendingAttachment: attachment,
        attachmentPreview: attachment,
        attachmentStatus: ExamAttachmentStatus.localPending,
      );
      unawaited(uploadPendingAttachment());
    }
    return ok;
  }

  Future<bool> updateExam(
    Exam current, {
    required String name,
    required DateTime examDate,
    String? laboratory,
    String? notes,
    MediaFile? attachment,
    bool removeAttachment = false,
  }) async {
    final n = ExamName.create(name);
    if (n == null) return false;
    final updated = Exam(
      id: current.id,
      name: n,
      examDate: ExamDate(examDate),
      laboratory: laboratory,
      notes: notes,
      attachmentPath: removeAttachment ? null : current.attachmentPath,
    );
    final ok = await _persist(() => _useCases.update(updated));
    if (!ok) return false;
    state = state.copyWith(selectedExam: updated);
    if (removeAttachment && current.attachmentPath != null) {
      unawaited(_removeObject(current, current.attachmentPath!));
    }
    if (attachment != null) {
      state = state.copyWith(
        pendingAttachment: attachment,
        attachmentPreview: attachment,
        attachmentStatus: ExamAttachmentStatus.localPending,
      );
      unawaited(uploadPendingAttachment(previousPath: current.attachmentPath));
    }
    return true;
  }

  Future<bool> deleteExam(Exam exam) async {
    final ok = await _persist(() => _useCases.delete(exam.id));
    if (ok && exam.attachmentPath != null) {
      unawaited(_removeObject(exam, exam.attachmentPath!));
    }
    return ok;
  }

  Future<void> selectExam(Exam exam) async {
    state = state.copyWith(
      selectedExam: exam,
      attachmentStatus: exam.hasAttachment
          ? ExamAttachmentStatus.synced
          : ExamAttachmentStatus.none,
      clearPreview: true,
      clearSignedUrl: true,
    );
    if (exam.hasAttachment) unawaited(loadAttachment());
  }

  void setDateFilter(DateTime? value) =>
      state = state.copyWith(dateFilter: value, clearDateFilter: value == null);
  void clearDateFilter() => state = state.copyWith(clearDateFilter: true);
  Future<void> uploadPendingAttachment({String? previousPath}) async {
    final user = ref.read(authSessionProvider),
        exam = state.selectedExam,
        file = state.pendingAttachment;
    if (user == null || exam == null || file == null) return;
    state = state.copyWith(
      attachmentStatus: ExamAttachmentStatus.uploading,
      clearAttachmentError: true,
    );
    String? newPath;
    try {
      final uploaded = await ref
          .read(examAttachmentServiceProvider)
          .upload(userId: user.id, examId: exam.id, file: file);
      newPath = uploaded.path;
      final updated = exam.copyWith(attachmentPath: newPath);
      await _useCases.update(updated);
      state = state.copyWith(
        selectedExam: updated,
        attachmentPreview: uploaded.cachedFile,
        attachmentSignedUrl: uploaded.signedUrl,
        attachmentStatus: ExamAttachmentStatus.synced,
        clearPending: true,
      );
      _afterCommit();
      if (previousPath != null && previousPath != newPath) {
        await _removeObject(exam, previousPath);
      }
    } catch (e) {
      if (newPath != null) {
        try {
          await ref
              .read(examAttachmentServiceProvider)
              .remove(userId: user.id, examId: exam.id, path: newPath);
        } catch (_) {}
      }
      state = state.copyWith(
        attachmentStatus: ExamAttachmentStatus.failed,
        attachmentError: e.toString(),
      );
    }
  }

  Future<void> loadAttachment() async {
    final user = ref.read(authSessionProvider),
        exam = state.selectedExam,
        path = state.selectedExam?.attachmentPath;
    if (user == null || exam == null || path == null) return;
    try {
      final view = await ref
          .read(examAttachmentServiceProvider)
          .load(userId: user.id, examId: exam.id, path: path);
      state = state.copyWith(
        attachmentPreview: view.file,
        attachmentSignedUrl: view.signedUrl,
        attachmentStatus: ExamAttachmentStatus.synced,
        clearAttachmentError: true,
      );
    } catch (e) {
      state = state.copyWith(
        attachmentStatus: state.attachmentPreview == null
            ? ExamAttachmentStatus.failed
            : ExamAttachmentStatus.synced,
        attachmentError: state.attachmentPreview == null ? e.toString() : null,
      );
    }
  }

  Future<void> _removeObject(Exam exam, String path) async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;
    try {
      await ref
          .read(examAttachmentServiceProvider)
          .remove(userId: user.id, examId: exam.id, path: path);
    } catch (_) {}
  }

  Future<bool> _persist(Future<void> Function() operation) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await operation();
      await loadItems();
      _afterCommit();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void _afterCommit() {
    ref.invalidate(examUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
    unawaited(ref.read(syncManagerProvider.notifier).syncNow());
  }
}
