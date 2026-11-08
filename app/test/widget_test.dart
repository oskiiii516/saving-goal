import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saving_goal/core/engine.dart';
import 'package:saving_goal/ui/goals_page.dart';
import 'package:saving_goal/ui/theme.dart';
import 'package:saving_goal/ui/widgets.dart';

/// 造一个可控的目标计算对象，直接喂给卡片，不碰数据库
GoalComputation fakeComp({
  int target = 1200000,
  int saved = 240000,
  int required = 100000,
  int paid = 0,
  GoalStatus status = GoalStatus.behind,
  String basis = '基准 1000.00',
}) {
  return GoalComputation(
    goalId: 'g1',
    name: '旅行基金',
    targetCents: target,
    initialCents: 0,
    savedTotalCents: saved,
    gapCents: target - saved,
    overCents: 0,
    progress: saved / target,
    totalMonths: 12,
    monthsLeftInclThis: 9,
    baseMonthlyCents: 100000,
    arrearsCents: 0,
    requiredThisMonthCents: required,
    paidThisMonthCents: paid,
    scheduledCumBeforeCents: 300000,
    basis: basis,
    status: status,
    projectedFinishYm: '2027-01',
    months: const [],
  );
}

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('目标卡展示应存/已存/还差与状态', (tester) async {
    await tester.pumpWidget(wrap(GoalCard(plan: fakeComp())));
    expect(find.text('旅行基金'), findsOneWidget);
    expect(find.text('1000.00'), findsWidgets); // 本月应存
    expect(find.text('0.00'), findsWidgets); // 本月已存
    expect(find.text('9600.00'), findsOneWidget); // 还差
    expect(find.text('本月欠缴'), findsOneWidget);
    expect(find.text('还差'), findsOneWidget);
  });

  testWidgets('达标目标不显示补缴提示', (tester) async {
    await tester.pumpWidget(wrap(GoalCard(
      plan: fakeComp(
        required: 100000,
        paid: 100000,
        status: GoalStatus.onTrack,
      ),
    )));
    expect(find.text('按计划'), findsOneWidget);
    expect(find.text('本月欠缴'), findsNothing);
  });

  testWidgets('进度条按比例填充且不越界', (tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
      width: 200,
      child: SlimProgress(value: 1.8),
    )));
    await tester.pumpAndSettle();
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0);
  });

  testWidgets('状态徽章文案齐全', (tester) async {
    for (final s in GoalStatus.values) {
      await tester.pumpWidget(wrap(StatusChip(status: s)));
      expect(find.text(s.label), findsOneWidget);
    }
  });
}
