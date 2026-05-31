import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/stock_repository.dart';

class StockProvider extends ChangeNotifier {
  StockProvider(this._repo);

  final StockRepository _repo;
  StockState? _state;
  bool _loading = true;
  String? _error;
  StreamSubscription<StockState>? _sub;

  StockState? get state => _state;
  bool get isLoading => _loading;
  String? get error => _error;

  void startListening() {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchAll().listen(
      (s) {
        _state = s;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> refresh() async {
    try {
      _state = await _repo.loadAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> run(Future<void> Function(StockState) action) async {
    if (_state == null) return 'لا توجد بيانات';
    try {
      await action(_state!);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
