import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/logger.dart';
import 'data/db/hive_provider.dart';
import 'features/purchase/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveDb.init();
  AppLogger.init();

  runApp(const ProviderScope(child: BoardKitApp()));
}

class BoardKitApp extends ConsumerWidget {
  const BoardKitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

      // 購入サービスを起動時に初期化（StoreKit接続・商品情報取得）
    ref.watch(purchaseServiceProvider);

    return MaterialApp.router(
      title: 'BoardKit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en')],
    );
  }
}
