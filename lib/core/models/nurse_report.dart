class NurseReport {
  NurseReport({
    required this.id,
    required this.type,
    required this.centerId,
    required this.nurseUsername,
    required this.nurseName,
    required this.patientName,
    this.patientFileNo = '',
    this.implantInfo = '',
    this.qty = 0,
    required this.date,
    this.status = 'pending',
    this.note = '',
  });

  /// usage = استخدام زرعة | failure = فشل زرعة
  final String type;
  final String id;
  final String centerId;
  final String nurseUsername;
  final String nurseName;
  final String patientName;
  final String patientFileNo;
  final String implantInfo;
  final int qty;
  final String date;
  final String status;
  final String note;

  bool get isPending => status.trim().toLowerCase() == 'pending';
  bool get isUsage => type == 'usage';
  bool get isFailure => type == 'failure';

  String get title => isFailure ? 'فشل زرعة' : 'استخدام زرعة';

  String get subtitle {
    final parts = <String>[
      patientName,
      if (patientFileNo.isNotEmpty) 'ملف: $patientFileNo',
      if (implantInfo.isNotEmpty) implantInfo,
      if (isUsage && qty > 0) '$qty قطعة',
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'centerId': centerId,
        'nurseUsername': nurseUsername,
        'nurseName': nurseName,
        'patientName': patientName,
        'patientFileNo': patientFileNo,
        'implantInfo': implantInfo,
        'qty': qty,
        'date': date,
        'status': status,
        'note': note,
      };

  factory NurseReport.fromMap(Map<String, dynamic> m) => NurseReport(
        id: m['id'] as String? ?? '',
        type: m['type'] as String? ?? 'usage',
        centerId: m['centerId'] as String? ?? '',
        nurseUsername: m['nurseUsername'] as String? ?? '',
        nurseName: m['nurseName'] as String? ?? '',
        patientName: m['patientName'] as String? ?? '',
        patientFileNo: m['patientFileNo'] as String? ?? '',
        implantInfo: m['implantInfo'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        date: m['date'] as String? ?? '',
        status: m['status'] as String? ?? 'pending',
        note: m['note'] as String? ?? '',
      );
}
