import '../entities/entities.dart';
import '../repositories/repositories.dart';

class PrivacyUseCases {
  const PrivacyUseCases(this._repository);
  final PrivacyRepository _repository;

  Future<List<PrivacyConsent>> getConsentHistory() =>
      _repository.getConsentHistory();
  Future<PrivacyConsent> acceptCurrentDocuments() =>
      _repository.acceptCurrentDocuments();
  Future<bool> hasCurrentConsent() => _repository.hasCurrentConsent();
  Future<void> requestDefinitiveRemoval() =>
      _repository.requestDefinitiveRemoval();
  Future<void> deleteRemoteData({String? password}) =>
      _repository.deleteRemoteData(password: password);
  Future<void> deleteRemoteAccount({String? password}) =>
      _repository.deleteRemoteAccount(password: password);
  bool get passwordRequired => _repository.passwordRequired;
}
