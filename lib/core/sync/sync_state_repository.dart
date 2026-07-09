import 'dart:convert';

import '../services/local_storage_service.dart';
import '../services/uuid_service.dart';
import 'sync_state.dart';

abstract interface class SyncStateRepository {
  Future<SyncState> getState();

  Future<SyncState> ensureState({
    required String appVersion,
    required String? userId,
  });

  Future<void> saveState(SyncState state);
}

class LocalSyncStateRepository implements SyncStateRepository {
  const LocalSyncStateRepository({
    required LocalStorageService storage,
    required UuidService uuidService,
  }) : _storage = storage,
       _uuidService = uuidService;

  static const _key = 'core.sync.state';

  final LocalStorageService _storage;
  final UuidService _uuidService;

  @override
  Future<SyncState> getState() async {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) return const SyncState();

    return SyncState.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<SyncState> ensureState({
    required String appVersion,
    required String? userId,
  }) async {
    final current = await getState();
    final state = current.copyWith(
      deviceId: current.deviceId ?? _uuidService.generate(),
      appVersion: appVersion,
      userId: userId,
    );

    await saveState(state);
    return state;
  }

  @override
  Future<void> saveState(SyncState state) {
    return _storage.setString(_key, jsonEncode(state.toJson()));
  }
}
