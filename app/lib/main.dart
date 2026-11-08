import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_info.dart';
import 'state/providers.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const SavingsApp(),
    ),
  );
}

class SavingsApp extends ConsumerStatefulWidget {
  const SavingsApp({super.key});

  @override
  ConsumerState<SavingsApp> createState() => _SavingsAppState();
}

class _SavingsAppState extends ConsumerState<SavingsApp> {
  @override
  void initState() {
    super.initState();
    // 启动时按当前设置排一次提醒（内部会 lazy init 插件与时区）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).syncReminder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // 数据一变，就把最新欠缴金额写进提醒文案
    ref.listen(aggregateProvider, (prev, next) {
      if (prev != null &&
          next.requiredThisMonthCents == prev.requiredThisMonthCents &&
          next.paidThisMonthCents == prev.paidThisMonthCents &&
          next.behindCount == prev.behindCount) {
        return;
      }
      ref.read(settingsProvider.notifier).syncReminder();
    });

    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // 锁住文字缩放上限，避免超大字号把卡片挤爆
        final scaler = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}
