import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// تخزين محلي (Hive) — نفس بنية state/* السابقة في Firestore.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _boxName = 'implant_stock_v1';

  Box<dynamic>? _box;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    if (!_box!.containsKey('warehouseStock')) {
      await seedEmpty();
    }
  }

  Future<void> seedEmpty() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final centers = <String, dynamic>{};
    for (final c in kCenters) {
      centers[c.id] = <dynamic>[];
    }
    await _box!.putAll({
      'warehouseStock': {'items': <dynamic>[], 'updated': ts},
      'centerStock': {'data': centers, 'updated': ts},
      'movementLog': {'items': <dynamic>[], 'updated': ts},
      'requests': {'items': <dynamic>[], 'updated': ts},
      'returnRequests': {'items': <dynamic>[], 'updated': ts},
    });
    _notify();
  }

  Future<Map<String, dynamic>?> doc(String key) async {
    final raw = _box?.get(key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> putAll(Map<String, Map<String, dynamic>> docs) async {
    await _box!.putAll(docs);
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
    await _box?.close();
  }
}
