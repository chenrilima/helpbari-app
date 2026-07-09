import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService {
  const SupabaseRealtimeService(this._client);

  final SupabaseClient _client;

  RealtimeChannel channel(String name) {
    return _client.channel(name);
  }

  RealtimeChannel tableChannel(String table) {
    return _client.channel('public:$table');
  }

  Future<String> removeChannel(RealtimeChannel channel) {
    return _client.removeChannel(channel);
  }

  Future<List<String>> removeAllChannels() {
    return _client.removeAllChannels();
  }
}
