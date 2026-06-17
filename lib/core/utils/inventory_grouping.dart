import '../constants/app_constants.dart';
import '../models/implant_item.dart';

/// تجميع المخزون: شركة ← نوع ← أصناف (مرتبة بالمقاس).
class BrandInventoryGroup {
  const BrandInventoryGroup({
    required this.brand,
    required this.totalQty,
    required this.types,
  });

  final String brand;
  final int totalQty;
  final List<TypeInventoryGroup> types;
}

class TypeInventoryGroup {
  const TypeInventoryGroup({
    required this.type,
    required this.totalQty,
    required this.items,
  });

  final String type;
  final int totalQty;
  final List<ImplantItem> items;
}

List<BrandInventoryGroup> groupInventoryByBrand(Iterable<ImplantItem> items) {
  final byBrand = <String, Map<String, List<ImplantItem>>>{};

  for (final item in items) {
    if (item.qty <= 0) continue;
    final brand = item.brand.trim().isEmpty ? 'غير محدد' : item.brand.trim();
    byBrand.putIfAbsent(brand, () => {});
    byBrand[brand]!.putIfAbsent(item.type, () => []).add(item);
  }

  final brandOrder = <String>[
    ...kBrands.map((b) => b.name),
    ...kStockCategories
        .where((c) => c.storageBrand != null)
        .map((c) => c.storageBrand!),
  ];

  int brandRank(String brand) {
    final i = brandOrder.indexOf(brand);
    return i >= 0 ? i : brandOrder.length;
  }

  final brands = byBrand.keys.toList()
    ..sort((a, b) {
      final ra = brandRank(a);
      final rb = brandRank(b);
      if (ra != rb) return ra.compareTo(rb);
      return a.compareTo(b);
    });

  return brands.map((brand) {
    final typeMap = byBrand[brand]!;
    final types = typeMap.entries.map((e) {
      final sorted = List<ImplantItem>.from(e.value)
        ..sort((a, b) => a.size.compareTo(b.size));
      final qty = sorted.fold<int>(0, (s, i) => s + i.qty);
      return TypeInventoryGroup(type: e.key, totalQty: qty, items: sorted);
    }).toList()
      ..sort((a, b) => a.type.compareTo(b.type));

    final total = types.fold<int>(0, (s, t) => s + t.totalQty);
    return BrandInventoryGroup(brand: brand, totalQty: total, types: types);
  }).toList();
}
