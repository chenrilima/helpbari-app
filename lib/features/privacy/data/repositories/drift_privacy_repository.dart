import '../../../../core/services/services.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/drift_privacy_consent_datasource.dart';
import '../datasources/privacy_supabase_datasource.dart';
import '../dtos/privacy_consent_dto.dart';

class DriftPrivacyRepository implements PrivacyRepository {
  const DriftPrivacyRepository({
    required Future<DriftPrivacyConsentDatasource> Function() local,
    required PrivacyRemoteDatasource? remote,
    required ClockService clock,
    required UuidService uuid,
    required String userId,
    required Future<String> Function() deviceId,
    required Future<String> Function() timezone,
  }) : _local = local,
       _remote = remote,
       _clock = clock,
       _uuid = uuid,
       _userId = userId,
       _deviceId = deviceId,
       _timezone = timezone;

  final Future<DriftPrivacyConsentDatasource> Function() _local;
  final PrivacyRemoteDatasource? _remote;
  final ClockService _clock;
  final UuidService _uuid;
  final String _userId;
  final Future<String> Function() _deviceId;
  final Future<String> Function() _timezone;

  @override
  Future<List<PrivacyConsent>> getConsentHistory() async =>
      (await (await _local()).getAll()).map((dto) => dto.consent).toList();

  @override
  Future<bool> hasCurrentConsent() async => (await getConsentHistory()).any(
    (consent) =>
        consent.termsVersion == PrivacyDocuments.termsVersion &&
        consent.privacyVersion == PrivacyDocuments.privacyVersion,
  );

  @override
  Future<PrivacyConsent> acceptCurrentDocuments() async {
    if (_userId == 'anonymous') {
      throw StateError('Autenticação obrigatória para registrar o aceite.');
    }
    final existing = await getConsentHistory();
    for (final consent in existing) {
      if (consent.termsVersion == PrivacyDocuments.termsVersion &&
          consent.privacyVersion == PrivacyDocuments.privacyVersion) {
        return consent;
      }
    }
    final now = _clock.now();
    final consent = PrivacyConsent(
      id: _uuid.generate(),
      userId: _userId,
      termsVersion: PrivacyDocuments.termsVersion,
      privacyVersion: PrivacyDocuments.privacyVersion,
      acceptedAt: now,
      deviceId: await _deviceId(),
      timezone: await _timezone(),
    );
    await (await _local()).save(
      PrivacyConsentDto(
        consent: consent,
        syncMetadata: SyncMetadata(
          id: consent.id,
          userId: _userId,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
        ),
      ),
    );
    return consent;
  }

  @override
  bool get passwordRequired => _remote?.passwordRequired ?? false;

  @override
  Future<void> requestDefinitiveRemoval() =>
      _requiredRemote().requestDefinitiveRemoval();

  @override
  Future<void> deleteRemoteData({String? password}) =>
      _requiredRemote().deleteData(password: password);

  @override
  Future<void> deleteRemoteAccount({String? password}) =>
      _requiredRemote().deleteAccount(password: password);

  PrivacyRemoteDatasource _requiredRemote() =>
      _remote ?? (throw StateError('Conexão necessária para esta operação.'));
}
