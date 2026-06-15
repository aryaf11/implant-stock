import 'dart:async';

import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/implant_item.dart';
import '../models/movement_log.dart';
import '../models/nurse_report.dart';
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
    final snap = _db.readSnapshot();
    return _stateFromSnapshot(snap);
  }

  StockState _stateFromSnapshot(Map<String, dynamic> snap) {
    final warehouseSnap = snap['warehouseStock'];
    final warehouse = warehouseSnap is Map
        ? ((warehouseSnap['items'] as List<dynamic>? ?? [])
            .map((e) =>
                ImplantItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList())
        : <ImplantItem>[];

    final centers = _parseCenters(
      snap['centerStock'] is Map ? snap['centerStock'] as Map : null,
    );

    final logSnap = snap['movementLog'];
    final log = logSnap is Map
        ? ((logSnap['items'] as List<dynamic>? ?? [])
            .map((e) =>
                MovementLog.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList())
        : <MovementLog>[];

    final reqSnap = snap['requests'];
    final reqs = reqSnap is Map
        ? ((reqSnap['items'] as List<dynamic>? ?? [])
            .map((e) =>
                StockRequest.fromMap(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.status.trim().toLowerCase() == 'pending')
            .toList())
        : <StockRequest>[];

    final retSnap = snap['returnRequests'];
    final returns = retSnap is Map
        ? ((retSnap['items'] as List<dynamic>? ?? [])
            .map((e) =>
                ReturnRequest.fromMap(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.status.trim().toLowerCase() == 'pending')
            .toList())
        : <ReturnRequest>[];

    final nurseSnap = snap['nurseReports'];
    final nurseReports = nurseSnap is Map
        ? ((nurseSnap['items'] as List<dynamic>? ?? [])
            .map((e) =>
                NurseReport.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList())
        : <NurseReport>[];

    return StockState(
      warehouse: warehouse,
      centers: centers,
      movementLog: log,
      requests: reqs,
      returnRequests: returns,
      nurseReports: nurseReports,
    );
  }

  Map<String, List<ImplantItem>> _parseCenters(Map<dynamic, dynamic>? snap) {
    final map = <String, List<ImplantItem>>{};
    for (final c in kCenters) {
      map[c.id] = [];
    }
    if (snap == null) return map;
    final data = snap['data'];
    if (data is! Map) return map;
    for (final entry in data.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      map[entry.key.toString()] = list
          .map((e) => ImplantItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    for (final c in kCenters) {
      map.putIfAbsent(c.id, () => []);
    }
    return map;
  }

  Stream<void> get changes => _db.changes;

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
      'nurseReports': {
        'items': state.nurseReports.map((e) => e.toMap()).toList(),
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

  ImplantItem? _warehouseForRequest(StockState state, StockRequest r) {
    if (r.warehouseItemId.isNotEmpty) {
      for (final i in state.warehouse) {
        if (i.id == r.warehouseItemId) return i;
      }
    }
    for (final i in state.warehouse) {
      if (i.brand == r.brand && i.type == r.type && i.size == r.size) {
        return i;
      }
    }
    return null;
  }

  Future<void> approveRequest(StockState state, String requestId) async {
    final idx = state.requests.indexWhere((x) => x.id == requestId);
    if (idx < 0) throw Exception('الطلب غير موجود');
    final r = state.requests[idx];
    final centerId = resolveCenterId(r.centerId);

    final item = _warehouseForRequest(state, r);
    if (item == null || item.qty < r.qty) {
      throw Exception('لا توجد كمية كافية في المستودع');
    }
    item.qty -= r.qty;
    if (item.qty == 0) state.warehouse.remove(item);

    final centerList = state.centers[centerId] ??= [];
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
        lot: item.lot,
        expiry: item.expiry,
      ));
    }

    state.requests.removeAt(idx);
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'صرف',
        type: r.fullName,
        qty: r.qty,
        detail: 'إلى ${centerNameAr(centerId)} (موافقة طلب)',
        center: centerId,
        brand: r.brand,
        size: r.size,
        note: r.note,
      ),
    );
    await _persist(state);
  }

  Future<void> rejectRequest(StockState state, String requestId) async {
    final idx = state.requests.indexWhere((x) => x.id == requestId);
    if (idx < 0) throw Exception('الطلب غير موجود');
    state.requests.removeAt(idx);
    await _persist(state);
  }

  Future<void> approveReturn(StockState state, String requestId) async {
    final rIdx = state.returnRequests.indexWhere((x) => x.id == requestId);
    if (rIdx < 0) throw Exception('الطلب غير موجود');
    final r = state.returnRequests[rIdx];
    final centerId = resolveCenterId(r.centerId);
    final list = state.centers[centerId] ??= [];
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

    state.returnRequests.removeAt(rIdx);
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'استرجاع',
        type: r.fullName,
        qty: r.qty,
        detail: 'من ${centerNameAr(centerId)} (موافقة)',
        center: centerId,
        brand: r.brand,
        size: r.size,
        note: r.reason,
      ),
    );
    await _persist(state);
  }

  Future<void> rejectReturn(StockState state, String requestId) async {
    final rIdx = state.returnRequests.indexWhere((x) => x.id == requestId);
    if (rIdx < 0) throw Exception('الطلب غير موجود');
    state.returnRequests.removeAt(rIdx);
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

  Future<void> submitNurseUsage(
    StockState state, {
    required String centerId,
    required String nurseUsername,
    required String nurseName,
    required String itemId,
    required int qty,
    required String patientName,
    String patientFileNo = '',
  }) async {
    if (patientName.trim().isEmpty) {
      throw Exception('اسم المريض مطلوب');
    }
    final list = state.centers[centerId]!;
    final idx = list.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw Exception('الصنف غير موجود');
    final item = list[idx];
    if (qty > item.qty) throw Exception('الكمية أكبر من المتاح');
    item.qty -= qty;
    if (item.qty == 0) list.removeAt(idx);

    final patient = patientName.trim();
    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'استخدام',
        type: item.fullName,
        qty: qty,
        detail:
            '${centerNameAr(centerId)} - $patient${patientFileNo.isNotEmpty ? ' (ملف $patientFileNo)' : ''}',
        center: centerId,
        brand: item.brand,
        size: item.size,
        note: patient,
      ),
    );

    state.nurseReports.insert(
      0,
      NurseReport(
        id: _newId(),
        type: 'usage',
        centerId: centerId,
        nurseUsername: nurseUsername,
        nurseName: nurseName,
        patientName: patient,
        patientFileNo: patientFileNo.trim(),
        implantInfo: item.fullName,
        qty: qty,
        date: todayAr(),
      ),
    );
    await _persist(state);
  }

  Future<void> submitImplantFailure(
    StockState state, {
    required String centerId,
    required String nurseUsername,
    required String nurseName,
    required String patientName,
    required String patientFileNo,
    String implantInfo = '',
    String note = '',
  }) async {
    if (patientName.trim().isEmpty) {
      throw Exception('اسم المريض مطلوب');
    }
    if (patientFileNo.trim().isEmpty) {
      throw Exception('رقم ملف المريض مطلوب');
    }

    state.nurseReports.insert(
      0,
      NurseReport(
        id: _newId(),
        type: 'failure',
        centerId: centerId,
        nurseUsername: nurseUsername,
        nurseName: nurseName,
        patientName: patientName.trim(),
        patientFileNo: patientFileNo.trim(),
        implantInfo: implantInfo.trim(),
        date: todayAr(),
        note: note.trim(),
      ),
    );

    _log(
      state,
      MovementLog(
        date: todayAr(),
        op: 'فشل زرعة',
        type: implantInfo.trim().isEmpty ? 'غير محدد' : implantInfo.trim(),
        qty: 0,
        detail:
            'مريض: ${patientName.trim()} · ملف: ${patientFileNo.trim()}${note.trim().isNotEmpty ? ' · $note' : ''}',
        center: centerId,
        note: note.trim(),
      ),
    );
    await _persist(state);
  }

  Future<void> dismissNurseReport(StockState state, String reportId) async {
    final i = state.nurseReports.indexWhere((r) => r.id == reportId);
    if (i < 0) throw Exception('التقرير غير موجود');
    state.nurseReports.removeAt(i);
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
    required this.nurseReports,
  });

  List<ImplantItem> warehouse;
  Map<String, List<ImplantItem>> centers;
  List<MovementLog> movementLog;
  List<StockRequest> requests;
  List<ReturnRequest> returnRequests;
  List<NurseReport> nurseReports;

  List<StockRequest> get pendingRequests => requests
      .where((r) => r.status.trim().toLowerCase() == 'pending')
      .toList();

  List<ReturnRequest> get pendingReturnRequests => returnRequests
      .where((r) => r.status.trim().toLowerCase() == 'pending')
      .toList();

  List<NurseReport> get pendingNurseReports =>
      nurseReports.where((r) => r.isPending).toList();

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
