import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'cloud_sync.dart';

/// تخزين محلي + مزامنة سحابية (Supabase).
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _boxName = 'implant_stock_v1';
  static const _webKey = 'implant_stock_state_v1';

  Box<dynamic>? _box;
  SharedPreferences? _prefs;
  Map<String, dynamic>? _memoryCache;
  final _changes = StreamController<void>.broadcast();
  StreamSubscription<void>? _cloudSub;

  Stream<void> get changes => _changes.stream;

  bool get _useWebPrefs => kIsWeb;

  bool get cloudEnabled => CloudSync.instance.isReady;

  Future<void> init() async {
    await CloudSync.instance.init();
    if (_useWebPrefs) {
      _prefs = await SharedPreferences.getInstance();
      _memoryCache = _readFromPrefs();
      if (!_prefs!.containsKey(_webKey)) {
        await _writeLocalOnly(_emptyState());
      }
    } else {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      if (!_box!.containsKey('warehouseStock')) {
        await _writeLocalOnly(_emptyState());
      }
    }
    await _pullFromCloudIfNewer();
    await _bootstrapCloudFromLocal();
    _cloudSub = CloudSync.instance.remoteChanges.listen((_) async {
      await _pullFromCloudIfNewer();
      _notify();
    });
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
      'nurseReports': {'items': <dynamic>[], 'updated': ts},
    };
  }

  int _docTs(Map<String, dynamic>? doc) {
    if (doc == null) return 0;
    return (doc['updated'] as num?)?.toInt() ?? 0;
  }

  bool _docHasData(String key, Map<String, dynamic> doc) {
    if (key == 'centerStock') {
      final data = doc['data'];
      if (data is Map) {
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return true;
        }
      }
      return false;
    }
    final items = doc['items'];
    return items is List && items.isNotEmpty;
  }

  Future<void> _bootstrapCloudFromLocal() async {
    if (!CloudSync.instance.isReady) return;
    final local = _readAllDocs();
    final toPush = <String, Map<String, dynamic>>{};

    for (final key in CloudSync.stateKeys) {
      final localDoc = local[key];
      if (localDoc is! Map) continue;
      final localMap = Map<String, dynamic>.from(localDoc);
      if (!_docHasData(key, localMap)) continue;

      final cloud = await CloudSync.instance.fetchDoc(key);
      if (cloud == null || !_docHasData(key, cloud)) {
        toPush[key] = localMap;
      }
    }

    if (toPush.isNotEmpty) {
      await CloudSync.instance.pushDocs(toPush);
    }
  }

  Future<void> _pullFromCloudIfNewer() async {
    if (!CloudSync.instance.isReady) return;
    final local = _readAllDocs();
    var merged = Map<String, dynamic>.from(local);
    var changed = false;

    for (final key in CloudSync.stateKeys) {
      final cloud = await CloudSync.instance.fetchDoc(key);
      if (cloud == null) continue;
      final localDoc = local[key];
      final localMap =
          localDoc is Map ? Map<String, dynamic>.from(localDoc) : null;
      if (_docTs(cloud) >= _docTs(localMap)) {
        merged[key] = _deepStringMap(cloud);
        changed = true;
      }
    }

    if (changed) {
      await _writeLocalOnly(merged);
    }
  }

  Future<void> seedEmpty() async {
    await _writeLocalOnly(_emptyState());
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
    for (final key in CloudSync.stateKeys) {
      final raw = _box!.get(key);
      if (raw is Map) {
        out[key] = _deepStringMap(raw);
      }
    }
    return out.isEmpty ? _emptyState() : out;
  }

  Future<void> _writeLocalOnly(Map<String, dynamic> all) async {
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
    await _writeLocalOnly(all);
    if (CloudSync.instance.isReady) {
      await CloudSync.instance.pushDocs(docs);
    }
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
    await _cloudSub?.cancel();
    await _changes.close();
    await _box?.close();
    await CloudSync.instance.dispose();
  }
}
