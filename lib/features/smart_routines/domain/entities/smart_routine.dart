import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/typed_ids.dart';

final class SmartRoutine extends Entity {
  factory SmartRoutine({
    required RoutineId routineId,
    required RoutineCategory category,
    required String displayName,
    required RoutineStatus status,
    required RoutineSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    PrescriptionItemReference? prescriptionReference,
    String? personalNotes,
    String? iconKey,
    DateTime? deletedAt,
  }) {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const SmartRoutineValidationException(
        'routine_name_required',
        'Routine display name is required.',
      );
    }
    if (updatedAt.isBefore(createdAt)) {
      throw const SmartRoutineValidationException(
        'invalid_routine_timestamps',
        'Routine updatedAt cannot precede createdAt.',
      );
    }
    return SmartRoutine._(
      routineId: routineId,
      category: category,
      displayName: name,
      status: status,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
      prescriptionReference: prescriptionReference,
      personalNotes: _optional(personalNotes),
      iconKey: _optional(iconKey),
      deletedAt: deletedAt,
    );
  }

  const SmartRoutine._({
    required this.routineId,
    required this.category,
    required this.displayName,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.prescriptionReference,
    this.personalNotes,
    this.iconKey,
    this.deletedAt,
  });

  final RoutineId routineId;
  @override
  String get id => routineId.value;
  final RoutineCategory category;
  final String displayName;
  final RoutineStatus status;
  final RoutineSource source;
  final PrescriptionItemReference? prescriptionReference;
  final String? personalNotes;
  final String? iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SmartRoutine rename(String name, DateTime at) =>
      _copy(displayName: name, updatedAt: at);

  SmartRoutine changeStatus(RoutineStatus next, DateTime at) {
    if (status == next) return this;
    if (status == RoutineStatus.archived ||
        !_allowedTransitions[status]!.contains(next)) {
      throw SmartRoutineValidationException(
        'invalid_routine_status_transition',
        'Cannot change routine status from ${status.name} to ${next.name}.',
      );
    }
    return _copy(status: next, updatedAt: at);
  }

  SmartRoutine _copy({
    String? displayName,
    RoutineStatus? status,
    DateTime? updatedAt,
  }) {
    return SmartRoutine(
      routineId: routineId,
      category: category,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prescriptionReference: prescriptionReference,
      personalNotes: personalNotes,
      iconKey: iconKey,
      deletedAt: deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRoutine &&
          routineId == other.routineId &&
          category == other.category &&
          displayName == other.displayName &&
          status == other.status &&
          source == other.source &&
          prescriptionReference == other.prescriptionReference &&
          personalNotes == other.personalNotes &&
          iconKey == other.iconKey &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    routineId,
    category,
    displayName,
    status,
    source,
    prescriptionReference,
    personalNotes,
    iconKey,
    createdAt,
    updatedAt,
    deletedAt,
  );

  static const _allowedTransitions = <RoutineStatus, Set<RoutineStatus>>{
    RoutineStatus.active: {
      RoutineStatus.paused,
      RoutineStatus.completed,
      RoutineStatus.canceled,
      RoutineStatus.archived,
    },
    RoutineStatus.paused: {
      RoutineStatus.active,
      RoutineStatus.completed,
      RoutineStatus.canceled,
      RoutineStatus.archived,
    },
    RoutineStatus.completed: {RoutineStatus.archived},
    RoutineStatus.canceled: {RoutineStatus.archived},
    RoutineStatus.archived: {},
  };
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
