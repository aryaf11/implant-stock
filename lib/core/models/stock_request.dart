import '../constants/app_constants.dart';

class StockRequest {
  StockRequest({
    required this.id,
    required this.centerId,
    required this.brand,
    required this.type,
    required this.size,
    required this.qty,
    required this.status,
    required this.date,
    this.note = '',
    this.warehouseItemId = '',
  });

  final String id;
  final String centerId;
  final String brand;
  final String type;
  final String size;
  final int qty;
  String status; // pending | approved | rejected
  final String date;
  String note;
  String warehouseItemId;

  String get fullName => '$brand $type $size';

  Map<String, dynamic> toMap() => {
        'id': id,
        'center': centerId,
        'brand': brand,
        'type': type,
        'size': size,
        'qty': qty,
        'status': status,
        'date': date,
        'note': note,
        'reqKey': warehouseItemId,
        'fullName': fullName,
      };

  factory StockRequest.fromMap(Map<String, dynamic> m) => StockRequest(
        id: m['id'] as String? ?? '',
        centerId: resolveCenterId(m['center'] as String? ?? ''),
        brand: m['brand'] as String? ?? '',
        type: m['type'] as String? ?? '',
        size: m['size'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        status: m['status'] as String? ?? 'pending',
        date: m['date'] as String? ?? '',
        note: m['note'] as String? ?? '',
        warehouseItemId: m['reqKey'] as String? ?? '',
      );
}
