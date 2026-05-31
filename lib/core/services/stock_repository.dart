import 'dart:async';

import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/implant_item.dart';
import '../models/movement_log.dart';
import '../models/return_request.dart';
import '../models/stock_request.dart';
import '../storage/local_database.dart';
import '../utils/date_utils.dart';

class StockRepository {
  StockRepository({LocalDatabase? db}) : _db = db ?? LocalDatabase.instance;

  final LocalDatabase _db;
  final _uuid = const Uuid();

  String _newId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      _uuid.v4().substring(0, 5);

  Future<StockState> loadAll() async {
    final warehouse = await _loadWarehouse();
    final centers = await _loadCenters();
    final log = await _loadLog();
    final reqs = await _loadRequests();
    final returns = await _loadReturnRequests();
    return StockState(
      warehouse: warehouse,
      centers: centers,
      movementLog: log,
      requests: reqs,
      returnRequests: returns,
    );
  }

  Stream<StockState> watchAll() async* {
    yield await loadAll();
    await for (final _ in _db.changes) {
      yield await loadAll();
    }
  }

  Future<List<ImplantItem>> _loadWarehouse() async {
    final snap = await _db.doc('warehouseStock');
    if (snap == null) return [];
    final items = snap['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ImplantItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, List<ImplantItem>>> _loadCenters() async {
    final snap = await _db.doc('centerStock');
    final map = <String, List<ImplantItem>>{};
    for (final c in kCenters) {
      map[c.id] = [];
    }
    if (snap == null) return map;
    final data = snap['data'] as Map<String, dynamic>? ?? {};
    for (final entry in data.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      map[entry.key] = list
          .map((e) => ImplantItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    for (final c in kCenters) {
      map.putIfAbsent(c.id, () => []);
    }
    return map;
  }

  Future<List<MovementLog>> _loadLog() async {
    final snap = await _db.doc('movementLog');
    if (snap == null) return [];
    final items = snap['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => MovementLog.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<StockRequest>> _loadRequests() async {
    final snap = await _db.doc('requests');
    if (snap == null) return [];
    final items = snap['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => StockRequest.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ReturnRequest>> _loadReturnRequests() async {
    final snap = await _db.doc('returnRequests');
    if (snap == null) return [];
    final items = snap['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ReturnRequest.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist(StockState state) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    await _db.putAll({
      'warehouseStock': {
        'items': state.warehouse.map((e) => e.toMap()).toList(),
        'updated': ts,
      },
      'centerStock': {
        'data': state.centers.map(
          (k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()),
        ),
        'updated': ts,
      },
      'movementLog': {
        'items': state.movementLog.take(500).map((e) => e.toMap()).toList(),
        'updated': ts,
      },
      'requests': {
        'items': state.requests.map((e) => e.toMap()).toList(),
        'updated': ts,
      },
      'returnRequests': {
        'items': state.returnRequests.map((e) => e.toMap()).toList(),
        'updated': ts,
      },
    });
  }

  void _log(StockState s, MovementLog entry) {
    s.movementLog.insert(0, entry);
    if (s.movementLog.length > 500) {
      s.movementLog.removeRange(500, s.movementLog.length);
    }
  }

  Future<void> addToWarehouse(
    StockState state, {
    required String brand,
    required String type,
    required String size,
    required int qty,
    String lot = '',
    String expiry = '',
    int threshold = 3,
  }) async {
    final existing = state.warehouse.where(
      (i) => i.brand == brand && i.type == type && i.size == size && i.lot == lot,
    );
    if (existing.isNotEmpty) {
      existing.first.qty += qty;
      existing.first.threshold = threshold;
    } else {
      state.warehouse.add(ImplantItem(
        id: _newId(),
        brand: brand,
        type: type,
        size: size,
        qty: qty,
        lot: lot,
        expiry: expiry,
        threshold: threshold,
      ));
    }
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'إضافة',
        type: '$brand $type $size',
        qty: qty,
        detail: 'تمت الإضافة للمستودع',
        center: 'المستودع',
        brand: brand,
        size: size,
      ),
    );
    await _persist(state);
  }

  Future<void> dispatchToCenter(
    StockState state, {
    required String warehouseItemId,
    required String centerId,
    required int qty,
    String note = '',
  }) async {
    final idx = state.warehouse.indexWhere((i) => i.id == warehouseItemId);
    if (idx < 0) throw Exception('الصنف غير موجود');
    final item = state.warehouse[idx];
    if (qty > item.qty) throw Exception('الكمية أكبر من المتاح');
    item.qty -= qty;
    if (item.qty == 0) state.warehouse.removeAt(idx);

    final centerList = state.centers[centerId]!;
    final ce = centerList.where(
      (i) =>
          i.type == item.type &&
          i.brand == item.brand &&
          i.size == item.size &&
          i.lot == item.lot,
    );
    if (ce.isNotEmpty) {
      ce.first.qty += qty;
    } else {
      centerList.add(ImplantItem(
        id: _newId(),
        brand: item.brand,
        type: item.type,
        size: item.size,
        qty: qty,
        lot: item.lot,
        expiry: item.expiry,
      ));
    }

    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'صرف',
        type: item.fullName,
        qty: qty,
        detail: 'إلى ${centerNameAr(centerId)}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: note,
      ),
    );
    await _persist(state);
  }

  Future<void> returnFromCenter(
    StockState state, {
    required String centerId,
    required String itemId,
    required int qty,
    String reason = '',
  }) async {
    final list = state.centers[centerId]!;
    final idx = list.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw Exception('الصنف غير موجود في المركز');
    final item = list[idx];
    if (qty > item.qty) throw Exception('الكمية أكبر من المتاح');
    item.qty -= qty;
    if (item.qty == 0) list.removeAt(idx);

    final we = state.warehouse.where(
      (i) =>
          i.type == item.type &&
          i.brand == item.brand &&
          i.size == item.size &&
          i.lot == item.lot,
    );
    if (we.isNotEmpty) {
      we.first.qty += qty;
    } else {
      state.warehouse.add(ImplantItem(
        id: _newId(),
        brand: item.brand,
        type: item.type,
        size: item.size,
        qty: qty,
        lot: item.lot,
        expiry: item.expiry,
        threshold: 3,
      ));
    }

    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'استرجاع',
        type: item.fullName,
        qty: qty,
        detail: 'من ${centerNameAr(centerId)}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: reason,
      ),
    );
    await _persist(state);
  }

  Future<void> approveRequest(StockState state, String requestId) async {
    final r = state.requests.firstWhere((x) => x.id == requestId);
    final wh = state.warehouse.where(
      (i) => i.brand == r.brand && i.type == r.type && i.size == r.size,
    );
    if (wh.isEmpty || wh.first.qty < r.qty) {
      throw Exception('لا توجد كمية كافية في المستودع');
    }
    final item = wh.first;
    item.qty -= r.qty;
    if (item.qty == 0) state.warehouse.remove(item);

    final centerList = state.centers[r.centerId]!;
    final ce = centerList.where(
      (i) => i.type == r.type && i.brand == r.brand && i.size == r.size,
    );
    if (ce.isNotEmpty) {
      ce.first.qty += r.qty;
    } else {
      centerList.add(ImplantItem(
        id: _newId(),
        brand: r.brand,
        type: r.type,
        size: r.size,
        qty: r.qty,
      ));
    }

    r.status = 'approved';
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'صرف',
        type: r.fullName,
        qty: r.qty,
        detail: 'إلى ${centerNameAr(r.centerId)} (موافقة طلب)',
        center: r.centerId,
        brand: r.brand,
        size: r.size,
        note: r.note,
      ),
    );
    await _persist(state);
  }

  Future<void> rejectRequest(StockState state, String requestId) async {
    final r = state.requests.firstWhere((x) => x.id == requestId);
    r.status = 'rejected';
    await _persist(state);
  }

  Future<void> approveReturn(StockState state, String requestId) async {
    final r = state.returnRequests.firstWhere((x) => x.id == requestId);
    final list = state.centers[r.centerId]!;
    final idx = list.indexWhere((i) => i.id == r.itemId);
    if (idx < 0) throw Exception('الصنف غير موجود في المركز');
    final item = list[idx];
    if (r.qty > item.qty) throw Exception('كمية غير كافية');
    item.qty -= r.qty;
    if (item.qty == 0) list.removeAt(idx);

    final we = state.warehouse.where(
      (i) =>
          i.type == r.itemType &&
          i.brand == r.brand &&
          i.size == r.size &&
          i.lot == r.lot,
    );
    if (we.isNotEmpty) {
      we.first.qty += r.qty;
    } else {
      state.warehouse.add(ImplantItem(
        id: _newId(),
        brand: r.brand,
        type: r.itemType,
        size: r.size,
        qty: r.qty,
        lot: r.lot,
        expiry: r.expiry,
        threshold: 3,
      ));
    }

    r.status = 'approved';
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'استرجاع',
        type: r.fullName,
        qty: r.qty,
        detail: 'من ${centerNameAr(r.centerId)} (موافقة)',
        center: r.centerId,
        brand: r.brand,
        size: r.size,
        note: r.reason,
      ),
    );
    await _persist(state);
  }

  Future<void> rejectReturn(StockState state, String requestId) async {
    final r = state.returnRequests.firstWhere((x) => x.id == requestId);
    r.status = 'rejected';
    await _persist(state);
  }

  Future<void> sendRequest(
    StockState state, {
    required String centerId,
    required String warehouseItemId,
    required int qty,
    String note = '',
  }) async {
    final item = state.warehouse.firstWhere((i) => i.id == warehouseItemId);
    if (item.qty == 0 || qty > item.qty) {
      throw Exception('الكمية غير متاحة');
    }
    state.requests.insert(
      0,
      StockRequest(
        id: _newId(),
        centerId: centerId,
        brand: item.brand,
        type: item.type,
        size: item.size,
        qty: qty,
        status: 'pending',
        date: todayAr(),
        note: note,
        warehouseItemId: warehouseItemId,
      ),
    );
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'طلب',
        type: item.fullName,
        qty: qty,
        detail: 'طلب من ${centerNameAr(centerId)}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: note,
      ),
    );
    await _persist(state);
  }

  Future<void> useImplant(
    StockState state, {
    required String centerId,
    required String itemId,
    required int qty,
    String patient = '',
  }) async {
    final list = state.centers[centerId]!;
    final idx = list.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw Exception('الصنف غير موجود');
    final item = list[idx];
    if (qty > item.qty) throw Exception('الكمية أكبر من المتاح');
    item.qty -= qty;
    if (item.qty == 0) list.removeAt(idx);

    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'استخدام',
        type: item.fullName,
        qty: qty,
        detail:
            '${centerNameAr(centerId)}${patient.isNotEmpty ? ' - $patient' : ''}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: patient,
      ),
    );
    await _persist(state);
  }

  Future<void> submitReturnRequest(
    StockState state, {
    required String centerId,
    required String itemId,
    required int qty,
    String reason = '',
  }) async {
    final list = state.centers[centerId]!;
    final item = list.firstWhere((i) => i.id == itemId);
    if (qty > item.qty) throw Exception('الكمية أكبر من المتاح');

    state.returnRequests.insert(
      0,
      ReturnRequest(
        id: _newId(),
        centerId: centerId,
        brand: item.brand,
        itemType: item.type,
        size: item.size,
        qty: qty,
        status: 'pending',
        date: todayAr(),
        itemId: itemId,
        lot: item.lot,
        expiry: item.expiry,
        reason: reason,
      ),
    );
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'طلب استرجاع',
        type: item.fullName,
        qty: qty,
        detail: 'طلب من ${centerNameAr(centerId)}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: reason,
      ),
    );
    await _persist(state);
  }
}

class StockState {
  StockState({
    required this.warehouse,
    required this.centers,
    required this.movementLog,
    required this.requests,
    required this.returnRequests,
  });

  List<ImplantItem> warehouse;
  Map<String, List<ImplantItem>> centers;
  List<MovementLog> movementLog;
  List<StockRequest> requests;
  List<ReturnRequest> returnRequests;

  List<StockRequest> get pendingRequests =>
      requests.where((r) => r.status == 'pending').toList();

  List<ReturnRequest> get pendingReturnRequests =>
      returnRequests.where((r) => r.status == 'pending').toList();

  int get totalWarehouseQty => warehouse.fold<int>(0, (s, i) => s + i.qty);

  int totalCentersQty() {
    var t = 0;
    for (final list in centers.values) {
      for (final i in list) {
        t += i.qty;
      }
    }
    return t;
  }
}
