class MovementLog {
  MovementLog({
    required this.date,
    required this.op,
    required this.type,
    required this.qty,
    required this.detail,
    this.center = '',
    this.brand = '',
    this.size = '',
    this.note = '',
  });

  final String date;
  final String op;
  final String type;
  final int qty;
  final String detail;
  final String center;
  final String brand;
  final String size;
  final String note;

  Map<String, dynamic> toMap() => {
        'date': date,
        'op': op,
        'type': type,
        'qty': qty,
        'detail': detail,
        'center': center,
        'brand': brand,
        'size': size,
        'note': note,
      };

  factory MovementLog.fromMap(Map<String, dynamic> m) => MovementLog(
        date: m['date'] as String? ?? '',
        op: m['op'] as String? ?? '',
        type: m['type'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        detail: m['detail'] as String? ?? '',
        center: m['center'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        size: m['size'] as String? ?? '',
        note: m['note'] as String? ?? '',
      );
}
