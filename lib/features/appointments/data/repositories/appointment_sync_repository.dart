import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/value_objects.dart';
import '../datasources/appointment_supabase_datasource.dart';
import '../datasources/drift_appointment_local_datasource.dart';
import '../dtos/appointment_dto.dart';

typedef AppointmentAfterRemoteCommit =
    Future<void> Function(AppointmentDto value);

class AppointmentSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const AppointmentSyncRepository({
    required Future<DriftAppointmentLocalDatasource> Function() local,
    required AppointmentSupabaseDatasource remote,
    required String userId,
    required AppointmentAfterRemoteCommit afterRemoteCommit,
    SyncStatusMapper mapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _afterRemoteCommit = afterRemoteCommit,
       _mapper = mapper;
  static const key = 'appointments';
  final Future<DriftAppointmentLocalDatasource> Function() _local;
  final AppointmentSupabaseDatasource _remote;
  final String _userId;
  final AppointmentAfterRemoteCommit _afterRemoteCommit;
  final SyncStatusMapper _mapper;
  @override
  String get syncKey => key;
  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_operation).toList();
  @override
  Future<SyncOperation?> localOperationById(String id) async {
    final dto = await (await _local()).pendingById(id);
    return dto == null ? null : _operation(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async => (await _local())
      .applyRemote(await _remote.upsert(_dto(operation), userId: _userId));
  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_operation).toList();
  @override
  Future<void> applyRemote(SyncOperation operation) async {
    final dto = _dto(operation);
    await (await _local()).applyRemote(dto);
    await _afterRemoteCommit(dto);
  }

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    final dto = _dto(operation);
    await (await _local()).applyRemoteAndMarkSynced(dto);
    await _afterRemoteCommit(dto);
  }

  @override
  Future<void> markSynced(String id, {required DateTime syncedAt}) async =>
      (await _local()).markSynced(id);
  @override
  Future<void> markFailed(String id, SyncError error) async =>
      (await _local()).markFailed(id, error.message);
  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _local()).getLastPullAt(key);
  @override
  Future<void> saveSuccessfulSync(DateTime at) async =>
      (await _local()).saveCursor(key, at);
  SyncOperation _operation(AppointmentDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : _mapper.operationTypeFromStatus(dto.syncMetadata.syncStatus),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    payload: {
      'title': dto.title,
      'date': dto.date.toIso8601String(),
      'status': dto.status.name,
      'doctorName': dto.doctorName,
      'location': dto.location,
      'notes': dto.notes,
      'createdAt': dto.syncMetadata.createdAt.toIso8601String(),
    },
  );
  AppointmentDto _dto(SyncOperation op) => AppointmentDto(
    id: op.recordId,
    title: op.payload['title'] as String,
    date: DateTime.parse(op.payload['date'] as String),
    status: AppointmentStatus.values.firstWhere(
      (v) => v.name == op.payload['status'],
      orElse: () => AppointmentStatus.scheduled,
    ),
    doctorName: op.payload['doctorName'] as String?,
    location: op.payload['location'] as String?,
    notes: op.payload['notes'] as String?,
    syncMetadata: SyncMetadata(
      id: op.recordId,
      userId: op.userId ?? _userId,
      createdAt: DateTime.parse(op.payload['createdAt'] as String),
      updatedAt: op.updatedAt,
      deletedAt: op.deletedAt,
      syncStatus: op.syncStatus,
    ),
  );
}
