import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/supabase/interceptors/supabase_request_interceptor.dart';
import '../dtos/privacy_consent_dto.dart';

abstract interface class PrivacyRemoteDatasource {
  Future<PrivacyConsentDto> upsert(PrivacyConsentDto value);
  Future<List<PrivacyConsentDto>> pull(String userId, DateTime? updatedAfter);
  Future<void> requestDefinitiveRemoval();
  Future<void> deleteData({String? password});
  Future<void> deleteAccount({String? password});
  bool get passwordRequired;
}

class PrivacySupabaseDatasource implements PrivacyRemoteDatasource {
  const PrivacySupabaseDatasource({
    required SupabaseDatabase database,
    required SupabaseClient client,
    required SupabaseInterceptorRunner interceptor,
  }) : _database = database,
       _client = client,
       _interceptor = interceptor;

  final SupabaseDatabase _database;
  final SupabaseClient _client;
  final SupabaseInterceptorRunner _interceptor;

  @override
  bool get passwordRequired =>
      _client.auth.currentUser?.appMetadata['provider'] == 'email';

  @override
  Future<PrivacyConsentDto> upsert(PrivacyConsentDto value) => _database.run(
    operation: 'upsert',
    table: 'privacy_consents',
    request: (query) async => PrivacyConsentDto.fromSupabase(
      Map<String, dynamic>.from(
        await query
            .upsert(
              value.toSupabase(),
              onConflict: 'user_id,terms_version,privacy_version',
            )
            .select()
            .single(),
      ),
    ),
  );

  @override
  Future<List<PrivacyConsentDto>> pull(String userId, DateTime? updatedAfter) =>
      _database.run(
        operation: 'select',
        table: 'privacy_consents',
        request: (query) async {
          var request = query.select().eq('user_id', userId);
          if (updatedAfter != null) {
            request = request.gt('updated_at', updatedAfter.toIso8601String());
          }
          return (await request.order(
            'updated_at',
          )).map(PrivacyConsentDto.fromSupabase).toList();
        },
      );

  @override
  Future<void> requestDefinitiveRemoval() => _rpc(
    operation: 'privacy.requestDeletion',
    function: 'request_my_account_deletion',
  );

  @override
  Future<void> deleteData({String? password}) async {
    await _verifyPassword(password);
    await _deleteStorage();
    await _rpc(operation: 'privacy.deleteData', function: 'delete_my_data');
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    await _verifyPassword(password);
    await _deleteStorage();
    await _rpc(
      operation: 'privacy.deleteAccount',
      function: 'delete_my_account',
    );
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  Future<void> _verifyPassword(String? password) async {
    if (!passwordRequired) return;
    final email = _client.auth.currentUser?.email;
    if (email == null || password == null || password.isEmpty) {
      throw StateError('Senha obrigatória para confirmar esta operação.');
    }
    await _interceptor.run(
      context: const SupabaseRequestContext(
        operation: 'privacy.verifyPassword',
        metadata: {'requiresAuth': true},
      ),
      request: () =>
          _client.auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<void> _deleteStorage() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');
    for (final bucket in privacyStorageBuckets) {
      final paths = await _listFiles(bucket: bucket, path: userId);
      for (var offset = 0; offset < paths.length; offset += 100) {
        final end = (offset + 100).clamp(0, paths.length);
        await _interceptor.run(
          context: SupabaseRequestContext(
            operation: 'privacy.storage.remove',
            bucket: bucket,
            metadata: const {'requiresAuth': true},
          ),
          request: () =>
              _client.storage.from(bucket).remove(paths.sublist(offset, end)),
        );
      }
    }
  }

  Future<List<String>> _listFiles({
    required String bucket,
    required String path,
  }) async {
    final result = <String>[];
    var offset = 0;
    while (true) {
      final objects = await _client.storage
          .from(bucket)
          .list(
            path: path,
            searchOptions: SearchOptions(limit: 100, offset: offset),
          );
      for (final object in objects) {
        final child = '$path/${object.name}';
        if (object.id == null && object.metadata == null) {
          result.addAll(await _listFiles(bucket: bucket, path: child));
        } else {
          result.add(child);
        }
      }
      if (objects.length < 100) break;
      offset += objects.length;
    }
    return result;
  }

  Future<void> _rpc({required String operation, required String function}) =>
      _interceptor.run(
        context: SupabaseRequestContext(
          operation: operation,
          metadata: const {'requiresAuth': true},
        ),
        request: () async {
          await _client.rpc<void>(function);
        },
      );
}

const privacyStorageBuckets = <String>[
  'profile-photos',
  'exam-attachments',
  'medical-reports',
  'report-attachments',
  'clinical-documents',
];
