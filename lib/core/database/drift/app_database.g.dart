// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WaterRecordsTable extends WaterRecords
    with TableInfo<$WaterRecordsTable, WaterRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount_ml > 0)',
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousSyncStatusMeta =
      const VerificationMeta('previousSyncStatus');
  @override
  late final GeneratedColumn<String> previousSyncStatus =
      GeneratedColumn<String>(
        'previous_sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    amountMl,
    recordedAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('previous_sync_status')) {
      context.handle(
        _previousSyncStatusMeta,
        previousSyncStatus.isAcceptableOrUnknown(
          data['previous_sync_status']!,
          _previousSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, id};
  @override
  WaterRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      previousSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_sync_status'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $WaterRecordsTable createAlias(String alias) {
    return $WaterRecordsTable(attachedDatabase, alias);
  }
}

class WaterRecord extends DataClass implements Insertable<WaterRecord> {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  const WaterRecord({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.previousSyncStatus,
    required this.syncAttempts,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['amount_ml'] = Variable<int>(amountMl);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || previousSyncStatus != null) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  WaterRecordsCompanion toCompanion(bool nullToAbsent) {
    return WaterRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      amountMl: Value(amountMl),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      previousSyncStatus: previousSyncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSyncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory WaterRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      previousSyncStatus: serializer.fromJson<String?>(
        json['previousSyncStatus'],
      ),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'amountMl': serializer.toJson<int>(amountMl),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'previousSyncStatus': serializer.toJson<String?>(previousSyncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  WaterRecord copyWith({
    String? id,
    String? userId,
    int? amountMl,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
    Value<String?> previousSyncStatus = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
  }) => WaterRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    amountMl: amountMl ?? this.amountMl,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus.value
        : this.previousSyncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  WaterRecord copyWithCompanion(WaterRecordsCompanion data) {
    return WaterRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      previousSyncStatus: data.previousSyncStatus.present
          ? data.previousSyncStatus.value
          : this.previousSyncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amountMl: $amountMl, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    amountMl,
    recordedAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.amountMl == this.amountMl &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.previousSyncStatus == this.previousSyncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError);
}

class WaterRecordsCompanion extends UpdateCompanion<WaterRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> amountMl;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> previousSyncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const WaterRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterRecordsCompanion.insert({
    required String id,
    required String userId,
    required int amountMl,
    required DateTime recordedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String syncStatus,
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       amountMl = Value(amountMl),
       recordedAt = Value(recordedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<WaterRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? amountMl,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? previousSyncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (amountMl != null) 'amount_ml': amountMl,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (previousSyncStatus != null)
        'previous_sync_status': previousSyncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? amountMl,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<String?>? previousSyncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return WaterRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountMl: amountMl ?? this.amountMl,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      previousSyncStatus: previousSyncStatus ?? this.previousSyncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (previousSyncStatus.present) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amountMl: $amountMl, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repositoryKeyMeta = const VerificationMeta(
    'repositoryKey',
  );
  @override
  late final GeneratedColumn<String> repositoryKey = GeneratedColumn<String>(
    'repository_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushAt = GeneratedColumn<DateTime>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    repositoryKey,
    lastPullAt,
    lastPushAt,
    lastSyncAt,
    status,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('repository_key')) {
      context.handle(
        _repositoryKeyMeta,
        repositoryKey.isAcceptableOrUnknown(
          data['repository_key']!,
          _repositoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repositoryKeyMeta);
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, repositoryKey};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      repositoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repository_key'],
      )!,
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_push_at'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String userId;
  final String repositoryKey;
  final DateTime? lastPullAt;
  final DateTime? lastPushAt;
  final DateTime? lastSyncAt;
  final String status;
  final String? errorMessage;
  const SyncCursor({
    required this.userId,
    required this.repositoryKey,
    this.lastPullAt,
    this.lastPushAt,
    this.lastSyncAt,
    required this.status,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['repository_key'] = Variable<String>(repositoryKey);
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      userId: Value(userId),
      repositoryKey: Value(repositoryKey),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      userId: serializer.fromJson<String>(json['userId']),
      repositoryKey: serializer.fromJson<String>(json['repositoryKey']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      lastPushAt: serializer.fromJson<DateTime?>(json['lastPushAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'repositoryKey': serializer.toJson<String>(repositoryKey),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'lastPushAt': serializer.toJson<DateTime?>(lastPushAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncCursor copyWith({
    String? userId,
    String? repositoryKey,
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<DateTime?> lastPushAt = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    String? status,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncCursor(
    userId: userId ?? this.userId,
    repositoryKey: repositoryKey ?? this.repositoryKey,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      userId: data.userId.present ? data.userId.value : this.userId,
      repositoryKey: data.repositoryKey.present
          ? data.repositoryKey.value
          : this.repositoryKey,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('userId: $userId, ')
          ..write('repositoryKey: $repositoryKey, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    repositoryKey,
    lastPullAt,
    lastPushAt,
    lastSyncAt,
    status,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.userId == this.userId &&
          other.repositoryKey == this.repositoryKey &&
          other.lastPullAt == this.lastPullAt &&
          other.lastPushAt == this.lastPushAt &&
          other.lastSyncAt == this.lastSyncAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> userId;
  final Value<String> repositoryKey;
  final Value<DateTime?> lastPullAt;
  final Value<DateTime?> lastPushAt;
  final Value<DateTime?> lastSyncAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.userId = const Value.absent(),
    this.repositoryKey = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String userId,
    required String repositoryKey,
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       repositoryKey = Value(repositoryKey);
  static Insertable<SyncCursor> custom({
    Expression<String>? userId,
    Expression<String>? repositoryKey,
    Expression<DateTime>? lastPullAt,
    Expression<DateTime>? lastPushAt,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (repositoryKey != null) 'repository_key': repositoryKey,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? userId,
    Value<String>? repositoryKey,
    Value<DateTime?>? lastPullAt,
    Value<DateTime?>? lastPushAt,
    Value<DateTime?>? lastSyncAt,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      userId: userId ?? this.userId,
      repositoryKey: repositoryKey ?? this.repositoryKey,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (repositoryKey.present) {
      map['repository_key'] = Variable<String>(repositoryKey.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('userId: $userId, ')
          ..write('repositoryKey: $repositoryKey, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDevicesTable extends SyncDevices
    with TableInfo<$SyncDevicesTable, SyncDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, appVersion, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDevice(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncDevicesTable createAlias(String alias) {
    return $SyncDevicesTable(attachedDatabase, alias);
  }
}

class SyncDevice extends DataClass implements Insertable<SyncDevice> {
  final String deviceId;
  final String appVersion;
  final DateTime updatedAt;
  const SyncDevice({
    required this.deviceId,
    required this.appVersion,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['app_version'] = Variable<String>(appVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncDevicesCompanion toCompanion(bool nullToAbsent) {
    return SyncDevicesCompanion(
      deviceId: Value(deviceId),
      appVersion: Value(appVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'appVersion': serializer.toJson<String>(appVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncDevice copyWith({
    String? deviceId,
    String? appVersion,
    DateTime? updatedAt,
  }) => SyncDevice(
    deviceId: deviceId ?? this.deviceId,
    appVersion: appVersion ?? this.appVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncDevice copyWithCompanion(SyncDevicesCompanion data) {
    return SyncDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('appVersion: $appVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, appVersion, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDevice &&
          other.deviceId == this.deviceId &&
          other.appVersion == this.appVersion &&
          other.updatedAt == this.updatedAt);
}

class SyncDevicesCompanion extends UpdateCompanion<SyncDevice> {
  final Value<String> deviceId;
  final Value<String> appVersion;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDevicesCompanion.insert({
    required String deviceId,
    required String appVersion,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       appVersion = Value(appVersion),
       updatedAt = Value(updatedAt);
  static Insertable<SyncDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? appVersion,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (appVersion != null) 'app_version': appVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? appVersion,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('appVersion: $appVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMigrationsTable extends LocalMigrations
    with TableInfo<$LocalMigrationsTable, LocalMigration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMigrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceChecksumMeta = const VerificationMeta(
    'sourceChecksum',
  );
  @override
  late final GeneratedColumn<String> sourceChecksum = GeneratedColumn<String>(
    'source_checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedCountMeta = const VerificationMeta(
    'importedCount',
  );
  @override
  late final GeneratedColumn<int> importedCount = GeneratedColumn<int>(
    'imported_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    completedAt,
    sourceChecksum,
    importedCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_migrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMigration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('source_checksum')) {
      context.handle(
        _sourceChecksumMeta,
        sourceChecksum.isAcceptableOrUnknown(
          data['source_checksum']!,
          _sourceChecksumMeta,
        ),
      );
    }
    if (data.containsKey('imported_count')) {
      context.handle(
        _importedCountMeta,
        importedCount.isAcceptableOrUnknown(
          data['imported_count']!,
          _importedCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey};
  @override
  LocalMigration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMigration(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      sourceChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_checksum'],
      ),
      importedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_count'],
      )!,
    );
  }

  @override
  $LocalMigrationsTable createAlias(String alias) {
    return $LocalMigrationsTable(attachedDatabase, alias);
  }
}

class LocalMigration extends DataClass implements Insertable<LocalMigration> {
  final String migrationKey;
  final DateTime completedAt;
  final String? sourceChecksum;
  final int importedCount;
  const LocalMigration({
    required this.migrationKey,
    required this.completedAt,
    this.sourceChecksum,
    required this.importedCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || sourceChecksum != null) {
      map['source_checksum'] = Variable<String>(sourceChecksum);
    }
    map['imported_count'] = Variable<int>(importedCount);
    return map;
  }

  LocalMigrationsCompanion toCompanion(bool nullToAbsent) {
    return LocalMigrationsCompanion(
      migrationKey: Value(migrationKey),
      completedAt: Value(completedAt),
      sourceChecksum: sourceChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceChecksum),
      importedCount: Value(importedCount),
    );
  }

  factory LocalMigration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMigration(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      sourceChecksum: serializer.fromJson<String?>(json['sourceChecksum']),
      importedCount: serializer.fromJson<int>(json['importedCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'sourceChecksum': serializer.toJson<String?>(sourceChecksum),
      'importedCount': serializer.toJson<int>(importedCount),
    };
  }

  LocalMigration copyWith({
    String? migrationKey,
    DateTime? completedAt,
    Value<String?> sourceChecksum = const Value.absent(),
    int? importedCount,
  }) => LocalMigration(
    migrationKey: migrationKey ?? this.migrationKey,
    completedAt: completedAt ?? this.completedAt,
    sourceChecksum: sourceChecksum.present
        ? sourceChecksum.value
        : this.sourceChecksum,
    importedCount: importedCount ?? this.importedCount,
  );
  LocalMigration copyWithCompanion(LocalMigrationsCompanion data) {
    return LocalMigration(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      sourceChecksum: data.sourceChecksum.present
          ? data.sourceChecksum.value
          : this.sourceChecksum,
      importedCount: data.importedCount.present
          ? data.importedCount.value
          : this.importedCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigration(')
          ..write('migrationKey: $migrationKey, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceChecksum: $sourceChecksum, ')
          ..write('importedCount: $importedCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(migrationKey, completedAt, sourceChecksum, importedCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMigration &&
          other.migrationKey == this.migrationKey &&
          other.completedAt == this.completedAt &&
          other.sourceChecksum == this.sourceChecksum &&
          other.importedCount == this.importedCount);
}

class LocalMigrationsCompanion extends UpdateCompanion<LocalMigration> {
  final Value<String> migrationKey;
  final Value<DateTime> completedAt;
  final Value<String?> sourceChecksum;
  final Value<int> importedCount;
  final Value<int> rowid;
  const LocalMigrationsCompanion({
    this.migrationKey = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sourceChecksum = const Value.absent(),
    this.importedCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMigrationsCompanion.insert({
    required String migrationKey,
    required DateTime completedAt,
    this.sourceChecksum = const Value.absent(),
    this.importedCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       completedAt = Value(completedAt);
  static Insertable<LocalMigration> custom({
    Expression<String>? migrationKey,
    Expression<DateTime>? completedAt,
    Expression<String>? sourceChecksum,
    Expression<int>? importedCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (completedAt != null) 'completed_at': completedAt,
      if (sourceChecksum != null) 'source_checksum': sourceChecksum,
      if (importedCount != null) 'imported_count': importedCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMigrationsCompanion copyWith({
    Value<String>? migrationKey,
    Value<DateTime>? completedAt,
    Value<String?>? sourceChecksum,
    Value<int>? importedCount,
    Value<int>? rowid,
  }) {
    return LocalMigrationsCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      completedAt: completedAt ?? this.completedAt,
      sourceChecksum: sourceChecksum ?? this.sourceChecksum,
      importedCount: importedCount ?? this.importedCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (sourceChecksum.present) {
      map['source_checksum'] = Variable<String>(sourceChecksum.value);
    }
    if (importedCount.present) {
      map['imported_count'] = Variable<int>(importedCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigrationsCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceChecksum: $sourceChecksum, ')
          ..write('importedCount: $importedCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterCutoversTable extends WaterCutovers
    with TableInfo<$WaterCutoversTable, WaterCutover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterCutoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseSchemaVersionMeta =
      const VerificationMeta('databaseSchemaVersion');
  @override
  late final GeneratedColumn<int> databaseSchemaVersion = GeneratedColumn<int>(
    'database_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_cutovers';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterCutover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('database_schema_version')) {
      context.handle(
        _databaseSchemaVersionMeta,
        databaseSchemaVersion.isAcceptableOrUnknown(
          data['database_schema_version']!,
          _databaseSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_databaseSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, userId};
  @override
  WaterCutover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterCutover(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      databaseSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}database_schema_version'],
      )!,
    );
  }

  @override
  $WaterCutoversTable createAlias(String alias) {
    return $WaterCutoversTable(attachedDatabase, alias);
  }
}

class WaterCutover extends DataClass implements Insertable<WaterCutover> {
  final String migrationKey;
  final int version;
  final String userId;
  final DateTime completedAt;
  final String checksum;
  final int recordCount;
  final int databaseSchemaVersion;
  const WaterCutover({
    required this.migrationKey,
    required this.version,
    required this.userId,
    required this.completedAt,
    required this.checksum,
    required this.recordCount,
    required this.databaseSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['version'] = Variable<int>(version);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['checksum'] = Variable<String>(checksum);
    map['record_count'] = Variable<int>(recordCount);
    map['database_schema_version'] = Variable<int>(databaseSchemaVersion);
    return map;
  }

  WaterCutoversCompanion toCompanion(bool nullToAbsent) {
    return WaterCutoversCompanion(
      migrationKey: Value(migrationKey),
      version: Value(version),
      userId: Value(userId),
      completedAt: Value(completedAt),
      checksum: Value(checksum),
      recordCount: Value(recordCount),
      databaseSchemaVersion: Value(databaseSchemaVersion),
    );
  }

  factory WaterCutover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterCutover(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      version: serializer.fromJson<int>(json['version']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      databaseSchemaVersion: serializer.fromJson<int>(
        json['databaseSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'version': serializer.toJson<int>(version),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'checksum': serializer.toJson<String>(checksum),
      'recordCount': serializer.toJson<int>(recordCount),
      'databaseSchemaVersion': serializer.toJson<int>(databaseSchemaVersion),
    };
  }

  WaterCutover copyWith({
    String? migrationKey,
    int? version,
    String? userId,
    DateTime? completedAt,
    String? checksum,
    int? recordCount,
    int? databaseSchemaVersion,
  }) => WaterCutover(
    migrationKey: migrationKey ?? this.migrationKey,
    version: version ?? this.version,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    checksum: checksum ?? this.checksum,
    recordCount: recordCount ?? this.recordCount,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
  );
  WaterCutover copyWithCompanion(WaterCutoversCompanion data) {
    return WaterCutover(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      version: data.version.present ? data.version.value : this.version,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      databaseSchemaVersion: data.databaseSchemaVersion.present
          ? data.databaseSchemaVersion.value
          : this.databaseSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterCutover(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterCutover &&
          other.migrationKey == this.migrationKey &&
          other.version == this.version &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.checksum == this.checksum &&
          other.recordCount == this.recordCount &&
          other.databaseSchemaVersion == this.databaseSchemaVersion);
}

class WaterCutoversCompanion extends UpdateCompanion<WaterCutover> {
  final Value<String> migrationKey;
  final Value<int> version;
  final Value<String> userId;
  final Value<DateTime> completedAt;
  final Value<String> checksum;
  final Value<int> recordCount;
  final Value<int> databaseSchemaVersion;
  final Value<int> rowid;
  const WaterCutoversCompanion({
    this.migrationKey = const Value.absent(),
    this.version = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.databaseSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterCutoversCompanion.insert({
    required String migrationKey,
    required int version,
    required String userId,
    required DateTime completedAt,
    required String checksum,
    required int recordCount,
    required int databaseSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       version = Value(version),
       userId = Value(userId),
       completedAt = Value(completedAt),
       checksum = Value(checksum),
       recordCount = Value(recordCount),
       databaseSchemaVersion = Value(databaseSchemaVersion);
  static Insertable<WaterCutover> custom({
    Expression<String>? migrationKey,
    Expression<int>? version,
    Expression<String>? userId,
    Expression<DateTime>? completedAt,
    Expression<String>? checksum,
    Expression<int>? recordCount,
    Expression<int>? databaseSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (version != null) 'version': version,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (checksum != null) 'checksum': checksum,
      if (recordCount != null) 'record_count': recordCount,
      if (databaseSchemaVersion != null)
        'database_schema_version': databaseSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterCutoversCompanion copyWith({
    Value<String>? migrationKey,
    Value<int>? version,
    Value<String>? userId,
    Value<DateTime>? completedAt,
    Value<String>? checksum,
    Value<int>? recordCount,
    Value<int>? databaseSchemaVersion,
    Value<int>? rowid,
  }) {
    return WaterCutoversCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      databaseSchemaVersion:
          databaseSchemaVersion ?? this.databaseSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (databaseSchemaVersion.present) {
      map['database_schema_version'] = Variable<int>(
        databaseSchemaVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterCutoversCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRecordsTable extends SettingsRecords
    with TableInfo<$SettingsRecordsTable, SettingsRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyWaterGoalMlMeta = const VerificationMeta(
    'dailyWaterGoalMl',
  );
  @override
  late final GeneratedColumn<int> dailyWaterGoalMl = GeneratedColumn<int>(
    'daily_water_goal_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2000),
  );
  static const VerificationMeta _vitaminRemindersEnabledMeta =
      const VerificationMeta('vitaminRemindersEnabled');
  @override
  late final GeneratedColumn<bool> vitaminRemindersEnabled =
      GeneratedColumn<bool>(
        'vitamin_reminders_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("vitamin_reminders_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _medicationRemindersEnabledMeta =
      const VerificationMeta('medicationRemindersEnabled');
  @override
  late final GeneratedColumn<bool> medicationRemindersEnabled =
      GeneratedColumn<bool>(
        'medication_reminders_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("medication_reminders_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _appointmentRemindersEnabledMeta =
      const VerificationMeta('appointmentRemindersEnabled');
  @override
  late final GeneratedColumn<bool> appointmentRemindersEnabled =
      GeneratedColumn<bool>(
        'appointment_reminders_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("appointment_reminders_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _mealTrackingEnabledMeta =
      const VerificationMeta('mealTrackingEnabled');
  @override
  late final GeneratedColumn<bool> mealTrackingEnabled = GeneratedColumn<bool>(
    'meal_tracking_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("meal_tracking_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _weightUnitMeta = const VerificationMeta(
    'weightUnit',
  );
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
    'weight_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kg'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousSyncStatusMeta =
      const VerificationMeta('previousSyncStatus');
  @override
  late final GeneratedColumn<String> previousSyncStatus =
      GeneratedColumn<String>(
        'previous_sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    dailyWaterGoalMl,
    vitaminRemindersEnabled,
    medicationRemindersEnabled,
    appointmentRemindersEnabled,
    mealTrackingEnabled,
    weightUnit,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('daily_water_goal_ml')) {
      context.handle(
        _dailyWaterGoalMlMeta,
        dailyWaterGoalMl.isAcceptableOrUnknown(
          data['daily_water_goal_ml']!,
          _dailyWaterGoalMlMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_reminders_enabled')) {
      context.handle(
        _vitaminRemindersEnabledMeta,
        vitaminRemindersEnabled.isAcceptableOrUnknown(
          data['vitamin_reminders_enabled']!,
          _vitaminRemindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('medication_reminders_enabled')) {
      context.handle(
        _medicationRemindersEnabledMeta,
        medicationRemindersEnabled.isAcceptableOrUnknown(
          data['medication_reminders_enabled']!,
          _medicationRemindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('appointment_reminders_enabled')) {
      context.handle(
        _appointmentRemindersEnabledMeta,
        appointmentRemindersEnabled.isAcceptableOrUnknown(
          data['appointment_reminders_enabled']!,
          _appointmentRemindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('meal_tracking_enabled')) {
      context.handle(
        _mealTrackingEnabledMeta,
        mealTrackingEnabled.isAcceptableOrUnknown(
          data['meal_tracking_enabled']!,
          _mealTrackingEnabledMeta,
        ),
      );
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
        _weightUnitMeta,
        weightUnit.isAcceptableOrUnknown(data['weight_unit']!, _weightUnitMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('previous_sync_status')) {
      context.handle(
        _previousSyncStatusMeta,
        previousSyncStatus.isAcceptableOrUnknown(
          data['previous_sync_status']!,
          _previousSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, id};
  @override
  SettingsRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      dailyWaterGoalMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_water_goal_ml'],
      )!,
      vitaminRemindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vitamin_reminders_enabled'],
      )!,
      medicationRemindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}medication_reminders_enabled'],
      )!,
      appointmentRemindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}appointment_reminders_enabled'],
      )!,
      mealTrackingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}meal_tracking_enabled'],
      )!,
      weightUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_unit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      previousSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_sync_status'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $SettingsRecordsTable createAlias(String alias) {
    return $SettingsRecordsTable(attachedDatabase, alias);
  }
}

class SettingsRecord extends DataClass implements Insertable<SettingsRecord> {
  final String id;
  final String userId;
  final int dailyWaterGoalMl;
  final bool vitaminRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool mealTrackingEnabled;
  final String weightUnit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  const SettingsRecord({
    required this.id,
    required this.userId,
    required this.dailyWaterGoalMl,
    required this.vitaminRemindersEnabled,
    required this.medicationRemindersEnabled,
    required this.appointmentRemindersEnabled,
    required this.mealTrackingEnabled,
    required this.weightUnit,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.previousSyncStatus,
    required this.syncAttempts,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['daily_water_goal_ml'] = Variable<int>(dailyWaterGoalMl);
    map['vitamin_reminders_enabled'] = Variable<bool>(vitaminRemindersEnabled);
    map['medication_reminders_enabled'] = Variable<bool>(
      medicationRemindersEnabled,
    );
    map['appointment_reminders_enabled'] = Variable<bool>(
      appointmentRemindersEnabled,
    );
    map['meal_tracking_enabled'] = Variable<bool>(mealTrackingEnabled);
    map['weight_unit'] = Variable<String>(weightUnit);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || previousSyncStatus != null) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  SettingsRecordsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      dailyWaterGoalMl: Value(dailyWaterGoalMl),
      vitaminRemindersEnabled: Value(vitaminRemindersEnabled),
      medicationRemindersEnabled: Value(medicationRemindersEnabled),
      appointmentRemindersEnabled: Value(appointmentRemindersEnabled),
      mealTrackingEnabled: Value(mealTrackingEnabled),
      weightUnit: Value(weightUnit),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      previousSyncStatus: previousSyncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSyncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory SettingsRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      dailyWaterGoalMl: serializer.fromJson<int>(json['dailyWaterGoalMl']),
      vitaminRemindersEnabled: serializer.fromJson<bool>(
        json['vitaminRemindersEnabled'],
      ),
      medicationRemindersEnabled: serializer.fromJson<bool>(
        json['medicationRemindersEnabled'],
      ),
      appointmentRemindersEnabled: serializer.fromJson<bool>(
        json['appointmentRemindersEnabled'],
      ),
      mealTrackingEnabled: serializer.fromJson<bool>(
        json['mealTrackingEnabled'],
      ),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      previousSyncStatus: serializer.fromJson<String?>(
        json['previousSyncStatus'],
      ),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'dailyWaterGoalMl': serializer.toJson<int>(dailyWaterGoalMl),
      'vitaminRemindersEnabled': serializer.toJson<bool>(
        vitaminRemindersEnabled,
      ),
      'medicationRemindersEnabled': serializer.toJson<bool>(
        medicationRemindersEnabled,
      ),
      'appointmentRemindersEnabled': serializer.toJson<bool>(
        appointmentRemindersEnabled,
      ),
      'mealTrackingEnabled': serializer.toJson<bool>(mealTrackingEnabled),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'previousSyncStatus': serializer.toJson<String?>(previousSyncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  SettingsRecord copyWith({
    String? id,
    String? userId,
    int? dailyWaterGoalMl,
    bool? vitaminRemindersEnabled,
    bool? medicationRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? mealTrackingEnabled,
    String? weightUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
    Value<String?> previousSyncStatus = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
  }) => SettingsRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
    vitaminRemindersEnabled:
        vitaminRemindersEnabled ?? this.vitaminRemindersEnabled,
    medicationRemindersEnabled:
        medicationRemindersEnabled ?? this.medicationRemindersEnabled,
    appointmentRemindersEnabled:
        appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
    mealTrackingEnabled: mealTrackingEnabled ?? this.mealTrackingEnabled,
    weightUnit: weightUnit ?? this.weightUnit,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus.value
        : this.previousSyncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  SettingsRecord copyWithCompanion(SettingsRecordsCompanion data) {
    return SettingsRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      dailyWaterGoalMl: data.dailyWaterGoalMl.present
          ? data.dailyWaterGoalMl.value
          : this.dailyWaterGoalMl,
      vitaminRemindersEnabled: data.vitaminRemindersEnabled.present
          ? data.vitaminRemindersEnabled.value
          : this.vitaminRemindersEnabled,
      medicationRemindersEnabled: data.medicationRemindersEnabled.present
          ? data.medicationRemindersEnabled.value
          : this.medicationRemindersEnabled,
      appointmentRemindersEnabled: data.appointmentRemindersEnabled.present
          ? data.appointmentRemindersEnabled.value
          : this.appointmentRemindersEnabled,
      mealTrackingEnabled: data.mealTrackingEnabled.present
          ? data.mealTrackingEnabled.value
          : this.mealTrackingEnabled,
      weightUnit: data.weightUnit.present
          ? data.weightUnit.value
          : this.weightUnit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      previousSyncStatus: data.previousSyncStatus.present
          ? data.previousSyncStatus.value
          : this.previousSyncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dailyWaterGoalMl: $dailyWaterGoalMl, ')
          ..write('vitaminRemindersEnabled: $vitaminRemindersEnabled, ')
          ..write('medicationRemindersEnabled: $medicationRemindersEnabled, ')
          ..write('appointmentRemindersEnabled: $appointmentRemindersEnabled, ')
          ..write('mealTrackingEnabled: $mealTrackingEnabled, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    dailyWaterGoalMl,
    vitaminRemindersEnabled,
    medicationRemindersEnabled,
    appointmentRemindersEnabled,
    mealTrackingEnabled,
    weightUnit,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.dailyWaterGoalMl == this.dailyWaterGoalMl &&
          other.vitaminRemindersEnabled == this.vitaminRemindersEnabled &&
          other.medicationRemindersEnabled == this.medicationRemindersEnabled &&
          other.appointmentRemindersEnabled ==
              this.appointmentRemindersEnabled &&
          other.mealTrackingEnabled == this.mealTrackingEnabled &&
          other.weightUnit == this.weightUnit &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.previousSyncStatus == this.previousSyncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError);
}

class SettingsRecordsCompanion extends UpdateCompanion<SettingsRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> dailyWaterGoalMl;
  final Value<bool> vitaminRemindersEnabled;
  final Value<bool> medicationRemindersEnabled;
  final Value<bool> appointmentRemindersEnabled;
  final Value<bool> mealTrackingEnabled;
  final Value<String> weightUnit;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> previousSyncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const SettingsRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.dailyWaterGoalMl = const Value.absent(),
    this.vitaminRemindersEnabled = const Value.absent(),
    this.medicationRemindersEnabled = const Value.absent(),
    this.appointmentRemindersEnabled = const Value.absent(),
    this.mealTrackingEnabled = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsRecordsCompanion.insert({
    required String id,
    required String userId,
    this.dailyWaterGoalMl = const Value.absent(),
    this.vitaminRemindersEnabled = const Value.absent(),
    this.medicationRemindersEnabled = const Value.absent(),
    this.appointmentRemindersEnabled = const Value.absent(),
    this.mealTrackingEnabled = const Value.absent(),
    this.weightUnit = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String syncStatus,
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<SettingsRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? dailyWaterGoalMl,
    Expression<bool>? vitaminRemindersEnabled,
    Expression<bool>? medicationRemindersEnabled,
    Expression<bool>? appointmentRemindersEnabled,
    Expression<bool>? mealTrackingEnabled,
    Expression<String>? weightUnit,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? previousSyncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (dailyWaterGoalMl != null) 'daily_water_goal_ml': dailyWaterGoalMl,
      if (vitaminRemindersEnabled != null)
        'vitamin_reminders_enabled': vitaminRemindersEnabled,
      if (medicationRemindersEnabled != null)
        'medication_reminders_enabled': medicationRemindersEnabled,
      if (appointmentRemindersEnabled != null)
        'appointment_reminders_enabled': appointmentRemindersEnabled,
      if (mealTrackingEnabled != null)
        'meal_tracking_enabled': mealTrackingEnabled,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (previousSyncStatus != null)
        'previous_sync_status': previousSyncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? dailyWaterGoalMl,
    Value<bool>? vitaminRemindersEnabled,
    Value<bool>? medicationRemindersEnabled,
    Value<bool>? appointmentRemindersEnabled,
    Value<bool>? mealTrackingEnabled,
    Value<String>? weightUnit,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<String?>? previousSyncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return SettingsRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      vitaminRemindersEnabled:
          vitaminRemindersEnabled ?? this.vitaminRemindersEnabled,
      medicationRemindersEnabled:
          medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      appointmentRemindersEnabled:
          appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      mealTrackingEnabled: mealTrackingEnabled ?? this.mealTrackingEnabled,
      weightUnit: weightUnit ?? this.weightUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      previousSyncStatus: previousSyncStatus ?? this.previousSyncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (dailyWaterGoalMl.present) {
      map['daily_water_goal_ml'] = Variable<int>(dailyWaterGoalMl.value);
    }
    if (vitaminRemindersEnabled.present) {
      map['vitamin_reminders_enabled'] = Variable<bool>(
        vitaminRemindersEnabled.value,
      );
    }
    if (medicationRemindersEnabled.present) {
      map['medication_reminders_enabled'] = Variable<bool>(
        medicationRemindersEnabled.value,
      );
    }
    if (appointmentRemindersEnabled.present) {
      map['appointment_reminders_enabled'] = Variable<bool>(
        appointmentRemindersEnabled.value,
      );
    }
    if (mealTrackingEnabled.present) {
      map['meal_tracking_enabled'] = Variable<bool>(mealTrackingEnabled.value);
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (previousSyncStatus.present) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dailyWaterGoalMl: $dailyWaterGoalMl, ')
          ..write('vitaminRemindersEnabled: $vitaminRemindersEnabled, ')
          ..write('medicationRemindersEnabled: $medicationRemindersEnabled, ')
          ..write('appointmentRemindersEnabled: $appointmentRemindersEnabled, ')
          ..write('mealTrackingEnabled: $mealTrackingEnabled, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsCutoversTable extends SettingsCutovers
    with TableInfo<$SettingsCutoversTable, SettingsCutover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsCutoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseSchemaVersionMeta =
      const VerificationMeta('databaseSchemaVersion');
  @override
  late final GeneratedColumn<int> databaseSchemaVersion = GeneratedColumn<int>(
    'database_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_cutovers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsCutover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('database_schema_version')) {
      context.handle(
        _databaseSchemaVersionMeta,
        databaseSchemaVersion.isAcceptableOrUnknown(
          data['database_schema_version']!,
          _databaseSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_databaseSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, userId};
  @override
  SettingsCutover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsCutover(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      databaseSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}database_schema_version'],
      )!,
    );
  }

  @override
  $SettingsCutoversTable createAlias(String alias) {
    return $SettingsCutoversTable(attachedDatabase, alias);
  }
}

class SettingsCutover extends DataClass implements Insertable<SettingsCutover> {
  final String migrationKey;
  final int version;
  final String userId;
  final DateTime completedAt;
  final String checksum;
  final int recordCount;
  final int databaseSchemaVersion;
  const SettingsCutover({
    required this.migrationKey,
    required this.version,
    required this.userId,
    required this.completedAt,
    required this.checksum,
    required this.recordCount,
    required this.databaseSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['version'] = Variable<int>(version);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['checksum'] = Variable<String>(checksum);
    map['record_count'] = Variable<int>(recordCount);
    map['database_schema_version'] = Variable<int>(databaseSchemaVersion);
    return map;
  }

  SettingsCutoversCompanion toCompanion(bool nullToAbsent) {
    return SettingsCutoversCompanion(
      migrationKey: Value(migrationKey),
      version: Value(version),
      userId: Value(userId),
      completedAt: Value(completedAt),
      checksum: Value(checksum),
      recordCount: Value(recordCount),
      databaseSchemaVersion: Value(databaseSchemaVersion),
    );
  }

  factory SettingsCutover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsCutover(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      version: serializer.fromJson<int>(json['version']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      databaseSchemaVersion: serializer.fromJson<int>(
        json['databaseSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'version': serializer.toJson<int>(version),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'checksum': serializer.toJson<String>(checksum),
      'recordCount': serializer.toJson<int>(recordCount),
      'databaseSchemaVersion': serializer.toJson<int>(databaseSchemaVersion),
    };
  }

  SettingsCutover copyWith({
    String? migrationKey,
    int? version,
    String? userId,
    DateTime? completedAt,
    String? checksum,
    int? recordCount,
    int? databaseSchemaVersion,
  }) => SettingsCutover(
    migrationKey: migrationKey ?? this.migrationKey,
    version: version ?? this.version,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    checksum: checksum ?? this.checksum,
    recordCount: recordCount ?? this.recordCount,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
  );
  SettingsCutover copyWithCompanion(SettingsCutoversCompanion data) {
    return SettingsCutover(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      version: data.version.present ? data.version.value : this.version,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      databaseSchemaVersion: data.databaseSchemaVersion.present
          ? data.databaseSchemaVersion.value
          : this.databaseSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCutover(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsCutover &&
          other.migrationKey == this.migrationKey &&
          other.version == this.version &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.checksum == this.checksum &&
          other.recordCount == this.recordCount &&
          other.databaseSchemaVersion == this.databaseSchemaVersion);
}

class SettingsCutoversCompanion extends UpdateCompanion<SettingsCutover> {
  final Value<String> migrationKey;
  final Value<int> version;
  final Value<String> userId;
  final Value<DateTime> completedAt;
  final Value<String> checksum;
  final Value<int> recordCount;
  final Value<int> databaseSchemaVersion;
  final Value<int> rowid;
  const SettingsCutoversCompanion({
    this.migrationKey = const Value.absent(),
    this.version = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.databaseSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCutoversCompanion.insert({
    required String migrationKey,
    required int version,
    required String userId,
    required DateTime completedAt,
    required String checksum,
    required int recordCount,
    required int databaseSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       version = Value(version),
       userId = Value(userId),
       completedAt = Value(completedAt),
       checksum = Value(checksum),
       recordCount = Value(recordCount),
       databaseSchemaVersion = Value(databaseSchemaVersion);
  static Insertable<SettingsCutover> custom({
    Expression<String>? migrationKey,
    Expression<int>? version,
    Expression<String>? userId,
    Expression<DateTime>? completedAt,
    Expression<String>? checksum,
    Expression<int>? recordCount,
    Expression<int>? databaseSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (version != null) 'version': version,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (checksum != null) 'checksum': checksum,
      if (recordCount != null) 'record_count': recordCount,
      if (databaseSchemaVersion != null)
        'database_schema_version': databaseSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCutoversCompanion copyWith({
    Value<String>? migrationKey,
    Value<int>? version,
    Value<String>? userId,
    Value<DateTime>? completedAt,
    Value<String>? checksum,
    Value<int>? recordCount,
    Value<int>? databaseSchemaVersion,
    Value<int>? rowid,
  }) {
    return SettingsCutoversCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      databaseSchemaVersion:
          databaseSchemaVersion ?? this.databaseSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (databaseSchemaVersion.present) {
      map['database_schema_version'] = Variable<int>(
        databaseSchemaVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCutoversCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileRecordsTable extends ProfileRecords
    with TableInfo<$ProfileRecordsTable, ProfileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightInCentimetersMeta =
      const VerificationMeta('heightInCentimeters');
  @override
  late final GeneratedColumn<int> heightInCentimeters = GeneratedColumn<int>(
    'height_in_centimeters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialWeightMeta = const VerificationMeta(
    'initialWeight',
  );
  @override
  late final GeneratedColumn<double> initialWeight = GeneratedColumn<double>(
    'initial_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetWeightMeta = const VerificationMeta(
    'targetWeight',
  );
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
    'target_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surgeryDateMeta = const VerificationMeta(
    'surgeryDate',
  );
  @override
  late final GeneratedColumn<DateTime> surgeryDate = GeneratedColumn<DateTime>(
    'surgery_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surgeryTypeMeta = const VerificationMeta(
    'surgeryType',
  );
  @override
  late final GeneratedColumn<String> surgeryType = GeneratedColumn<String>(
    'surgery_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoStoragePathMeta = const VerificationMeta(
    'photoStoragePath',
  );
  @override
  late final GeneratedColumn<String> photoStoragePath = GeneratedColumn<String>(
    'photo_storage_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousSyncStatusMeta =
      const VerificationMeta('previousSyncStatus');
  @override
  late final GeneratedColumn<String> previousSyncStatus =
      GeneratedColumn<String>(
        'previous_sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    email,
    birthDate,
    heightInCentimeters,
    initialWeight,
    targetWeight,
    surgeryDate,
    surgeryType,
    photoUrl,
    photoStoragePath,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('height_in_centimeters')) {
      context.handle(
        _heightInCentimetersMeta,
        heightInCentimeters.isAcceptableOrUnknown(
          data['height_in_centimeters']!,
          _heightInCentimetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heightInCentimetersMeta);
    }
    if (data.containsKey('initial_weight')) {
      context.handle(
        _initialWeightMeta,
        initialWeight.isAcceptableOrUnknown(
          data['initial_weight']!,
          _initialWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialWeightMeta);
    }
    if (data.containsKey('target_weight')) {
      context.handle(
        _targetWeightMeta,
        targetWeight.isAcceptableOrUnknown(
          data['target_weight']!,
          _targetWeightMeta,
        ),
      );
    }
    if (data.containsKey('surgery_date')) {
      context.handle(
        _surgeryDateMeta,
        surgeryDate.isAcceptableOrUnknown(
          data['surgery_date']!,
          _surgeryDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surgeryDateMeta);
    }
    if (data.containsKey('surgery_type')) {
      context.handle(
        _surgeryTypeMeta,
        surgeryType.isAcceptableOrUnknown(
          data['surgery_type']!,
          _surgeryTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surgeryTypeMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('photo_storage_path')) {
      context.handle(
        _photoStoragePathMeta,
        photoStoragePath.isAcceptableOrUnknown(
          data['photo_storage_path']!,
          _photoStoragePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('previous_sync_status')) {
      context.handle(
        _previousSyncStatusMeta,
        previousSyncStatus.isAcceptableOrUnknown(
          data['previous_sync_status']!,
          _previousSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, id};
  @override
  ProfileRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      )!,
      heightInCentimeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_in_centimeters'],
      )!,
      initialWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_weight'],
      )!,
      targetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight'],
      ),
      surgeryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}surgery_date'],
      )!,
      surgeryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surgery_type'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoStoragePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_storage_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      previousSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_sync_status'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $ProfileRecordsTable createAlias(String alias) {
    return $ProfileRecordsTable(attachedDatabase, alias);
  }
}

class ProfileRecord extends DataClass implements Insertable<ProfileRecord> {
  final String id;
  final String userId;
  final String name;
  final String email;
  final DateTime birthDate;
  final int heightInCentimeters;
  final double initialWeight;
  final double? targetWeight;
  final DateTime surgeryDate;
  final String surgeryType;
  final String? photoUrl;
  final String? photoStoragePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  const ProfileRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.heightInCentimeters,
    required this.initialWeight,
    this.targetWeight,
    required this.surgeryDate,
    required this.surgeryType,
    this.photoUrl,
    this.photoStoragePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.previousSyncStatus,
    required this.syncAttempts,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['height_in_centimeters'] = Variable<int>(heightInCentimeters);
    map['initial_weight'] = Variable<double>(initialWeight);
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<double>(targetWeight);
    }
    map['surgery_date'] = Variable<DateTime>(surgeryDate);
    map['surgery_type'] = Variable<String>(surgeryType);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || photoStoragePath != null) {
      map['photo_storage_path'] = Variable<String>(photoStoragePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || previousSyncStatus != null) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  ProfileRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProfileRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      email: Value(email),
      birthDate: Value(birthDate),
      heightInCentimeters: Value(heightInCentimeters),
      initialWeight: Value(initialWeight),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      surgeryDate: Value(surgeryDate),
      surgeryType: Value(surgeryType),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      photoStoragePath: photoStoragePath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoStoragePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      previousSyncStatus: previousSyncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSyncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory ProfileRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      heightInCentimeters: serializer.fromJson<int>(
        json['heightInCentimeters'],
      ),
      initialWeight: serializer.fromJson<double>(json['initialWeight']),
      targetWeight: serializer.fromJson<double?>(json['targetWeight']),
      surgeryDate: serializer.fromJson<DateTime>(json['surgeryDate']),
      surgeryType: serializer.fromJson<String>(json['surgeryType']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoStoragePath: serializer.fromJson<String?>(json['photoStoragePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      previousSyncStatus: serializer.fromJson<String?>(
        json['previousSyncStatus'],
      ),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'heightInCentimeters': serializer.toJson<int>(heightInCentimeters),
      'initialWeight': serializer.toJson<double>(initialWeight),
      'targetWeight': serializer.toJson<double?>(targetWeight),
      'surgeryDate': serializer.toJson<DateTime>(surgeryDate),
      'surgeryType': serializer.toJson<String>(surgeryType),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoStoragePath': serializer.toJson<String?>(photoStoragePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'previousSyncStatus': serializer.toJson<String?>(previousSyncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  ProfileRecord copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    DateTime? birthDate,
    int? heightInCentimeters,
    double? initialWeight,
    Value<double?> targetWeight = const Value.absent(),
    DateTime? surgeryDate,
    String? surgeryType,
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoStoragePath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
    Value<String?> previousSyncStatus = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
  }) => ProfileRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    email: email ?? this.email,
    birthDate: birthDate ?? this.birthDate,
    heightInCentimeters: heightInCentimeters ?? this.heightInCentimeters,
    initialWeight: initialWeight ?? this.initialWeight,
    targetWeight: targetWeight.present ? targetWeight.value : this.targetWeight,
    surgeryDate: surgeryDate ?? this.surgeryDate,
    surgeryType: surgeryType ?? this.surgeryType,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoStoragePath: photoStoragePath.present
        ? photoStoragePath.value
        : this.photoStoragePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus.value
        : this.previousSyncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  ProfileRecord copyWithCompanion(ProfileRecordsCompanion data) {
    return ProfileRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      heightInCentimeters: data.heightInCentimeters.present
          ? data.heightInCentimeters.value
          : this.heightInCentimeters,
      initialWeight: data.initialWeight.present
          ? data.initialWeight.value
          : this.initialWeight,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      surgeryDate: data.surgeryDate.present
          ? data.surgeryDate.value
          : this.surgeryDate,
      surgeryType: data.surgeryType.present
          ? data.surgeryType.value
          : this.surgeryType,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      photoStoragePath: data.photoStoragePath.present
          ? data.photoStoragePath.value
          : this.photoStoragePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      previousSyncStatus: data.previousSyncStatus.present
          ? data.previousSyncStatus.value
          : this.previousSyncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightInCentimeters: $heightInCentimeters, ')
          ..write('initialWeight: $initialWeight, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('surgeryDate: $surgeryDate, ')
          ..write('surgeryType: $surgeryType, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoStoragePath: $photoStoragePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    email,
    birthDate,
    heightInCentimeters,
    initialWeight,
    targetWeight,
    surgeryDate,
    surgeryType,
    photoUrl,
    photoStoragePath,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.email == this.email &&
          other.birthDate == this.birthDate &&
          other.heightInCentimeters == this.heightInCentimeters &&
          other.initialWeight == this.initialWeight &&
          other.targetWeight == this.targetWeight &&
          other.surgeryDate == this.surgeryDate &&
          other.surgeryType == this.surgeryType &&
          other.photoUrl == this.photoUrl &&
          other.photoStoragePath == this.photoStoragePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.previousSyncStatus == this.previousSyncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError);
}

class ProfileRecordsCompanion extends UpdateCompanion<ProfileRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> email;
  final Value<DateTime> birthDate;
  final Value<int> heightInCentimeters;
  final Value<double> initialWeight;
  final Value<double?> targetWeight;
  final Value<DateTime> surgeryDate;
  final Value<String> surgeryType;
  final Value<String?> photoUrl;
  final Value<String?> photoStoragePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> previousSyncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const ProfileRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightInCentimeters = const Value.absent(),
    this.initialWeight = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.surgeryDate = const Value.absent(),
    this.surgeryType = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoStoragePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileRecordsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String email,
    required DateTime birthDate,
    required int heightInCentimeters,
    required double initialWeight,
    this.targetWeight = const Value.absent(),
    required DateTime surgeryDate,
    required String surgeryType,
    this.photoUrl = const Value.absent(),
    this.photoStoragePath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String syncStatus,
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       email = Value(email),
       birthDate = Value(birthDate),
       heightInCentimeters = Value(heightInCentimeters),
       initialWeight = Value(initialWeight),
       surgeryDate = Value(surgeryDate),
       surgeryType = Value(surgeryType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<ProfileRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<DateTime>? birthDate,
    Expression<int>? heightInCentimeters,
    Expression<double>? initialWeight,
    Expression<double>? targetWeight,
    Expression<DateTime>? surgeryDate,
    Expression<String>? surgeryType,
    Expression<String>? photoUrl,
    Expression<String>? photoStoragePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? previousSyncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightInCentimeters != null)
        'height_in_centimeters': heightInCentimeters,
      if (initialWeight != null) 'initial_weight': initialWeight,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (surgeryDate != null) 'surgery_date': surgeryDate,
      if (surgeryType != null) 'surgery_type': surgeryType,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoStoragePath != null) 'photo_storage_path': photoStoragePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (previousSyncStatus != null)
        'previous_sync_status': previousSyncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? email,
    Value<DateTime>? birthDate,
    Value<int>? heightInCentimeters,
    Value<double>? initialWeight,
    Value<double?>? targetWeight,
    Value<DateTime>? surgeryDate,
    Value<String>? surgeryType,
    Value<String?>? photoUrl,
    Value<String?>? photoStoragePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<String?>? previousSyncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return ProfileRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      heightInCentimeters: heightInCentimeters ?? this.heightInCentimeters,
      initialWeight: initialWeight ?? this.initialWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      surgeryType: surgeryType ?? this.surgeryType,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStoragePath: photoStoragePath ?? this.photoStoragePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      previousSyncStatus: previousSyncStatus ?? this.previousSyncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (heightInCentimeters.present) {
      map['height_in_centimeters'] = Variable<int>(heightInCentimeters.value);
    }
    if (initialWeight.present) {
      map['initial_weight'] = Variable<double>(initialWeight.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (surgeryDate.present) {
      map['surgery_date'] = Variable<DateTime>(surgeryDate.value);
    }
    if (surgeryType.present) {
      map['surgery_type'] = Variable<String>(surgeryType.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (photoStoragePath.present) {
      map['photo_storage_path'] = Variable<String>(photoStoragePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (previousSyncStatus.present) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightInCentimeters: $heightInCentimeters, ')
          ..write('initialWeight: $initialWeight, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('surgeryDate: $surgeryDate, ')
          ..write('surgeryType: $surgeryType, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoStoragePath: $photoStoragePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileCutoversTable extends ProfileCutovers
    with TableInfo<$ProfileCutoversTable, ProfileCutover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileCutoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseSchemaVersionMeta =
      const VerificationMeta('databaseSchemaVersion');
  @override
  late final GeneratedColumn<int> databaseSchemaVersion = GeneratedColumn<int>(
    'database_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_cutovers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileCutover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('database_schema_version')) {
      context.handle(
        _databaseSchemaVersionMeta,
        databaseSchemaVersion.isAcceptableOrUnknown(
          data['database_schema_version']!,
          _databaseSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_databaseSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, userId};
  @override
  ProfileCutover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileCutover(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      databaseSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}database_schema_version'],
      )!,
    );
  }

  @override
  $ProfileCutoversTable createAlias(String alias) {
    return $ProfileCutoversTable(attachedDatabase, alias);
  }
}

class ProfileCutover extends DataClass implements Insertable<ProfileCutover> {
  final String migrationKey;
  final int version;
  final String userId;
  final DateTime completedAt;
  final String checksum;
  final int recordCount;
  final int databaseSchemaVersion;
  const ProfileCutover({
    required this.migrationKey,
    required this.version,
    required this.userId,
    required this.completedAt,
    required this.checksum,
    required this.recordCount,
    required this.databaseSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['version'] = Variable<int>(version);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['checksum'] = Variable<String>(checksum);
    map['record_count'] = Variable<int>(recordCount);
    map['database_schema_version'] = Variable<int>(databaseSchemaVersion);
    return map;
  }

  ProfileCutoversCompanion toCompanion(bool nullToAbsent) {
    return ProfileCutoversCompanion(
      migrationKey: Value(migrationKey),
      version: Value(version),
      userId: Value(userId),
      completedAt: Value(completedAt),
      checksum: Value(checksum),
      recordCount: Value(recordCount),
      databaseSchemaVersion: Value(databaseSchemaVersion),
    );
  }

  factory ProfileCutover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileCutover(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      version: serializer.fromJson<int>(json['version']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      databaseSchemaVersion: serializer.fromJson<int>(
        json['databaseSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'version': serializer.toJson<int>(version),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'checksum': serializer.toJson<String>(checksum),
      'recordCount': serializer.toJson<int>(recordCount),
      'databaseSchemaVersion': serializer.toJson<int>(databaseSchemaVersion),
    };
  }

  ProfileCutover copyWith({
    String? migrationKey,
    int? version,
    String? userId,
    DateTime? completedAt,
    String? checksum,
    int? recordCount,
    int? databaseSchemaVersion,
  }) => ProfileCutover(
    migrationKey: migrationKey ?? this.migrationKey,
    version: version ?? this.version,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    checksum: checksum ?? this.checksum,
    recordCount: recordCount ?? this.recordCount,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
  );
  ProfileCutover copyWithCompanion(ProfileCutoversCompanion data) {
    return ProfileCutover(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      version: data.version.present ? data.version.value : this.version,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      databaseSchemaVersion: data.databaseSchemaVersion.present
          ? data.databaseSchemaVersion.value
          : this.databaseSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCutover(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileCutover &&
          other.migrationKey == this.migrationKey &&
          other.version == this.version &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.checksum == this.checksum &&
          other.recordCount == this.recordCount &&
          other.databaseSchemaVersion == this.databaseSchemaVersion);
}

class ProfileCutoversCompanion extends UpdateCompanion<ProfileCutover> {
  final Value<String> migrationKey;
  final Value<int> version;
  final Value<String> userId;
  final Value<DateTime> completedAt;
  final Value<String> checksum;
  final Value<int> recordCount;
  final Value<int> databaseSchemaVersion;
  final Value<int> rowid;
  const ProfileCutoversCompanion({
    this.migrationKey = const Value.absent(),
    this.version = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.databaseSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileCutoversCompanion.insert({
    required String migrationKey,
    required int version,
    required String userId,
    required DateTime completedAt,
    required String checksum,
    required int recordCount,
    required int databaseSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       version = Value(version),
       userId = Value(userId),
       completedAt = Value(completedAt),
       checksum = Value(checksum),
       recordCount = Value(recordCount),
       databaseSchemaVersion = Value(databaseSchemaVersion);
  static Insertable<ProfileCutover> custom({
    Expression<String>? migrationKey,
    Expression<int>? version,
    Expression<String>? userId,
    Expression<DateTime>? completedAt,
    Expression<String>? checksum,
    Expression<int>? recordCount,
    Expression<int>? databaseSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (version != null) 'version': version,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (checksum != null) 'checksum': checksum,
      if (recordCount != null) 'record_count': recordCount,
      if (databaseSchemaVersion != null)
        'database_schema_version': databaseSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileCutoversCompanion copyWith({
    Value<String>? migrationKey,
    Value<int>? version,
    Value<String>? userId,
    Value<DateTime>? completedAt,
    Value<String>? checksum,
    Value<int>? recordCount,
    Value<int>? databaseSchemaVersion,
    Value<int>? rowid,
  }) {
    return ProfileCutoversCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      databaseSchemaVersion:
          databaseSchemaVersion ?? this.databaseSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (databaseSchemaVersion.present) {
      map['database_schema_version'] = Variable<int>(
        databaseSchemaVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCutoversCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightRecordsTable extends WeightRecords
    with TableInfo<$WeightRecordsTable, WeightRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (weight_kg > 0)',
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousSyncStatusMeta =
      const VerificationMeta('previousSyncStatus');
  @override
  late final GeneratedColumn<String> previousSyncStatus =
      GeneratedColumn<String>(
        'previous_sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    weightKg,
    recordedAt,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('previous_sync_status')) {
      context.handle(
        _previousSyncStatusMeta,
        previousSyncStatus.isAcceptableOrUnknown(
          data['previous_sync_status']!,
          _previousSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, id};
  @override
  WeightRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      previousSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_sync_status'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $WeightRecordsTable createAlias(String alias) {
    return $WeightRecordsTable(attachedDatabase, alias);
  }
}

class WeightRecord extends DataClass implements Insertable<WeightRecord> {
  final String id;
  final String userId;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  const WeightRecord({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.previousSyncStatus,
    required this.syncAttempts,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['weight_kg'] = Variable<double>(weightKg);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || previousSyncStatus != null) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  WeightRecordsCompanion toCompanion(bool nullToAbsent) {
    return WeightRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      weightKg: Value(weightKg),
      recordedAt: Value(recordedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      previousSyncStatus: previousSyncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSyncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory WeightRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      previousSyncStatus: serializer.fromJson<String?>(
        json['previousSyncStatus'],
      ),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'weightKg': serializer.toJson<double>(weightKg),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'previousSyncStatus': serializer.toJson<String?>(previousSyncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  WeightRecord copyWith({
    String? id,
    String? userId,
    double? weightKg,
    DateTime? recordedAt,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
    Value<String?> previousSyncStatus = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
  }) => WeightRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    weightKg: weightKg ?? this.weightKg,
    recordedAt: recordedAt ?? this.recordedAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus.value
        : this.previousSyncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  WeightRecord copyWithCompanion(WeightRecordsCompanion data) {
    return WeightRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      previousSyncStatus: data.previousSyncStatus.present
          ? data.previousSyncStatus.value
          : this.previousSyncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    weightKg,
    recordedAt,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.weightKg == this.weightKg &&
          other.recordedAt == this.recordedAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.previousSyncStatus == this.previousSyncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError);
}

class WeightRecordsCompanion extends UpdateCompanion<WeightRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<double> weightKg;
  final Value<DateTime> recordedAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> previousSyncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const WeightRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightRecordsCompanion.insert({
    required String id,
    required String userId,
    required double weightKg,
    required DateTime recordedAt,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String syncStatus,
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       weightKg = Value(weightKg),
       recordedAt = Value(recordedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<WeightRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<double>? weightKg,
    Expression<DateTime>? recordedAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? previousSyncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (weightKg != null) 'weight_kg': weightKg,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (previousSyncStatus != null)
        'previous_sync_status': previousSyncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<double>? weightKg,
    Value<DateTime>? recordedAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<String?>? previousSyncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return WeightRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      previousSyncStatus: previousSyncStatus ?? this.previousSyncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (previousSyncStatus.present) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightCutoversTable extends WeightCutovers
    with TableInfo<$WeightCutoversTable, WeightCutover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightCutoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseSchemaVersionMeta =
      const VerificationMeta('databaseSchemaVersion');
  @override
  late final GeneratedColumn<int> databaseSchemaVersion = GeneratedColumn<int>(
    'database_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_cutovers';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightCutover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('database_schema_version')) {
      context.handle(
        _databaseSchemaVersionMeta,
        databaseSchemaVersion.isAcceptableOrUnknown(
          data['database_schema_version']!,
          _databaseSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_databaseSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, userId};
  @override
  WeightCutover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightCutover(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      databaseSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}database_schema_version'],
      )!,
    );
  }

  @override
  $WeightCutoversTable createAlias(String alias) {
    return $WeightCutoversTable(attachedDatabase, alias);
  }
}

class WeightCutover extends DataClass implements Insertable<WeightCutover> {
  final String migrationKey;
  final int version;
  final String userId;
  final DateTime completedAt;
  final String checksum;
  final int recordCount;
  final int databaseSchemaVersion;
  const WeightCutover({
    required this.migrationKey,
    required this.version,
    required this.userId,
    required this.completedAt,
    required this.checksum,
    required this.recordCount,
    required this.databaseSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['version'] = Variable<int>(version);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['checksum'] = Variable<String>(checksum);
    map['record_count'] = Variable<int>(recordCount);
    map['database_schema_version'] = Variable<int>(databaseSchemaVersion);
    return map;
  }

  WeightCutoversCompanion toCompanion(bool nullToAbsent) {
    return WeightCutoversCompanion(
      migrationKey: Value(migrationKey),
      version: Value(version),
      userId: Value(userId),
      completedAt: Value(completedAt),
      checksum: Value(checksum),
      recordCount: Value(recordCount),
      databaseSchemaVersion: Value(databaseSchemaVersion),
    );
  }

  factory WeightCutover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightCutover(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      version: serializer.fromJson<int>(json['version']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      databaseSchemaVersion: serializer.fromJson<int>(
        json['databaseSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'version': serializer.toJson<int>(version),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'checksum': serializer.toJson<String>(checksum),
      'recordCount': serializer.toJson<int>(recordCount),
      'databaseSchemaVersion': serializer.toJson<int>(databaseSchemaVersion),
    };
  }

  WeightCutover copyWith({
    String? migrationKey,
    int? version,
    String? userId,
    DateTime? completedAt,
    String? checksum,
    int? recordCount,
    int? databaseSchemaVersion,
  }) => WeightCutover(
    migrationKey: migrationKey ?? this.migrationKey,
    version: version ?? this.version,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    checksum: checksum ?? this.checksum,
    recordCount: recordCount ?? this.recordCount,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
  );
  WeightCutover copyWithCompanion(WeightCutoversCompanion data) {
    return WeightCutover(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      version: data.version.present ? data.version.value : this.version,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      databaseSchemaVersion: data.databaseSchemaVersion.present
          ? data.databaseSchemaVersion.value
          : this.databaseSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightCutover(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightCutover &&
          other.migrationKey == this.migrationKey &&
          other.version == this.version &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.checksum == this.checksum &&
          other.recordCount == this.recordCount &&
          other.databaseSchemaVersion == this.databaseSchemaVersion);
}

class WeightCutoversCompanion extends UpdateCompanion<WeightCutover> {
  final Value<String> migrationKey;
  final Value<int> version;
  final Value<String> userId;
  final Value<DateTime> completedAt;
  final Value<String> checksum;
  final Value<int> recordCount;
  final Value<int> databaseSchemaVersion;
  final Value<int> rowid;
  const WeightCutoversCompanion({
    this.migrationKey = const Value.absent(),
    this.version = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.databaseSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightCutoversCompanion.insert({
    required String migrationKey,
    required int version,
    required String userId,
    required DateTime completedAt,
    required String checksum,
    required int recordCount,
    required int databaseSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       version = Value(version),
       userId = Value(userId),
       completedAt = Value(completedAt),
       checksum = Value(checksum),
       recordCount = Value(recordCount),
       databaseSchemaVersion = Value(databaseSchemaVersion);
  static Insertable<WeightCutover> custom({
    Expression<String>? migrationKey,
    Expression<int>? version,
    Expression<String>? userId,
    Expression<DateTime>? completedAt,
    Expression<String>? checksum,
    Expression<int>? recordCount,
    Expression<int>? databaseSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (version != null) 'version': version,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (checksum != null) 'checksum': checksum,
      if (recordCount != null) 'record_count': recordCount,
      if (databaseSchemaVersion != null)
        'database_schema_version': databaseSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightCutoversCompanion copyWith({
    Value<String>? migrationKey,
    Value<int>? version,
    Value<String>? userId,
    Value<DateTime>? completedAt,
    Value<String>? checksum,
    Value<int>? recordCount,
    Value<int>? databaseSchemaVersion,
    Value<int>? rowid,
  }) {
    return WeightCutoversCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      databaseSchemaVersion:
          databaseSchemaVersion ?? this.databaseSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (databaseSchemaVersion.present) {
      map['database_schema_version'] = Variable<int>(
        databaseSchemaVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightCutoversCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealRecordsTable extends MealRecords
    with TableInfo<$MealRecordsTable, MealRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealDateMeta = const VerificationMeta(
    'mealDate',
  );
  @override
  late final GeneratedColumn<DateTime> mealDate = GeneratedColumn<DateTime>(
    'meal_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGramsMeta = const VerificationMeta(
    'proteinGrams',
  );
  @override
  late final GeneratedColumn<int> proteinGrams = GeneratedColumn<int>(
    'protein_grams',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (protein_grams IS NULL OR protein_grams >= 0)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousSyncStatusMeta =
      const VerificationMeta('previousSyncStatus');
  @override
  late final GeneratedColumn<String> previousSyncStatus =
      GeneratedColumn<String>(
        'previous_sync_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    type,
    mealDate,
    notes,
    proteinGrams,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('meal_date')) {
      context.handle(
        _mealDateMeta,
        mealDate.isAcceptableOrUnknown(data['meal_date']!, _mealDateMeta),
      );
    } else if (isInserting) {
      context.missing(_mealDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
        _proteinGramsMeta,
        proteinGrams.isAcceptableOrUnknown(
          data['protein_grams']!,
          _proteinGramsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('previous_sync_status')) {
      context.handle(
        _previousSyncStatusMeta,
        previousSyncStatus.isAcceptableOrUnknown(
          data['previous_sync_status']!,
          _previousSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, id};
  @override
  MealRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      mealDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}meal_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      proteinGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_grams'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      previousSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_sync_status'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $MealRecordsTable createAlias(String alias) {
    return $MealRecordsTable(attachedDatabase, alias);
  }
}

class MealRecord extends DataClass implements Insertable<MealRecord> {
  final String id;
  final String userId;
  final String name;
  final String type;
  final DateTime mealDate;
  final String? notes;
  final int? proteinGrams;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  const MealRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.mealDate,
    this.notes,
    this.proteinGrams,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.previousSyncStatus,
    required this.syncAttempts,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['meal_date'] = Variable<DateTime>(mealDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || proteinGrams != null) {
      map['protein_grams'] = Variable<int>(proteinGrams);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || previousSyncStatus != null) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  MealRecordsCompanion toCompanion(bool nullToAbsent) {
    return MealRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      mealDate: Value(mealDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      proteinGrams: proteinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinGrams),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      previousSyncStatus: previousSyncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSyncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory MealRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      mealDate: serializer.fromJson<DateTime>(json['mealDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      proteinGrams: serializer.fromJson<int?>(json['proteinGrams']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      previousSyncStatus: serializer.fromJson<String?>(
        json['previousSyncStatus'],
      ),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'mealDate': serializer.toJson<DateTime>(mealDate),
      'notes': serializer.toJson<String?>(notes),
      'proteinGrams': serializer.toJson<int?>(proteinGrams),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'previousSyncStatus': serializer.toJson<String?>(previousSyncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  MealRecord copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    DateTime? mealDate,
    Value<String?> notes = const Value.absent(),
    Value<int?> proteinGrams = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
    Value<String?> previousSyncStatus = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
  }) => MealRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    mealDate: mealDate ?? this.mealDate,
    notes: notes.present ? notes.value : this.notes,
    proteinGrams: proteinGrams.present ? proteinGrams.value : this.proteinGrams,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus.value
        : this.previousSyncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  MealRecord copyWithCompanion(MealRecordsCompanion data) {
    return MealRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      mealDate: data.mealDate.present ? data.mealDate.value : this.mealDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      previousSyncStatus: data.previousSyncStatus.present
          ? data.previousSyncStatus.value
          : this.previousSyncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('mealDate: $mealDate, ')
          ..write('notes: $notes, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    type,
    mealDate,
    notes,
    proteinGrams,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    previousSyncStatus,
    syncAttempts,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.mealDate == this.mealDate &&
          other.notes == this.notes &&
          other.proteinGrams == this.proteinGrams &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.previousSyncStatus == this.previousSyncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError);
}

class MealRecordsCompanion extends UpdateCompanion<MealRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<DateTime> mealDate;
  final Value<String?> notes;
  final Value<int?> proteinGrams;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> previousSyncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const MealRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.mealDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealRecordsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    required DateTime mealDate,
    this.notes = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String syncStatus,
    this.previousSyncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       type = Value(type),
       mealDate = Value(mealDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<MealRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? mealDate,
    Expression<String>? notes,
    Expression<int>? proteinGrams,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? previousSyncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (mealDate != null) 'meal_date': mealDate,
      if (notes != null) 'notes': notes,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (previousSyncStatus != null)
        'previous_sync_status': previousSyncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? type,
    Value<DateTime>? mealDate,
    Value<String?>? notes,
    Value<int?>? proteinGrams,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<String?>? previousSyncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return MealRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      mealDate: mealDate ?? this.mealDate,
      notes: notes ?? this.notes,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      previousSyncStatus: previousSyncStatus ?? this.previousSyncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mealDate.present) {
      map['meal_date'] = Variable<DateTime>(mealDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<int>(proteinGrams.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (previousSyncStatus.present) {
      map['previous_sync_status'] = Variable<String>(previousSyncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('mealDate: $mealDate, ')
          ..write('notes: $notes, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('previousSyncStatus: $previousSyncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealCutoversTable extends MealCutovers
    with TableInfo<$MealCutoversTable, MealCutover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealCutoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseSchemaVersionMeta =
      const VerificationMeta('databaseSchemaVersion');
  @override
  late final GeneratedColumn<int> databaseSchemaVersion = GeneratedColumn<int>(
    'database_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_cutovers';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealCutover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('database_schema_version')) {
      context.handle(
        _databaseSchemaVersionMeta,
        databaseSchemaVersion.isAcceptableOrUnknown(
          data['database_schema_version']!,
          _databaseSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_databaseSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, userId};
  @override
  MealCutover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealCutover(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      databaseSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}database_schema_version'],
      )!,
    );
  }

  @override
  $MealCutoversTable createAlias(String alias) {
    return $MealCutoversTable(attachedDatabase, alias);
  }
}

class MealCutover extends DataClass implements Insertable<MealCutover> {
  final String migrationKey;
  final int version;
  final String userId;
  final DateTime completedAt;
  final String checksum;
  final int recordCount;
  final int databaseSchemaVersion;
  const MealCutover({
    required this.migrationKey,
    required this.version,
    required this.userId,
    required this.completedAt,
    required this.checksum,
    required this.recordCount,
    required this.databaseSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['version'] = Variable<int>(version);
    map['user_id'] = Variable<String>(userId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['checksum'] = Variable<String>(checksum);
    map['record_count'] = Variable<int>(recordCount);
    map['database_schema_version'] = Variable<int>(databaseSchemaVersion);
    return map;
  }

  MealCutoversCompanion toCompanion(bool nullToAbsent) {
    return MealCutoversCompanion(
      migrationKey: Value(migrationKey),
      version: Value(version),
      userId: Value(userId),
      completedAt: Value(completedAt),
      checksum: Value(checksum),
      recordCount: Value(recordCount),
      databaseSchemaVersion: Value(databaseSchemaVersion),
    );
  }

  factory MealCutover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealCutover(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      version: serializer.fromJson<int>(json['version']),
      userId: serializer.fromJson<String>(json['userId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      databaseSchemaVersion: serializer.fromJson<int>(
        json['databaseSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'version': serializer.toJson<int>(version),
      'userId': serializer.toJson<String>(userId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'checksum': serializer.toJson<String>(checksum),
      'recordCount': serializer.toJson<int>(recordCount),
      'databaseSchemaVersion': serializer.toJson<int>(databaseSchemaVersion),
    };
  }

  MealCutover copyWith({
    String? migrationKey,
    int? version,
    String? userId,
    DateTime? completedAt,
    String? checksum,
    int? recordCount,
    int? databaseSchemaVersion,
  }) => MealCutover(
    migrationKey: migrationKey ?? this.migrationKey,
    version: version ?? this.version,
    userId: userId ?? this.userId,
    completedAt: completedAt ?? this.completedAt,
    checksum: checksum ?? this.checksum,
    recordCount: recordCount ?? this.recordCount,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
  );
  MealCutover copyWithCompanion(MealCutoversCompanion data) {
    return MealCutover(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      version: data.version.present ? data.version.value : this.version,
      userId: data.userId.present ? data.userId.value : this.userId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      databaseSchemaVersion: data.databaseSchemaVersion.present
          ? data.databaseSchemaVersion.value
          : this.databaseSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealCutover(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    version,
    userId,
    completedAt,
    checksum,
    recordCount,
    databaseSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealCutover &&
          other.migrationKey == this.migrationKey &&
          other.version == this.version &&
          other.userId == this.userId &&
          other.completedAt == this.completedAt &&
          other.checksum == this.checksum &&
          other.recordCount == this.recordCount &&
          other.databaseSchemaVersion == this.databaseSchemaVersion);
}

class MealCutoversCompanion extends UpdateCompanion<MealCutover> {
  final Value<String> migrationKey;
  final Value<int> version;
  final Value<String> userId;
  final Value<DateTime> completedAt;
  final Value<String> checksum;
  final Value<int> recordCount;
  final Value<int> databaseSchemaVersion;
  final Value<int> rowid;
  const MealCutoversCompanion({
    this.migrationKey = const Value.absent(),
    this.version = const Value.absent(),
    this.userId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.databaseSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealCutoversCompanion.insert({
    required String migrationKey,
    required int version,
    required String userId,
    required DateTime completedAt,
    required String checksum,
    required int recordCount,
    required int databaseSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       version = Value(version),
       userId = Value(userId),
       completedAt = Value(completedAt),
       checksum = Value(checksum),
       recordCount = Value(recordCount),
       databaseSchemaVersion = Value(databaseSchemaVersion);
  static Insertable<MealCutover> custom({
    Expression<String>? migrationKey,
    Expression<int>? version,
    Expression<String>? userId,
    Expression<DateTime>? completedAt,
    Expression<String>? checksum,
    Expression<int>? recordCount,
    Expression<int>? databaseSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (version != null) 'version': version,
      if (userId != null) 'user_id': userId,
      if (completedAt != null) 'completed_at': completedAt,
      if (checksum != null) 'checksum': checksum,
      if (recordCount != null) 'record_count': recordCount,
      if (databaseSchemaVersion != null)
        'database_schema_version': databaseSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealCutoversCompanion copyWith({
    Value<String>? migrationKey,
    Value<int>? version,
    Value<String>? userId,
    Value<DateTime>? completedAt,
    Value<String>? checksum,
    Value<int>? recordCount,
    Value<int>? databaseSchemaVersion,
    Value<int>? rowid,
  }) {
    return MealCutoversCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      checksum: checksum ?? this.checksum,
      recordCount: recordCount ?? this.recordCount,
      databaseSchemaVersion:
          databaseSchemaVersion ?? this.databaseSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (databaseSchemaVersion.present) {
      map['database_schema_version'] = Variable<int>(
        databaseSchemaVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealCutoversCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('version: $version, ')
          ..write('userId: $userId, ')
          ..write('completedAt: $completedAt, ')
          ..write('checksum: $checksum, ')
          ..write('recordCount: $recordCount, ')
          ..write('databaseSchemaVersion: $databaseSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WaterRecordsTable waterRecords = $WaterRecordsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $SyncDevicesTable syncDevices = $SyncDevicesTable(this);
  late final $LocalMigrationsTable localMigrations = $LocalMigrationsTable(
    this,
  );
  late final $WaterCutoversTable waterCutovers = $WaterCutoversTable(this);
  late final $SettingsRecordsTable settingsRecords = $SettingsRecordsTable(
    this,
  );
  late final $SettingsCutoversTable settingsCutovers = $SettingsCutoversTable(
    this,
  );
  late final $ProfileRecordsTable profileRecords = $ProfileRecordsTable(this);
  late final $ProfileCutoversTable profileCutovers = $ProfileCutoversTable(
    this,
  );
  late final $WeightRecordsTable weightRecords = $WeightRecordsTable(this);
  late final $WeightCutoversTable weightCutovers = $WeightCutoversTable(this);
  late final $MealRecordsTable mealRecords = $MealRecordsTable(this);
  late final $MealCutoversTable mealCutovers = $MealCutoversTable(this);
  late final Index waterUserDeletedRecordedIdx = Index(
    'water_user_deleted_recorded_idx',
    'CREATE INDEX water_user_deleted_recorded_idx ON water_records (user_id, deleted_at, recorded_at)',
  );
  late final Index waterUserSyncUpdatedIdx = Index(
    'water_user_sync_updated_idx',
    'CREATE INDEX water_user_sync_updated_idx ON water_records (user_id, sync_status, updated_at)',
  );
  late final Index settingsUserUniqueIdx = Index(
    'settings_user_unique_idx',
    'CREATE UNIQUE INDEX settings_user_unique_idx ON settings_records (user_id)',
  );
  late final Index settingsUserSyncUpdatedIdx = Index(
    'settings_user_sync_updated_idx',
    'CREATE INDEX settings_user_sync_updated_idx ON settings_records (user_id, sync_status, updated_at)',
  );
  late final Index profileUserUniqueIdx = Index(
    'profile_user_unique_idx',
    'CREATE UNIQUE INDEX profile_user_unique_idx ON profile_records (user_id)',
  );
  late final Index profileUserSyncUpdatedIdx = Index(
    'profile_user_sync_updated_idx',
    'CREATE INDEX profile_user_sync_updated_idx ON profile_records (user_id, sync_status, updated_at)',
  );
  late final Index weightUserDeletedRecordedIdx = Index(
    'weight_user_deleted_recorded_idx',
    'CREATE INDEX weight_user_deleted_recorded_idx ON weight_records (user_id, deleted_at, recorded_at)',
  );
  late final Index weightUserSyncUpdatedIdx = Index(
    'weight_user_sync_updated_idx',
    'CREATE INDEX weight_user_sync_updated_idx ON weight_records (user_id, sync_status, updated_at)',
  );
  late final Index mealUserDeletedDateIdx = Index(
    'meal_user_deleted_date_idx',
    'CREATE INDEX meal_user_deleted_date_idx ON meal_records (user_id, deleted_at, meal_date)',
  );
  late final Index mealUserTypeDateIdx = Index(
    'meal_user_type_date_idx',
    'CREATE INDEX meal_user_type_date_idx ON meal_records (user_id, type, meal_date)',
  );
  late final Index mealUserSyncUpdatedIdx = Index(
    'meal_user_sync_updated_idx',
    'CREATE INDEX meal_user_sync_updated_idx ON meal_records (user_id, sync_status, updated_at)',
  );
  late final WaterDao waterDao = WaterDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final WeightDao weightDao = WeightDao(this as AppDatabase);
  late final MealDao mealDao = MealDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    waterRecords,
    syncCursors,
    syncDevices,
    localMigrations,
    waterCutovers,
    settingsRecords,
    settingsCutovers,
    profileRecords,
    profileCutovers,
    weightRecords,
    weightCutovers,
    mealRecords,
    mealCutovers,
    waterUserDeletedRecordedIdx,
    waterUserSyncUpdatedIdx,
    settingsUserUniqueIdx,
    settingsUserSyncUpdatedIdx,
    profileUserUniqueIdx,
    profileUserSyncUpdatedIdx,
    weightUserDeletedRecordedIdx,
    weightUserSyncUpdatedIdx,
    mealUserDeletedDateIdx,
    mealUserTypeDateIdx,
    mealUserSyncUpdatedIdx,
  ];
}

typedef $$WaterRecordsTableCreateCompanionBuilder =
    WaterRecordsCompanion Function({
      required String id,
      required String userId,
      required int amountMl,
      required DateTime recordedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$WaterRecordsTableUpdateCompanionBuilder =
    WaterRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> amountMl,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$WaterRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterRecordsTable> {
  $$WaterRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterRecordsTable> {
  $$WaterRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterRecordsTable> {
  $$WaterRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$WaterRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterRecordsTable,
          WaterRecord,
          $$WaterRecordsTableFilterComposer,
          $$WaterRecordsTableOrderingComposer,
          $$WaterRecordsTableAnnotationComposer,
          $$WaterRecordsTableCreateCompanionBuilder,
          $$WaterRecordsTableUpdateCompanionBuilder,
          (
            WaterRecord,
            BaseReferences<_$AppDatabase, $WaterRecordsTable, WaterRecord>,
          ),
          WaterRecord,
          PrefetchHooks Function()
        > {
  $$WaterRecordsTableTableManager(_$AppDatabase db, $WaterRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterRecordsCompanion(
                id: id,
                userId: userId,
                amountMl: amountMl,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int amountMl,
                required DateTime recordedAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncStatus,
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterRecordsCompanion.insert(
                id: id,
                userId: userId,
                amountMl: amountMl,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterRecordsTable,
      WaterRecord,
      $$WaterRecordsTableFilterComposer,
      $$WaterRecordsTableOrderingComposer,
      $$WaterRecordsTableAnnotationComposer,
      $$WaterRecordsTableCreateCompanionBuilder,
      $$WaterRecordsTableUpdateCompanionBuilder,
      (
        WaterRecord,
        BaseReferences<_$AppDatabase, $WaterRecordsTable, WaterRecord>,
      ),
      WaterRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String userId,
      required String repositoryKey,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastSyncAt,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> userId,
      Value<String> repositoryKey,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastSyncAt,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repositoryKey => $composableBuilder(
    column: $table.repositoryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repositoryKey => $composableBuilder(
    column: $table.repositoryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get repositoryKey => $composableBuilder(
    column: $table.repositoryKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> repositoryKey = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                userId: userId,
                repositoryKey: repositoryKey,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                lastSyncAt: lastSyncAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String repositoryKey,
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                userId: userId,
                repositoryKey: repositoryKey,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                lastSyncAt: lastSyncAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$SyncDevicesTableCreateCompanionBuilder =
    SyncDevicesCompanion Function({
      required String deviceId,
      required String appVersion,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncDevicesTableUpdateCompanionBuilder =
    SyncDevicesCompanion Function({
      Value<String> deviceId,
      Value<String> appVersion,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncDevicesTable,
          SyncDevice,
          $$SyncDevicesTableFilterComposer,
          $$SyncDevicesTableOrderingComposer,
          $$SyncDevicesTableAnnotationComposer,
          $$SyncDevicesTableCreateCompanionBuilder,
          $$SyncDevicesTableUpdateCompanionBuilder,
          (
            SyncDevice,
            BaseReferences<_$AppDatabase, $SyncDevicesTable, SyncDevice>,
          ),
          SyncDevice,
          PrefetchHooks Function()
        > {
  $$SyncDevicesTableTableManager(_$AppDatabase db, $SyncDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncDevicesCompanion(
                deviceId: deviceId,
                appVersion: appVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String appVersion,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncDevicesCompanion.insert(
                deviceId: deviceId,
                appVersion: appVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncDevicesTable,
      SyncDevice,
      $$SyncDevicesTableFilterComposer,
      $$SyncDevicesTableOrderingComposer,
      $$SyncDevicesTableAnnotationComposer,
      $$SyncDevicesTableCreateCompanionBuilder,
      $$SyncDevicesTableUpdateCompanionBuilder,
      (
        SyncDevice,
        BaseReferences<_$AppDatabase, $SyncDevicesTable, SyncDevice>,
      ),
      SyncDevice,
      PrefetchHooks Function()
    >;
typedef $$LocalMigrationsTableCreateCompanionBuilder =
    LocalMigrationsCompanion Function({
      required String migrationKey,
      required DateTime completedAt,
      Value<String?> sourceChecksum,
      Value<int> importedCount,
      Value<int> rowid,
    });
typedef $$LocalMigrationsTableUpdateCompanionBuilder =
    LocalMigrationsCompanion Function({
      Value<String> migrationKey,
      Value<DateTime> completedAt,
      Value<String?> sourceChecksum,
      Value<int> importedCount,
      Value<int> rowid,
    });

class $$LocalMigrationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMigrationsTable> {
  $$LocalMigrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedCount => $composableBuilder(
    column: $table.importedCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMigrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMigrationsTable> {
  $$LocalMigrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedCount => $composableBuilder(
    column: $table.importedCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMigrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMigrationsTable> {
  $$LocalMigrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importedCount => $composableBuilder(
    column: $table.importedCount,
    builder: (column) => column,
  );
}

class $$LocalMigrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMigrationsTable,
          LocalMigration,
          $$LocalMigrationsTableFilterComposer,
          $$LocalMigrationsTableOrderingComposer,
          $$LocalMigrationsTableAnnotationComposer,
          $$LocalMigrationsTableCreateCompanionBuilder,
          $$LocalMigrationsTableUpdateCompanionBuilder,
          (
            LocalMigration,
            BaseReferences<
              _$AppDatabase,
              $LocalMigrationsTable,
              LocalMigration
            >,
          ),
          LocalMigration,
          PrefetchHooks Function()
        > {
  $$LocalMigrationsTableTableManager(
    _$AppDatabase db,
    $LocalMigrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMigrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMigrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMigrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String?> sourceChecksum = const Value.absent(),
                Value<int> importedCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMigrationsCompanion(
                migrationKey: migrationKey,
                completedAt: completedAt,
                sourceChecksum: sourceChecksum,
                importedCount: importedCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required DateTime completedAt,
                Value<String?> sourceChecksum = const Value.absent(),
                Value<int> importedCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMigrationsCompanion.insert(
                migrationKey: migrationKey,
                completedAt: completedAt,
                sourceChecksum: sourceChecksum,
                importedCount: importedCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMigrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMigrationsTable,
      LocalMigration,
      $$LocalMigrationsTableFilterComposer,
      $$LocalMigrationsTableOrderingComposer,
      $$LocalMigrationsTableAnnotationComposer,
      $$LocalMigrationsTableCreateCompanionBuilder,
      $$LocalMigrationsTableUpdateCompanionBuilder,
      (
        LocalMigration,
        BaseReferences<_$AppDatabase, $LocalMigrationsTable, LocalMigration>,
      ),
      LocalMigration,
      PrefetchHooks Function()
    >;
typedef $$WaterCutoversTableCreateCompanionBuilder =
    WaterCutoversCompanion Function({
      required String migrationKey,
      required int version,
      required String userId,
      required DateTime completedAt,
      required String checksum,
      required int recordCount,
      required int databaseSchemaVersion,
      Value<int> rowid,
    });
typedef $$WaterCutoversTableUpdateCompanionBuilder =
    WaterCutoversCompanion Function({
      Value<String> migrationKey,
      Value<int> version,
      Value<String> userId,
      Value<DateTime> completedAt,
      Value<String> checksum,
      Value<int> recordCount,
      Value<int> databaseSchemaVersion,
      Value<int> rowid,
    });

class $$WaterCutoversTableFilterComposer
    extends Composer<_$AppDatabase, $WaterCutoversTable> {
  $$WaterCutoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterCutoversTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterCutoversTable> {
  $$WaterCutoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterCutoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterCutoversTable> {
  $$WaterCutoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => column,
  );
}

class $$WaterCutoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterCutoversTable,
          WaterCutover,
          $$WaterCutoversTableFilterComposer,
          $$WaterCutoversTableOrderingComposer,
          $$WaterCutoversTableAnnotationComposer,
          $$WaterCutoversTableCreateCompanionBuilder,
          $$WaterCutoversTableUpdateCompanionBuilder,
          (
            WaterCutover,
            BaseReferences<_$AppDatabase, $WaterCutoversTable, WaterCutover>,
          ),
          WaterCutover,
          PrefetchHooks Function()
        > {
  $$WaterCutoversTableTableManager(_$AppDatabase db, $WaterCutoversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterCutoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterCutoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterCutoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> databaseSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterCutoversCompanion(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required int version,
                required String userId,
                required DateTime completedAt,
                required String checksum,
                required int recordCount,
                required int databaseSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => WaterCutoversCompanion.insert(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterCutoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterCutoversTable,
      WaterCutover,
      $$WaterCutoversTableFilterComposer,
      $$WaterCutoversTableOrderingComposer,
      $$WaterCutoversTableAnnotationComposer,
      $$WaterCutoversTableCreateCompanionBuilder,
      $$WaterCutoversTableUpdateCompanionBuilder,
      (
        WaterCutover,
        BaseReferences<_$AppDatabase, $WaterCutoversTable, WaterCutover>,
      ),
      WaterCutover,
      PrefetchHooks Function()
    >;
typedef $$SettingsRecordsTableCreateCompanionBuilder =
    SettingsRecordsCompanion Function({
      required String id,
      required String userId,
      Value<int> dailyWaterGoalMl,
      Value<bool> vitaminRemindersEnabled,
      Value<bool> medicationRemindersEnabled,
      Value<bool> appointmentRemindersEnabled,
      Value<bool> mealTrackingEnabled,
      Value<String> weightUnit,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$SettingsRecordsTableUpdateCompanionBuilder =
    SettingsRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> dailyWaterGoalMl,
      Value<bool> vitaminRemindersEnabled,
      Value<bool> medicationRemindersEnabled,
      Value<bool> appointmentRemindersEnabled,
      Value<bool> mealTrackingEnabled,
      Value<String> weightUnit,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$SettingsRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRecordsTable> {
  $$SettingsRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyWaterGoalMl => $composableBuilder(
    column: $table.dailyWaterGoalMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vitaminRemindersEnabled => $composableBuilder(
    column: $table.vitaminRemindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get medicationRemindersEnabled => $composableBuilder(
    column: $table.medicationRemindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appointmentRemindersEnabled => $composableBuilder(
    column: $table.appointmentRemindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mealTrackingEnabled => $composableBuilder(
    column: $table.mealTrackingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRecordsTable> {
  $$SettingsRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyWaterGoalMl => $composableBuilder(
    column: $table.dailyWaterGoalMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vitaminRemindersEnabled => $composableBuilder(
    column: $table.vitaminRemindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get medicationRemindersEnabled => $composableBuilder(
    column: $table.medicationRemindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appointmentRemindersEnabled => $composableBuilder(
    column: $table.appointmentRemindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mealTrackingEnabled => $composableBuilder(
    column: $table.mealTrackingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRecordsTable> {
  $$SettingsRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get dailyWaterGoalMl => $composableBuilder(
    column: $table.dailyWaterGoalMl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vitaminRemindersEnabled => $composableBuilder(
    column: $table.vitaminRemindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get medicationRemindersEnabled => $composableBuilder(
    column: $table.medicationRemindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appointmentRemindersEnabled => $composableBuilder(
    column: $table.appointmentRemindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mealTrackingEnabled => $composableBuilder(
    column: $table.mealTrackingEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$SettingsRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRecordsTable,
          SettingsRecord,
          $$SettingsRecordsTableFilterComposer,
          $$SettingsRecordsTableOrderingComposer,
          $$SettingsRecordsTableAnnotationComposer,
          $$SettingsRecordsTableCreateCompanionBuilder,
          $$SettingsRecordsTableUpdateCompanionBuilder,
          (
            SettingsRecord,
            BaseReferences<
              _$AppDatabase,
              $SettingsRecordsTable,
              SettingsRecord
            >,
          ),
          SettingsRecord,
          PrefetchHooks Function()
        > {
  $$SettingsRecordsTableTableManager(
    _$AppDatabase db,
    $SettingsRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> dailyWaterGoalMl = const Value.absent(),
                Value<bool> vitaminRemindersEnabled = const Value.absent(),
                Value<bool> medicationRemindersEnabled = const Value.absent(),
                Value<bool> appointmentRemindersEnabled = const Value.absent(),
                Value<bool> mealTrackingEnabled = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsRecordsCompanion(
                id: id,
                userId: userId,
                dailyWaterGoalMl: dailyWaterGoalMl,
                vitaminRemindersEnabled: vitaminRemindersEnabled,
                medicationRemindersEnabled: medicationRemindersEnabled,
                appointmentRemindersEnabled: appointmentRemindersEnabled,
                mealTrackingEnabled: mealTrackingEnabled,
                weightUnit: weightUnit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<int> dailyWaterGoalMl = const Value.absent(),
                Value<bool> vitaminRemindersEnabled = const Value.absent(),
                Value<bool> medicationRemindersEnabled = const Value.absent(),
                Value<bool> appointmentRemindersEnabled = const Value.absent(),
                Value<bool> mealTrackingEnabled = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncStatus,
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsRecordsCompanion.insert(
                id: id,
                userId: userId,
                dailyWaterGoalMl: dailyWaterGoalMl,
                vitaminRemindersEnabled: vitaminRemindersEnabled,
                medicationRemindersEnabled: medicationRemindersEnabled,
                appointmentRemindersEnabled: appointmentRemindersEnabled,
                mealTrackingEnabled: mealTrackingEnabled,
                weightUnit: weightUnit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRecordsTable,
      SettingsRecord,
      $$SettingsRecordsTableFilterComposer,
      $$SettingsRecordsTableOrderingComposer,
      $$SettingsRecordsTableAnnotationComposer,
      $$SettingsRecordsTableCreateCompanionBuilder,
      $$SettingsRecordsTableUpdateCompanionBuilder,
      (
        SettingsRecord,
        BaseReferences<_$AppDatabase, $SettingsRecordsTable, SettingsRecord>,
      ),
      SettingsRecord,
      PrefetchHooks Function()
    >;
typedef $$SettingsCutoversTableCreateCompanionBuilder =
    SettingsCutoversCompanion Function({
      required String migrationKey,
      required int version,
      required String userId,
      required DateTime completedAt,
      required String checksum,
      required int recordCount,
      required int databaseSchemaVersion,
      Value<int> rowid,
    });
typedef $$SettingsCutoversTableUpdateCompanionBuilder =
    SettingsCutoversCompanion Function({
      Value<String> migrationKey,
      Value<int> version,
      Value<String> userId,
      Value<DateTime> completedAt,
      Value<String> checksum,
      Value<int> recordCount,
      Value<int> databaseSchemaVersion,
      Value<int> rowid,
    });

class $$SettingsCutoversTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsCutoversTable> {
  $$SettingsCutoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsCutoversTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsCutoversTable> {
  $$SettingsCutoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsCutoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsCutoversTable> {
  $$SettingsCutoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => column,
  );
}

class $$SettingsCutoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsCutoversTable,
          SettingsCutover,
          $$SettingsCutoversTableFilterComposer,
          $$SettingsCutoversTableOrderingComposer,
          $$SettingsCutoversTableAnnotationComposer,
          $$SettingsCutoversTableCreateCompanionBuilder,
          $$SettingsCutoversTableUpdateCompanionBuilder,
          (
            SettingsCutover,
            BaseReferences<
              _$AppDatabase,
              $SettingsCutoversTable,
              SettingsCutover
            >,
          ),
          SettingsCutover,
          PrefetchHooks Function()
        > {
  $$SettingsCutoversTableTableManager(
    _$AppDatabase db,
    $SettingsCutoversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsCutoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsCutoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsCutoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> databaseSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCutoversCompanion(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required int version,
                required String userId,
                required DateTime completedAt,
                required String checksum,
                required int recordCount,
                required int databaseSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCutoversCompanion.insert(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsCutoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsCutoversTable,
      SettingsCutover,
      $$SettingsCutoversTableFilterComposer,
      $$SettingsCutoversTableOrderingComposer,
      $$SettingsCutoversTableAnnotationComposer,
      $$SettingsCutoversTableCreateCompanionBuilder,
      $$SettingsCutoversTableUpdateCompanionBuilder,
      (
        SettingsCutover,
        BaseReferences<_$AppDatabase, $SettingsCutoversTable, SettingsCutover>,
      ),
      SettingsCutover,
      PrefetchHooks Function()
    >;
typedef $$ProfileRecordsTableCreateCompanionBuilder =
    ProfileRecordsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String email,
      required DateTime birthDate,
      required int heightInCentimeters,
      required double initialWeight,
      Value<double?> targetWeight,
      required DateTime surgeryDate,
      required String surgeryType,
      Value<String?> photoUrl,
      Value<String?> photoStoragePath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$ProfileRecordsTableUpdateCompanionBuilder =
    ProfileRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> email,
      Value<DateTime> birthDate,
      Value<int> heightInCentimeters,
      Value<double> initialWeight,
      Value<double?> targetWeight,
      Value<DateTime> surgeryDate,
      Value<String> surgeryType,
      Value<String?> photoUrl,
      Value<String?> photoStoragePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$ProfileRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightInCentimeters => $composableBuilder(
    column: $table.heightInCentimeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialWeight => $composableBuilder(
    column: $table.initialWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get surgeryDate => $composableBuilder(
    column: $table.surgeryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surgeryType => $composableBuilder(
    column: $table.surgeryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoStoragePath => $composableBuilder(
    column: $table.photoStoragePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightInCentimeters => $composableBuilder(
    column: $table.heightInCentimeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialWeight => $composableBuilder(
    column: $table.initialWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get surgeryDate => $composableBuilder(
    column: $table.surgeryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surgeryType => $composableBuilder(
    column: $table.surgeryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoStoragePath => $composableBuilder(
    column: $table.photoStoragePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<int> get heightInCentimeters => $composableBuilder(
    column: $table.heightInCentimeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialWeight => $composableBuilder(
    column: $table.initialWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get surgeryDate => $composableBuilder(
    column: $table.surgeryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surgeryType => $composableBuilder(
    column: $table.surgeryType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get photoStoragePath => $composableBuilder(
    column: $table.photoStoragePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$ProfileRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileRecordsTable,
          ProfileRecord,
          $$ProfileRecordsTableFilterComposer,
          $$ProfileRecordsTableOrderingComposer,
          $$ProfileRecordsTableAnnotationComposer,
          $$ProfileRecordsTableCreateCompanionBuilder,
          $$ProfileRecordsTableUpdateCompanionBuilder,
          (
            ProfileRecord,
            BaseReferences<_$AppDatabase, $ProfileRecordsTable, ProfileRecord>,
          ),
          ProfileRecord,
          PrefetchHooks Function()
        > {
  $$ProfileRecordsTableTableManager(
    _$AppDatabase db,
    $ProfileRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<DateTime> birthDate = const Value.absent(),
                Value<int> heightInCentimeters = const Value.absent(),
                Value<double> initialWeight = const Value.absent(),
                Value<double?> targetWeight = const Value.absent(),
                Value<DateTime> surgeryDate = const Value.absent(),
                Value<String> surgeryType = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoStoragePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileRecordsCompanion(
                id: id,
                userId: userId,
                name: name,
                email: email,
                birthDate: birthDate,
                heightInCentimeters: heightInCentimeters,
                initialWeight: initialWeight,
                targetWeight: targetWeight,
                surgeryDate: surgeryDate,
                surgeryType: surgeryType,
                photoUrl: photoUrl,
                photoStoragePath: photoStoragePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String email,
                required DateTime birthDate,
                required int heightInCentimeters,
                required double initialWeight,
                Value<double?> targetWeight = const Value.absent(),
                required DateTime surgeryDate,
                required String surgeryType,
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoStoragePath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncStatus,
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileRecordsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                email: email,
                birthDate: birthDate,
                heightInCentimeters: heightInCentimeters,
                initialWeight: initialWeight,
                targetWeight: targetWeight,
                surgeryDate: surgeryDate,
                surgeryType: surgeryType,
                photoUrl: photoUrl,
                photoStoragePath: photoStoragePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileRecordsTable,
      ProfileRecord,
      $$ProfileRecordsTableFilterComposer,
      $$ProfileRecordsTableOrderingComposer,
      $$ProfileRecordsTableAnnotationComposer,
      $$ProfileRecordsTableCreateCompanionBuilder,
      $$ProfileRecordsTableUpdateCompanionBuilder,
      (
        ProfileRecord,
        BaseReferences<_$AppDatabase, $ProfileRecordsTable, ProfileRecord>,
      ),
      ProfileRecord,
      PrefetchHooks Function()
    >;
typedef $$ProfileCutoversTableCreateCompanionBuilder =
    ProfileCutoversCompanion Function({
      required String migrationKey,
      required int version,
      required String userId,
      required DateTime completedAt,
      required String checksum,
      required int recordCount,
      required int databaseSchemaVersion,
      Value<int> rowid,
    });
typedef $$ProfileCutoversTableUpdateCompanionBuilder =
    ProfileCutoversCompanion Function({
      Value<String> migrationKey,
      Value<int> version,
      Value<String> userId,
      Value<DateTime> completedAt,
      Value<String> checksum,
      Value<int> recordCount,
      Value<int> databaseSchemaVersion,
      Value<int> rowid,
    });

class $$ProfileCutoversTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileCutoversTable> {
  $$ProfileCutoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileCutoversTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileCutoversTable> {
  $$ProfileCutoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileCutoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileCutoversTable> {
  $$ProfileCutoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => column,
  );
}

class $$ProfileCutoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileCutoversTable,
          ProfileCutover,
          $$ProfileCutoversTableFilterComposer,
          $$ProfileCutoversTableOrderingComposer,
          $$ProfileCutoversTableAnnotationComposer,
          $$ProfileCutoversTableCreateCompanionBuilder,
          $$ProfileCutoversTableUpdateCompanionBuilder,
          (
            ProfileCutover,
            BaseReferences<
              _$AppDatabase,
              $ProfileCutoversTable,
              ProfileCutover
            >,
          ),
          ProfileCutover,
          PrefetchHooks Function()
        > {
  $$ProfileCutoversTableTableManager(
    _$AppDatabase db,
    $ProfileCutoversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileCutoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileCutoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileCutoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> databaseSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileCutoversCompanion(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required int version,
                required String userId,
                required DateTime completedAt,
                required String checksum,
                required int recordCount,
                required int databaseSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ProfileCutoversCompanion.insert(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileCutoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileCutoversTable,
      ProfileCutover,
      $$ProfileCutoversTableFilterComposer,
      $$ProfileCutoversTableOrderingComposer,
      $$ProfileCutoversTableAnnotationComposer,
      $$ProfileCutoversTableCreateCompanionBuilder,
      $$ProfileCutoversTableUpdateCompanionBuilder,
      (
        ProfileCutover,
        BaseReferences<_$AppDatabase, $ProfileCutoversTable, ProfileCutover>,
      ),
      ProfileCutover,
      PrefetchHooks Function()
    >;
typedef $$WeightRecordsTableCreateCompanionBuilder =
    WeightRecordsCompanion Function({
      required String id,
      required String userId,
      required double weightKg,
      required DateTime recordedAt,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$WeightRecordsTableUpdateCompanionBuilder =
    WeightRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<double> weightKg,
      Value<DateTime> recordedAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$WeightRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightRecordsTable> {
  $$WeightRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightRecordsTable> {
  $$WeightRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightRecordsTable> {
  $$WeightRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$WeightRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightRecordsTable,
          WeightRecord,
          $$WeightRecordsTableFilterComposer,
          $$WeightRecordsTableOrderingComposer,
          $$WeightRecordsTableAnnotationComposer,
          $$WeightRecordsTableCreateCompanionBuilder,
          $$WeightRecordsTableUpdateCompanionBuilder,
          (
            WeightRecord,
            BaseReferences<_$AppDatabase, $WeightRecordsTable, WeightRecord>,
          ),
          WeightRecord,
          PrefetchHooks Function()
        > {
  $$WeightRecordsTableTableManager(_$AppDatabase db, $WeightRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightRecordsCompanion(
                id: id,
                userId: userId,
                weightKg: weightKg,
                recordedAt: recordedAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required double weightKg,
                required DateTime recordedAt,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncStatus,
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightRecordsCompanion.insert(
                id: id,
                userId: userId,
                weightKg: weightKg,
                recordedAt: recordedAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightRecordsTable,
      WeightRecord,
      $$WeightRecordsTableFilterComposer,
      $$WeightRecordsTableOrderingComposer,
      $$WeightRecordsTableAnnotationComposer,
      $$WeightRecordsTableCreateCompanionBuilder,
      $$WeightRecordsTableUpdateCompanionBuilder,
      (
        WeightRecord,
        BaseReferences<_$AppDatabase, $WeightRecordsTable, WeightRecord>,
      ),
      WeightRecord,
      PrefetchHooks Function()
    >;
typedef $$WeightCutoversTableCreateCompanionBuilder =
    WeightCutoversCompanion Function({
      required String migrationKey,
      required int version,
      required String userId,
      required DateTime completedAt,
      required String checksum,
      required int recordCount,
      required int databaseSchemaVersion,
      Value<int> rowid,
    });
typedef $$WeightCutoversTableUpdateCompanionBuilder =
    WeightCutoversCompanion Function({
      Value<String> migrationKey,
      Value<int> version,
      Value<String> userId,
      Value<DateTime> completedAt,
      Value<String> checksum,
      Value<int> recordCount,
      Value<int> databaseSchemaVersion,
      Value<int> rowid,
    });

class $$WeightCutoversTableFilterComposer
    extends Composer<_$AppDatabase, $WeightCutoversTable> {
  $$WeightCutoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightCutoversTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightCutoversTable> {
  $$WeightCutoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightCutoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightCutoversTable> {
  $$WeightCutoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => column,
  );
}

class $$WeightCutoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightCutoversTable,
          WeightCutover,
          $$WeightCutoversTableFilterComposer,
          $$WeightCutoversTableOrderingComposer,
          $$WeightCutoversTableAnnotationComposer,
          $$WeightCutoversTableCreateCompanionBuilder,
          $$WeightCutoversTableUpdateCompanionBuilder,
          (
            WeightCutover,
            BaseReferences<_$AppDatabase, $WeightCutoversTable, WeightCutover>,
          ),
          WeightCutover,
          PrefetchHooks Function()
        > {
  $$WeightCutoversTableTableManager(
    _$AppDatabase db,
    $WeightCutoversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightCutoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightCutoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightCutoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> databaseSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightCutoversCompanion(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required int version,
                required String userId,
                required DateTime completedAt,
                required String checksum,
                required int recordCount,
                required int databaseSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => WeightCutoversCompanion.insert(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightCutoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightCutoversTable,
      WeightCutover,
      $$WeightCutoversTableFilterComposer,
      $$WeightCutoversTableOrderingComposer,
      $$WeightCutoversTableAnnotationComposer,
      $$WeightCutoversTableCreateCompanionBuilder,
      $$WeightCutoversTableUpdateCompanionBuilder,
      (
        WeightCutover,
        BaseReferences<_$AppDatabase, $WeightCutoversTable, WeightCutover>,
      ),
      WeightCutover,
      PrefetchHooks Function()
    >;
typedef $$MealRecordsTableCreateCompanionBuilder =
    MealRecordsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String type,
      required DateTime mealDate,
      Value<String?> notes,
      Value<int?> proteinGrams,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$MealRecordsTableUpdateCompanionBuilder =
    MealRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> type,
      Value<DateTime> mealDate,
      Value<String?> notes,
      Value<int?> proteinGrams,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<String?> previousSyncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$MealRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mealDate => $composableBuilder(
    column: $table.mealDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mealDate => $composableBuilder(
    column: $table.mealDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get mealDate =>
      $composableBuilder(column: $table.mealDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousSyncStatus => $composableBuilder(
    column: $table.previousSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$MealRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealRecordsTable,
          MealRecord,
          $$MealRecordsTableFilterComposer,
          $$MealRecordsTableOrderingComposer,
          $$MealRecordsTableAnnotationComposer,
          $$MealRecordsTableCreateCompanionBuilder,
          $$MealRecordsTableUpdateCompanionBuilder,
          (
            MealRecord,
            BaseReferences<_$AppDatabase, $MealRecordsTable, MealRecord>,
          ),
          MealRecord,
          PrefetchHooks Function()
        > {
  $$MealRecordsTableTableManager(_$AppDatabase db, $MealRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> mealDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> proteinGrams = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealRecordsCompanion(
                id: id,
                userId: userId,
                name: name,
                type: type,
                mealDate: mealDate,
                notes: notes,
                proteinGrams: proteinGrams,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String type,
                required DateTime mealDate,
                Value<String?> notes = const Value.absent(),
                Value<int?> proteinGrams = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String syncStatus,
                Value<String?> previousSyncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealRecordsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                type: type,
                mealDate: mealDate,
                notes: notes,
                proteinGrams: proteinGrams,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                previousSyncStatus: previousSyncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealRecordsTable,
      MealRecord,
      $$MealRecordsTableFilterComposer,
      $$MealRecordsTableOrderingComposer,
      $$MealRecordsTableAnnotationComposer,
      $$MealRecordsTableCreateCompanionBuilder,
      $$MealRecordsTableUpdateCompanionBuilder,
      (
        MealRecord,
        BaseReferences<_$AppDatabase, $MealRecordsTable, MealRecord>,
      ),
      MealRecord,
      PrefetchHooks Function()
    >;
typedef $$MealCutoversTableCreateCompanionBuilder =
    MealCutoversCompanion Function({
      required String migrationKey,
      required int version,
      required String userId,
      required DateTime completedAt,
      required String checksum,
      required int recordCount,
      required int databaseSchemaVersion,
      Value<int> rowid,
    });
typedef $$MealCutoversTableUpdateCompanionBuilder =
    MealCutoversCompanion Function({
      Value<String> migrationKey,
      Value<int> version,
      Value<String> userId,
      Value<DateTime> completedAt,
      Value<String> checksum,
      Value<int> recordCount,
      Value<int> databaseSchemaVersion,
      Value<int> rowid,
    });

class $$MealCutoversTableFilterComposer
    extends Composer<_$AppDatabase, $MealCutoversTable> {
  $$MealCutoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealCutoversTableOrderingComposer
    extends Composer<_$AppDatabase, $MealCutoversTable> {
  $$MealCutoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealCutoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealCutoversTable> {
  $$MealCutoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get recordCount => $composableBuilder(
    column: $table.recordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get databaseSchemaVersion => $composableBuilder(
    column: $table.databaseSchemaVersion,
    builder: (column) => column,
  );
}

class $$MealCutoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealCutoversTable,
          MealCutover,
          $$MealCutoversTableFilterComposer,
          $$MealCutoversTableOrderingComposer,
          $$MealCutoversTableAnnotationComposer,
          $$MealCutoversTableCreateCompanionBuilder,
          $$MealCutoversTableUpdateCompanionBuilder,
          (
            MealCutover,
            BaseReferences<_$AppDatabase, $MealCutoversTable, MealCutover>,
          ),
          MealCutover,
          PrefetchHooks Function()
        > {
  $$MealCutoversTableTableManager(_$AppDatabase db, $MealCutoversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealCutoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealCutoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealCutoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> recordCount = const Value.absent(),
                Value<int> databaseSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealCutoversCompanion(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required int version,
                required String userId,
                required DateTime completedAt,
                required String checksum,
                required int recordCount,
                required int databaseSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => MealCutoversCompanion.insert(
                migrationKey: migrationKey,
                version: version,
                userId: userId,
                completedAt: completedAt,
                checksum: checksum,
                recordCount: recordCount,
                databaseSchemaVersion: databaseSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealCutoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealCutoversTable,
      MealCutover,
      $$MealCutoversTableFilterComposer,
      $$MealCutoversTableOrderingComposer,
      $$MealCutoversTableAnnotationComposer,
      $$MealCutoversTableCreateCompanionBuilder,
      $$MealCutoversTableUpdateCompanionBuilder,
      (
        MealCutover,
        BaseReferences<_$AppDatabase, $MealCutoversTable, MealCutover>,
      ),
      MealCutover,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WaterRecordsTableTableManager get waterRecords =>
      $$WaterRecordsTableTableManager(_db, _db.waterRecords);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$SyncDevicesTableTableManager get syncDevices =>
      $$SyncDevicesTableTableManager(_db, _db.syncDevices);
  $$LocalMigrationsTableTableManager get localMigrations =>
      $$LocalMigrationsTableTableManager(_db, _db.localMigrations);
  $$WaterCutoversTableTableManager get waterCutovers =>
      $$WaterCutoversTableTableManager(_db, _db.waterCutovers);
  $$SettingsRecordsTableTableManager get settingsRecords =>
      $$SettingsRecordsTableTableManager(_db, _db.settingsRecords);
  $$SettingsCutoversTableTableManager get settingsCutovers =>
      $$SettingsCutoversTableTableManager(_db, _db.settingsCutovers);
  $$ProfileRecordsTableTableManager get profileRecords =>
      $$ProfileRecordsTableTableManager(_db, _db.profileRecords);
  $$ProfileCutoversTableTableManager get profileCutovers =>
      $$ProfileCutoversTableTableManager(_db, _db.profileCutovers);
  $$WeightRecordsTableTableManager get weightRecords =>
      $$WeightRecordsTableTableManager(_db, _db.weightRecords);
  $$WeightCutoversTableTableManager get weightCutovers =>
      $$WeightCutoversTableTableManager(_db, _db.weightCutovers);
  $$MealRecordsTableTableManager get mealRecords =>
      $$MealRecordsTableTableManager(_db, _db.mealRecords);
  $$MealCutoversTableTableManager get mealCutovers =>
      $$MealCutoversTableTableManager(_db, _db.mealCutovers);
}
