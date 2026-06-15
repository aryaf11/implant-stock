import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/models/app_user.dart';
import 'core/services/auth_service.dart';
import 'core/services/stock_repository.dart';
import 'core/services/user_repository.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/stock_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/nurse/nurse_shell.dart';
import 'screens/supervisor/supervisor_shell.dart';
import 'widgets/empty_state.dart';

class ImplantStockApp extends StatelessWidget {
  const ImplantStockApp({
    super.key,
    required this.stockRepository,
    this.initialStock,
  });

  final StockRepository stockRepository;
  final StockState? initialStock;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => UserRepository.instance),
        Provider(create: (_) => stockRepository),
        Provider(
          create: (ctx) => AuthService(ctx.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => StockProvider(
            ctx.read<StockRepository>(),
            initialState: initialStock,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'مخزون الزرعات',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _stockListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AuthProvider>().tryRestoreSession();
    });
  }

  void _syncStockListener(bool loggedIn) {
    final stock = context.read<StockProvider>();
    if (loggedIn && !_stockListening) {
      stock.startListening();
      _stockListening = true;
    } else if (!loggedIn && _stockListening) {
      stock.stopListening();
      _stockListening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _syncStockListener(auth.isLoggedIn);

    if (auth.isInitializing) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: LoadingView(message: 'جاري التحقق من الجلسة...'),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    final user = auth.user!;
    if (user.role == UserRole.admin) {
      return const AdminShell();
    }
    if (user.role == UserRole.nurse) {
      return const NurseShell();
    }
    return const SupervisorShell();
  }
}
