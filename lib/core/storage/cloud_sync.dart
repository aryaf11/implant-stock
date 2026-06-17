import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// مزامنة Firestore — نفس هيكل التطبيق القديم (مجموعة state).
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

  FirebaseFirestore? _db;
  bool _ready = false;
  int? _lastPushMs;
  final _remote = StreamController<void>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];

  bool get isReady => _ready;
  Stream<void> get remoteChanges => _remote.stream;

  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _db = FirebaseFirestore.instance;
      _ready = true;
      _listenAll();
      if (kDebugMode) debugPrint('[CloudSync] Firebase connected');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CloudSync] init failed: $e\n$st');
    }
  }

  void _listenAll() {
    final db = _db;
    if (db == null) return;
    for (final key in stateKeys) {
      _subs.add(
        db.collection('state').doc(key).snapshots().listen((snap) {
          if (!snap.exists) return;
          final data = snap.data();
          if (data == null) return;
          final updated = (data['updated'] as num?)?.toInt() ?? 0;
          if (_lastPushMs != null && updated - _lastPushMs! < 2000) return;
          if (!_remote.isClosed) _remote.add(null);
        }),
      );
    }
    _subs.add(
      db.collection('state').doc(_usersDoc).snapshots().listen((_) {
        if (!_remote.isClosed) _remote.add(null);
      }),
    );
  }

  Future<Map<String, dynamic>?> fetchDoc(String key) async {
    if (!_ready || _db == null) return null;
    try {
      final snap = await _db!.collection('state').doc(key).get();
      if (!snap.exists) return null;
      return snap.data();
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSync] fetch $key: $e');
      return null;
    }
  }

  Future<void> pushDocs(Map<String, Map<String, dynamic>> docs) async {
    if (!_ready || _db == null) return;
    final ts = DateTime.now().millisecondsSinceEpoch;
    _lastPushMs = ts;
    try {
      final batch = _db!.batch();
      for (final e in docs.entries) {
        final payload = Map<String, dynamic>.from(e.value);
        payload['updated'] = ts;
        batch.set(_db!.collection('state').doc(e.key), payload);
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('[CloudSync] push error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> fetchUsers() async {
    final data = await fetchDoc(_usersDoc);
    if (data == null) return null;
    final items = data['items'];
    if (items is! List) return null;
    return items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> pushUsers(List<Map<String, dynamic>> users) async {
    await pushDocs({
      _usersDoc: {'items': users},
    });
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _remote.close();
  }
}
