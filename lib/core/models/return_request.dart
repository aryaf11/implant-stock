class ReturnRequest {
  ReturnRequest({
    required this.id,
    required this.centerId,
    required this.brand,
    required this.itemType,
    required this.size,
    required this.qty,
    required this.status,
    required this.date,
    required this.itemId,
    this.lot = '',
    this.expiry = '',
    this.reason = '',
  });

  final String id;
  final String centerId;
  final String brand;
  final String itemType;
  final String size;
  final int qty;
  String status;
  final String date;
  final String itemId;
  String lot;
  String expiry;
  String reason;

  String get fullName => '$brand $itemType $size';

  Map<String, dynamic> toMap() => {
        'id': id,
        'center': centerId,
        'brand': brand,
        'itemType': itemType,
        'size': size,
        'qty': qty,
        'status': status,
        'date': date,
        'itemId': itemId,
        'lot': lot,
        'expiry': expiry,
        'reason': reason,
        'fullName': fullName,
        'type': 'return',
      };

  factory ReturnRequest.fromMap(Map<String, dynamic> m) => ReturnRequest(
        id: m['id'] as String? ?? '',
        centerId: m['center'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        itemType: m['itemType'] as String? ?? '',
        size: m['size'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        status: m['status'] as String? ?? 'pending',
        date: m['date'] as String? ?? '',
        itemId: m['itemId'] as String? ?? '',
        lot: m['lot'] as String? ?? '',
        expiry: m['expiry'] as String? ?? '',
        reason: m['reason'] as String? ?? '',
      );
}
