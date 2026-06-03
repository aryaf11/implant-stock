import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/stock_repository.dart';

class StockProvider extends ChangeNotifier {
  StockProvider(this._repo, {StockState? initialState}) : _state = initialState;

  final StockRepository _repo;
  StockState? _state;
  bool _loading = false;
  String? _error;
  String? _busyActionId;
  StreamSubscription<void>? _sub;
  bool _suppressReload = false;

  StockState? get state => _state;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get busyActionId => _busyActionId;

  bool isBusy(String id) => _busyActionId == id;

  void startListening() {
    _sub?.cancel();
    if (_state == null) {
      _loadOnce();
    }
    _sub = _repo.changes.listen((_) {
      if (!_suppressReload) _loadOnce(silent: true);
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _loadOnce({bool silent = false}) async {
    if (!silent) {
      _loading = _state == null;
      notifyListeners();
    }
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
    await _loadOnce(silent: _state != null);
  }

  Future<String?> approveRequest(String requestId) =>
      _runBusy(requestId, (s) => _repo.approveRequest(s, requestId));

  Future<String?> rejectRequest(String requestId) =>
      _runBusy(requestId, (s) => _repo.rejectRequest(s, requestId));

  Future<String?> approveReturn(String requestId) =>
      _runBusy('ret_$requestId', (s) => _repo.approveReturn(s, requestId));

  Future<String?> rejectReturn(String requestId) =>
      _runBusy('ret_$requestId', (s) => _repo.rejectReturn(s, requestId));

  Future<String?> _runBusy(
    String busyId,
    Future<void> Function(StockState) action,
  ) async {
    if (_state == null) return _error ?? 'لا توجد بيانات';
    _busyActionId = busyId;
    notifyListeners();
    final result = await run(action);
    _busyActionId = null;
    notifyListeners();
    return result;
  }

  Future<String?> run(Future<void> Function(StockState) action) async {
    if (_state == null) return _error ?? 'لا توجد بيانات';
    _suppressReload = true;
    try {
      await action(_state!);
      _error = null;
      notifyListeners();
      return null;
    } catch (e) {
      try {
        _state = await _repo.loadAll();
      } catch (_) {}
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
