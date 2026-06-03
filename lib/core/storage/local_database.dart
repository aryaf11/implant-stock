import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// تخزين محلي — Hive (موبايل/سطح المكتب) أو SharedPreferences (ويب).
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _boxName = 'implant_stock_v1';
  static const _webKey = 'implant_stock_state_v1';

  Box<dynamic>? _box;
  SharedPreferences? _prefs;
  Map<String, dynamic>? _memoryCache;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  bool get _useWebPrefs => kIsWeb;

  Future<void> init() async {
    if (_useWebPrefs) {
      _prefs = await SharedPreferences.getInstance();
      _memoryCache = _readFromPrefs();
      if (!_prefs!.containsKey(_webKey)) {
        await seedEmpty();
      }
      return;
    }
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    if (!_box!.containsKey('warehouseStock')) {
      await seedEmpty();
    }
  }

  Map<String, dynamic> _emptyState() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final centers = <String, dynamic>{};
    for (final c in kCenters) {
      centers[c.id] = <dynamic>[];
    }
    return {
      'warehouseStock': {'items': <dynamic>[], 'updated': ts},
      'centerStock': {'data': centers, 'updated': ts},
      'movementLog': {'items': <dynamic>[], 'updated': ts},
      'requests': {'items': <dynamic>[], 'updated': ts},
      'returnRequests': {'items': <dynamic>[], 'updated': ts},
    };
  }

  Future<void> seedEmpty() async {
    final state = _emptyState();
    await _writeAll(state);
    _notify();
  }

  Map<String, dynamic> _readFromPrefs() {
    final raw = _prefs?.getString(_webKey);
    if (raw == null || raw.isEmpty) return _emptyState();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return _emptyState();
    return _deepStringMap(decoded);
  }

  Map<String, dynamic> _readAllDocs() {
    if (_useWebPrefs) {
      _memoryCache ??= _readFromPrefs();
      return Map<String, dynamic>.from(_memoryCache!);
    }
    final out = <String, dynamic>{};
    for (final key in [
      'warehouseStock',
      'centerStock',
      'movementLog',
      'requests',
      'returnRequests',
    ]) {
      final raw = _box!.get(key);
      if (raw is Map) {
        out[key] = _deepStringMap(raw);
      }
    }
    return out.isEmpty ? _emptyState() : out;
  }

  Future<void> _writeAll(Map<String, dynamic> all) async {
    _memoryCache = _deepStringMap(all);
    if (_useWebPrefs) {
      await _prefs!.setString(_webKey, jsonEncode(_memoryCache));
      return;
    }
    await _box!.putAll(_memoryCache!);
  }

  Map<String, dynamic> readSnapshot() => _readAllDocs();

  Future<Map<String, dynamic>?> doc(String key) async {
    final all = _readAllDocs();
    return all[key];
  }

  Future<void> putAll(Map<String, Map<String, dynamic>> docs) async {
    final all = _readAllDocs();
    all.addAll(docs);
    await _writeAll(all);
    _notify();
  }

  Map<String, dynamic> _deepStringMap(Map source) {
    return source.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
  }

  dynamic _deepConvert(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _deepConvert(val)));
    }
    if (v is List) return v.map(_deepConvert).toList();
    return v;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
    await _box?.close();
  }
}
