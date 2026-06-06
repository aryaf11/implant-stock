/// الفروع الأربعة لمراكز زراعة الأسنان.
class CenterInfo {
  const CenterInfo({required this.id, required this.nameAr});
  final String id;
  final String nameAr;
}

const kCenters = <CenterInfo>[
  CenterInfo(id: 'branch1', nameAr: 'الفرع الأول'),
  CenterInfo(id: 'branch2', nameAr: 'الفرع الثاني'),
  CenterInfo(id: 'branch3', nameAr: 'الفرع الثالث'),
  CenterInfo(id: 'branch4', nameAr: 'الفرع الرابع'),
  CenterInfo(id: 'drsaleh', nameAr: 'د. صالح'),
];

/// يحوّل معرّف الفرع أو اسمه العربي إلى branch1 … branch4
String resolveCenterId(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return kCenters.first.id;
  for (final c in kCenters) {
    if (c.id == v || c.nameAr == v) return c.id;
  }
  return v;
}

String centerNameAr(String centerId) {
  final id = resolveCenterId(centerId);
  for (final c in kCenters) {
    if (c.id == id) return c.nameAr;
  }
  return centerId;
}

/// الشركات الثلاث وأنواعها ومقاساتها.
class BrandCatalog {
  const BrandCatalog({
    required this.name,
    required this.types,
    required this.sizes,
  });

  final String name;
  final List<String> types;
  final List<String> sizes;
}

const kBrands = <BrandCatalog>[
  BrandCatalog(
    name: 'Straumann',
    types: [
      'BL (Bone Level)',
      'BLX (Bone Level Tapered)',
      'TL (Tissue Level)',
      'SLA Active',
      'Pro Arch',
    ],
    sizes: [
      '3.3×8',
      '3.3×10',
      '3.3×12',
      '4.1×8',
      '4.1×10',
      '4.1×12',
      '4.8×8',
      '4.8×10',
      '4.8×12',
      '6.5×8',
      '6.5×10',
    ],
  ),
  BrandCatalog(
    name: 'BioHorizons',
    types: [
      'Tapered Internal',
      'Laser-Lok',
      '3.0 Mini',
      'External Hex',
      'Predion',
    ],
    sizes: [
      '3.0×9',
      '3.0×11',
      '3.5×9',
      '3.5×11',
      '3.5×13',
      '4.5×9',
      '4.5×11',
      '4.5×13',
      '5.7×9',
      '5.7×11',
    ],
  ),
  BrandCatalog(
    name: 'Ora',
    types: ['Conical', 'Cylindrical', 'Short', 'Wide', 'Standard'],
    sizes: [
      '3.5×8',
      '3.5×10',
      '3.5×12',
      '4.0×8',
      '4.0×10',
      '4.0×12',
      '5.0×8',
      '5.0×10',
      '5.0×12',
    ],
  ),
];

BrandCatalog? brandByName(String name) {
  for (final b in kBrands) {
    if (b.name == name) return b;
  }
  return null;
}

/// أصناف المخزون — الزرعات أو مواد أخرى.
class StockCategory {
  const StockCategory({
    required this.id,
    required this.nameAr,
    this.storageBrand,
  });

  final String id;
  final String nameAr;

  /// قيمة حقل brand عند التخزين — null = واجهة شركات الزرعات.
  final String? storageBrand;

  bool get isImplants => id == 'implants';
}

const kStockCategories = <StockCategory>[
  StockCategory(id: 'implants', nameAr: 'زرعات'),
  StockCategory(id: 'accessories', nameAr: 'ملحقات', storageBrand: 'ملحقات'),
  StockCategory(id: 'tools', nameAr: 'أدوات', storageBrand: 'أدوات'),
  StockCategory(id: 'custom', nameAr: 'صنف آخر'),
];

bool isImplantBrand(String brand) =>
    kBrands.any((b) => b.name == brand);
