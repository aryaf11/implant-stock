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
];

String centerNameAr(String centerId) =>
    kCenters.firstWhere((c) => c.id == centerId, orElse: () => kCenters.first).nameAr;

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
