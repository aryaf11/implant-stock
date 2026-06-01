import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/stock_repository.dart';

class StockProvider extends ChangeNotifier {
  StockProvider(this._repo);

  final StockRepository _repo;
  StockState? _state;
  bool _loading = false;
  String? _error;
  StreamSubscription<void>? _sub;
  bool _suppressReload = false;

  StockState? get state => _state;
  bool get isLoading => _loading;
  String? get error => _error;

  void startListening() {
    _sub?.cancel();
    _loadOnce();
    _sub = _repo.changes.listen((_) {
      if (!_suppressReload) _loadOnce();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _loadOnce() async {
    _loading = _state == null;
    notifyListeners();
    try {
      _state = await _repo.loadAll();
      _error = null;
    } catch (e, st) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('[StockProvider] $e\n$st');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadOnce();
  }

  /// تنفيذ عملية ثم إعادة تحميل البيانات لتحديث الواجهة فوراً.
  Future<String?> run(Future<void> Function(StockState) action) async {
    if (_state == null) return _error ?? 'لا توجد بيانات';
    _suppressReload = true;
    try {
      await action(_state!);
      _state = await _repo.loadAll();
      _error = null;
      notifyListeners();
      return null;
    } catch (e) {
      _state = await _repo.loadAll();
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _suppressReload = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
