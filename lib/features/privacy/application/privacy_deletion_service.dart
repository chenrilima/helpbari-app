import '../domain/models/models.dart';
import '../domain/usecases/use_cases.dart';
import '../data/services/privacy_local_cleanup_service.dart';

class PrivacyDeletionService {
  const PrivacyDeletionService({
    required PrivacyUseCases privacy,
    required PrivacyLocalCleanupService localCleanup,
    required Future<void> Function() logout,
    required String userId,
  }) : _privacy = privacy,
       _localCleanup = localCleanup,
       _logout = logout,
       _userId = userId;

  final PrivacyUseCases _privacy;
  final PrivacyLocalCleanupService _localCleanup;
  final Future<void> Function() _logout;
  final String _userId;

  Future<PrivacyDeletionResult> deleteData({String? password}) =>
      _delete(PrivacyDeletionKind.data, password: password);

  Future<PrivacyDeletionResult> deleteAccount({String? password}) =>
      _delete(PrivacyDeletionKind.account, password: password);

  Future<PrivacyDeletionResult> _delete(
    PrivacyDeletionKind kind, {
    String? password,
  }) async {
    if (_userId == 'anonymous') {
      throw StateError('Usuário autenticado obrigatório.');
    }
    if (kind == PrivacyDeletionKind.account) {
      await _privacy.deleteRemoteAccount(password: password);
    } else {
      await _privacy.deleteRemoteData(password: password);
    }
    try {
      await _localCleanup.clearUser(_userId);
    } catch (error) {
      throw PrivacyPartialDeletionException(error);
    }
    await _logout();
    return PrivacyDeletionResult(
      kind: kind,
      remoteCompleted: true,
      localCompleted: true,
    );
  }
}

class PrivacyPartialDeletionException implements Exception {
  const PrivacyPartialDeletionException(this.cause);
  final Object cause;

  @override
  String toString() =>
      'Dados remotos removidos; a limpeza local precisa ser repetida.';
}
