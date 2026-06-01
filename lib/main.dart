import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/user_repository.dart';
import 'core/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.init();
  await UserRepository.instance.init();
  runApp(const ImplantStockApp());
}
