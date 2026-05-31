import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/stock_repository.dart';
import '../providers/stock_provider.dart';
import 'empty_state.dart';

/// يعرض تحميلاً أو خطأاً أو المحتوى عند جاهزية المخزون.
class StockDataGate extends StatelessWidget {
  const StockDataGate({
    super.key,
    required this.builder,
    this.loadingMessage = 'جاري تحميل البيانات...',
  });

  final Widget Function(BuildContext context, StockState state) builder;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    if (stock.isLoading && stock.state == null) {
      return LoadingView(message: loadingMessage);
    }
    if (stock.state == null) {
      return EmptyState(
        message: stock.error ?? 'تعذّر تحميل البيانات',
        subtitle: 'اسحب للأسفل أو اضغط إعادة المحاولة',
        icon: Icons.cloud_off_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: stock.refresh,
      child: builder(context, stock.state!),
    );
  }
}
