@Tags(['golden'])
library;

// 这组用例是「视觉预览」：把界面渲染成 PNG 给人看，并锁住像素防回归。
// 它依赖 Windows 上的微软雅黑字体（C:\Windows\Fonts\msyh.ttc），所以在 Linux CI 上
// 必然像素不一致 —— CI 用 `flutter test --exclude-tags golden` 跳过，本地照常跑。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saving_goal/core/engine.dart';
import 'package:saving_goal/data/database.dart';
import 'package:saving_goal/state/providers.dart';
import 'package:saving_goal/ui/goal_detail_page.dart';
import 'package:saving_goal/ui/goals_page.dart';
import 'package:saving_goal/ui/insights_page.dart';
import 'package:saving_goal/ui/settings_page.dart';
import 'package:saving_goal/ui/theme.dart';

/// 本机中文字体，仅用于本地 golden 预览（CI 无此文件时自动跳过）
/// 同时注册成 Roboto —— Material 在 Android 平台默认字体族就是它，
/// 否则未显式指定 fontFamily 的文本（AppBar 标题、按钮）会渲染成方块。
Future<void> _loadCjkFont() async {
  const candidates = [
    r'C:\Windows\Fonts\msyh.ttc',
    r'C:\Windows\Fonts\simhei.ttf',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final bytes = Uint8List.fromList(f.readAsBytesSync());
    for (final family in ['Microsoft YaHei', 'Roboto']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
    return;
  }
}

/// 图标字体：测试环境默认不带 MaterialIcons，图标会画成方块
Future<void> _loadIconFont() async {
  const path =
      r'D:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
  final f = File(path);
  if (!f.existsSync()) return;
  final bytes = Uint8List.fromList(f.readAsBytesSync());
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

GoalComputation _comp({
  required String id,
  required String name,
  required int target,
  required int saved,
  required int requiredThisMonth,
  required int paid,
  required GoalStatus status,
  required String basis,
  int monthsLeft = 9,
  String? finish = '2027-08',
  List<MonthPlan> months = const [],
}) {
  return GoalComputation(
    goalId: id,
    name: name,
    targetCents: target,
    initialCents: 0,
    savedTotalCents: saved,
    gapCents: target - saved,
    overCents: 0,
    progress: saved / target,
    totalMonths: 12,
    monthsLeftInclThis: monthsLeft,
    baseMonthlyCents: requiredThisMonth,
    arrearsCents: 0,
    requiredThisMonthCents: requiredThisMonth,
    paidThisMonthCents: paid,
    scheduledCumBeforeCents: 300000,
    basis: basis,
    status: status,
    projectedFinishYm: finish,
    months: months,
  );
}

/// 造一段月度明细，给统计页的曲线用
List<MonthPlan> _months({
  required String startYm,
  required int planned,
  required Map<int, int> actuals,
  int count = 12,
  String nowYm = '2026-11',
}) {
  final base = SavingsEngine.ymIndex(startYm);
  final now = SavingsEngine.ymIndex(nowYm);
  final out = <MonthPlan>[];
  var cumPlanned = 0;
  var cumActual = 0;
  for (var i = 0; i < count; i++) {
    final idx = base + i;
    final actual = actuals[i] ?? 0;
    cumPlanned += planned;
    cumActual += actual;
    out.add(MonthPlan(
      ym: SavingsEngine.indexYm(idx),
      plannedCents: planned,
      actualCents: actual,
      deltaCents: actual - planned,
      cumPlannedCents: cumPlanned,
      cumActualCents: cumActual,
      isPast: idx < now,
      isCurrent: idx == now,
      isFuture: idx > now,
    ));
  }
  return out;
}

Aggregate _agg() => Aggregate()
  ..requiredThisMonthCents = 257500
  ..paidThisMonthCents = 150000
  ..savedTotalCents = 390000
  ..targetCents = 2100000
  ..gapCents = 1710000
  ..behindCount = 1;

void main() {
  testWidgets('首页视觉预览', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 932 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final comps = [
      _comp(
        id: 'g1',
        name: '旅行基金',
        target: 1200000,
        saved: 240000,
        requiredThisMonth: 107500,
        paid: 0,
        status: GoalStatus.behind,
        basis: '基准 1000.00 + 补缴 75.00（600.00 摊 8 月）',
      ),
      _comp(
        id: 'g2',
        name: '新电脑',
        target: 900000,
        saved: 150000,
        requiredThisMonth: 150000,
        paid: 150000,
        status: GoalStatus.onTrack,
        basis: '重排：还差 7500.00 / 剩 6 个月',
        monthsLeft: 6,
        finish: '2027-04',
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        goalsProvider.overrideWith((ref) => Stream.value(const <GoalRow>[])),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const GoalsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/home.png'),
    );
  });

  testWidgets('首页浅色预览', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 932 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final comps = [
      _comp(
        id: 'g1',
        name: '旅行基金',
        target: 1200000,
        saved: 240000,
        requiredThisMonth: 107500,
        paid: 0,
        status: GoalStatus.behind,
        basis: '基准 1000.00 + 补缴 75.00（600.00 摊 8 月）',
      ),
      _comp(
        id: 'g2',
        name: '新电脑',
        target: 900000,
        saved: 150000,
        requiredThisMonth: 150000,
        paid: 150000,
        status: GoalStatus.onTrack,
        basis: '重排：还差 7500.00 / 剩 6 个月',
        monthsLeft: 6,
        finish: '2027-04',
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        goalsProvider.overrideWith((ref) => Stream.value(const <GoalRow>[])),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        home: const GoalsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/home_light.png'),
    );
  });

  testWidgets('统计页视觉预览', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 1500 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final comps = [
      _comp(
        id: 'g1',
        name: '旅行基金',
        target: 1200000,
        saved: 240000,
        requiredThisMonth: 107500,
        paid: 0,
        status: GoalStatus.behind,
        basis: '',
        months: _months(
          startYm: '2026-08',
          planned: 100000,
          actuals: {0: 100000, 1: 100000, 2: 40000},
        ),
      ),
      _comp(
        id: 'g2',
        name: '新电脑',
        target: 900000,
        saved: 150000,
        requiredThisMonth: 150000,
        paid: 150000,
        status: GoalStatus.onTrack,
        basis: '',
        monthsLeft: 6,
        finish: '2027-04',
        months: _months(
          startYm: '2026-09',
          planned: 150000,
          actuals: {0: 150000},
          count: 8,
        ),
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        nowYmProvider.overrideWithValue('2026-11'),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const InsightsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/insights.png'),
    );
  });

  testWidgets('详情页视觉预览', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 2400 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final goalRow = GoalRow(
      id: 'g1',
      name: '旅行基金',
      targetCents: 1200000,
      initialCents: 200000,
      startYm: '2026-08',
      deadlineYm: '2027-07',
      model: 'schedule',
      arrearsMode: 'spread',
      graceMonths: 0,
      priority: 0,
      payDay: 15,
      note: '日本 · 往返机票+住宿',
      archived: false,
      createdAt: DateTime(2026, 8, 1),
    );
    final deposits = [
      DepositRow(
        id: 'd1',
        goalId: 'g1',
        ym: '2026-08',
        amountCents: 100000,
        note: '首月',
        createdAt: DateTime(2026, 8, 2),
      ),
      DepositRow(
        id: 'd2',
        goalId: 'g1',
        ym: '2026-09',
        amountCents: 100000,
        note: '',
        createdAt: DateTime(2026, 9, 2),
      ),
      DepositRow(
        id: 'd3',
        goalId: 'g1',
        ym: '2026-10',
        amountCents: 40000,
        note: '这个月手紧',
        createdAt: DateTime(2026, 10, 2),
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        nowYmProvider.overrideWithValue('2026-11'),
        goalsProvider.overrideWith((ref) => Stream.value([goalRow])),
        depositsProvider.overrideWith((ref) => Stream.value(deposits)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const GoalDetailPage(goalId: 'g1'),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/detail.png'),
    );
  });

  testWidgets('左滑操作预览', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 932 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final comps = [
      _comp(
        id: 'g1',
        name: '旅行基金',
        target: 1200000,
        saved: 240000,
        requiredThisMonth: 107500,
        paid: 0,
        status: GoalStatus.behind,
        basis: '基准 1000.00 + 补缴 75.00（600.00 摊 8 月）',
      ),
    ];

    final rows = [
      GoalRow(
        id: 'g1',
        name: '旅行基金',
        targetCents: 1200000,
        initialCents: 0,
        startYm: '2026-08',
        deadlineYm: '2027-07',
        model: 'schedule',
        arrearsMode: 'spread',
        graceMonths: 0,
        priority: 0,
        payDay: 0,
        note: '',
        archived: false,
        createdAt: DateTime(2026, 8, 1),
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        goalsProvider.overrideWith((ref) => Stream.value(rows)),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const GoalsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    // 左滑露出操作按钮
    await tester.drag(find.byType(GoalCard).first, const Offset(-270, 0));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/home_swipe.png'),
    );
  });

  testWidgets('按每月能存多少规划（表单预览）', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 1000 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final comps = [
      _comp(
        id: 'g1',
        name: '米车',
        target: 20000000,
        saved: 0,
        requiredThisMonth: 2500000,
        paid: 0,
        status: GoalStatus.behind,
        basis: '基准 25000.00',
        monthsLeft: 8,
        finish: '2027-07',
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        goalsProvider.overrideWith((ref) => Stream.value(const <GoalRow>[])),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const GoalsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新目标'));
    await tester.pumpAndSettle();

    Finder fieldByLabel(String label) => find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(TextField),
          ),
          matching: find.byType(EditableText),
        );

    await tester.enterText(fieldByLabel('目标金额'), '200000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('先定月供'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldByLabel('每月能存多少'), '5000');
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/goal_form_monthly.png'),
    );
  });

  testWidgets('设置页预览（含关于）', (tester) async {
    await _loadCjkFont();
    await _loadIconFont();
    tester.view.physicalSize = const Size(430 * 2, 1180 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        goalsProvider.overrideWith((ref) => Stream.value(const <GoalRow>[])),
        computationsProvider.overrideWithValue(const []),
        aggregateProvider.overrideWithValue(_agg()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const SettingsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/settings.png'),
    );
  });
}
