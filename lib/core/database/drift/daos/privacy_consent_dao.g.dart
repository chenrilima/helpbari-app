// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_consent_dao.dart';

// ignore_for_file: type=lint
mixin _$PrivacyConsentDaoMixin on DatabaseAccessor<AppDatabase> {
  $PrivacyConsentRecordsTable get privacyConsentRecords =>
      attachedDatabase.privacyConsentRecords;
  PrivacyConsentDaoManager get managers => PrivacyConsentDaoManager(this);
}

class PrivacyConsentDaoManager {
  final _$PrivacyConsentDaoMixin _db;
  PrivacyConsentDaoManager(this._db);
  $$PrivacyConsentRecordsTableTableManager get privacyConsentRecords =>
      $$PrivacyConsentRecordsTableTableManager(
        _db.attachedDatabase,
        _db.privacyConsentRecords,
      );
}
