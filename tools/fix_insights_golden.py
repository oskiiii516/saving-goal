# -*- coding: utf-8 -*-
"""统计页 golden 补上流水数据，让「按年存钱」区块有内容。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\app\test\preview_golden_test.dart")
s = p.read_text(encoding="utf-8")

old = """    await tester.pumpWidget(ProviderScope(
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
    ));"""

new = """    final deposits = [
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
      DepositRow(
        id: 'd4',
        goalId: 'g2',
        ym: '2026-09',
        amountCents: 150000,
        note: '',
        createdAt: DateTime(2026, 9, 3),
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        nowYmProvider.overrideWithValue('2026-11'),
        computationsProvider.overrideWithValue(comps),
        aggregateProvider.overrideWithValue(_agg()),
        depositsProvider.overrideWith((ref) => Stream.value(deposits)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.dark),
        home: const InsightsPage(),
      ),
    ));"""

assert old in s
s = s.replace(old, new, 1)
p.write_text(s, encoding="utf-8")
print("ok")
