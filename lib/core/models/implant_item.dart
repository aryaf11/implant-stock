class ImplantItem {
  ImplantItem({
    required this.id,
    required this.brand,
    required this.type,
    required this.size,
    required this.qty,
    this.lot = '',
    this.expiry = '',
    this.threshold = 3,
  });

  final String id;
  final String brand;
  final String type;
  final String size;
  int qty;
  String lot;
  String expiry;
  int threshold;

  String get fullName => '$brand $type $size';

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'type': type,
        'size': size,
        'qty': qty,
        'lot': lot,
        'expiry': expiry,
        'threshold': threshold,
      };

  factory ImplantItem.fromMap(Map<String, dynamic> m) => ImplantItem(
        id: m['id'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        type: m['type'] as String? ?? '',
        size: m['size'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        lot: m['lot'] as String? ?? '',
        expiry: m['expiry'] as String? ?? '',
        threshold: (m['threshold'] as num?)?.toInt() ?? 3,
      );
}
