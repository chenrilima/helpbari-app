// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state_dao.dart';

// ignore_for_file: type=lint
mixin _$OnboardingStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $OnboardingStateRecordsTable get onboardingStateRecords =>
      attachedDatabase.onboardingStateRecords;
  OnboardingStateDaoManager get managers => OnboardingStateDaoManager(this);
}

class OnboardingStateDaoManager {
  final _$OnboardingStateDaoMixin _db;
  OnboardingStateDaoManager(this._db);
  $$OnboardingStateRecordsTableTableManager get onboardingStateRecords =>
      $$OnboardingStateRecordsTableTableManager(
        _db.attachedDatabase,
        _db.onboardingStateRecords,
      );
}
