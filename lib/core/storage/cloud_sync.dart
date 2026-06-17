import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// مزامنة Supabase — جدول app_state (key + data JSON).
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  static const stateKeys = [
    'warehouseStock',
    'centerStock',
    'movementLog',
    'requests',
    'returnRequests',
    'nurseReports',
  ];

  static const _usersDoc = 'users_v1';

  bool _ready = false;
  int? _lastPushMs;
  final _remote = StreamController<void>.broadcast();
  RealtimeChannel? _channel;

  bool get isReady => _ready;
  Stream<void> get remoteChanges => _remote.stream;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> init() async {
    if (_ready) return;
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[CloudSync] Supabase غير مضبوط — ضع URL و anon key في supabase_config.dart',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      _ready = true;
      _listenAll();
      if (kDebugMode) debugPrint('[CloudSync] Supabase connected');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CloudSync] init failed: $e\n$st');
    }
  }

  void _listenAll() {
    _channel?.unsubscribe();
    _channel = _client
        .channel('implant-stock-state')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.stateTable,
          callback: (payload) {
            final updated = _rowUpdated(payload.newRecord);
            if (_lastPushMs != null && updated - _lastPushMs! < 2000) return;
            if (!_remote.isClosed) _remote.add(null);
          },
        )
        .subscribe();
  }

  int _rowUpdated(Map<String, dynamic>? row) {
    if (row == null) return 0;
    return (row['updated'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>?> fetchDoc(String key) async {
    if (!_ready) return null;
    try {
      final row = await _client
          .from(SupabaseConfig.stateTable)
          .select('data, updated')
          .eq('key', key)
          .maybeSingle();
      if (row == null) return null;
      final data = row['data'];
      if (data is! Map) return null;
      final doc = Map<String, dynamic>.from(data);
      doc['updated'] = _rowUpdated(row);
      return doc;
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSync] fetch $key: $e');
      return null;
    }
  }

  Future<void> pushDocs(Map<String, Map<String, dynamic>> docs) async {
    if (!_ready) return;
    final ts = DateTime.now().millisecondsSinceEpoch;
    _lastPushMs = ts;
    try {
      final rows = docs.entries.map((e) {
        final payload = Map<String, dynamic>.from(e.value);
        payload['updated'] = ts;
        return {
          'key': e.key,
          'data': payload,
          'updated': ts,
        };
      }).toList();
      await _client.from(SupabaseConfig.stateTable).upsert(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSync] push error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> fetchUsers() async {
    final data = await fetchDoc(_usersDoc);
    if (data == null) return null;
    final items = data['items'];
    if (items is! List) return null;
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> pushUsers(List<Map<String, dynamic>> users) async {
    await pushDocs({
      _usersDoc: {'items': users},
    });
  }

  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
    await _remote.close();
  }
}
