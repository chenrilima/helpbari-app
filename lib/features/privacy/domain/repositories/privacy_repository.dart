import '../entities/entities.dart';

abstract interface class PrivacyRepository {
  Future<List<PrivacyConsent>> getConsentHistory();
  Future<PrivacyConsent> acceptCurrentDocuments();
  Future<bool> hasCurrentConsent();
  Future<void> requestDefinitiveRemoval();
  Future<void> deleteRemoteData({String? password});
  Future<void> deleteRemoteAccount({String? password});
  bool get passwordRequired;
}
