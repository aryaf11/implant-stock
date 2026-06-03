import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/stock_repository.dart';
import 'core/services/user_repository.dart';
import 'core/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.init();
  await UserRepository.instance.init();

  final stockRepo = StockRepository();
  final initialStock = await stockRepo.loadAll();

  runApp(
    ImplantStockApp(
      stockRepository: stockRepo,
      initialStock: initialStock,
    ),
  );
}
