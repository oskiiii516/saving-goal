# -*- coding: utf-8 -*-
"""给 engine_test.dart 追加「按年统计」用例。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\app\test\engine_test.dart")
s = p.read_text(encoding="utf-8")

block = '''
  group('按年统计（每年存了多少）', () {
    // 目标 12000 / 2026-08 ~ 2027-07，每月 1000
    final g = SavingsGoal(
      id: 'g1',
      name: '旅行基金',
      targetCents: 1200000,
      startYm: '2026-08',
      deadlineYm: '2027-07',
      createdAt: DateTime(2026, 8, 1),
    );
    final deps = [
      dep('2026-08', 1000),
      dep('2026-09', 1000),
      dep('2026-10', 400),
      dep('2026-12', 2000),
      dep('2027-01', 1000),
    ];
    final plan = SavingsEngine.compute(g, deps, '2026-11');

    test('[20] 一年只算这一年，计划额来自月度时间表', () {
      final ys = SavingsEngine.yearlySummary(
        plans: [plan],
        deposits: deps,
        nowYm: '2026-11',
      );
      expect(ys.map((e) => e.year), [2026, 2027]);

      final y26 = ys[0];
      expect(y26.plannedCents, 500000); // 8/9/10/11/12 五个月 × 1000
      expect(y26.actualCents, 440000); // 1000+1000+400+2000
      expect(y26.depositsCount, 4);
      expect(y26.goalCount, 1);
      expect(y26.gapCents, 60000);
      expect(y26.isCurrent, isTrue);
      expect(y26.isFuture, isFalse);
      expect(y26.progress, closeTo(0.88, 0.0001));

      final y27 = ys[1];
      expect(y27.plannedCents, 700000); // 1~7 月
      expect(y27.actualCents, 100000);
      expect(y27.depositsCount, 1);
      expect(y27.isFuture, isTrue);
      expect(y27.met, isFalse);
    });

    test('[21] 期初已存不归属任何一年', () {
      final withInitial = SavingsGoal(
        id: 'g2',
        name: '米车',
        targetCents: 2000000,
        initialCents: 800000,
        startYm: '2026-11',
        deadlineYm: '2027-06',
      );
      final p2 = SavingsEngine.compute(withInitial, const [], '2026-11');
      final ys = SavingsEngine.yearlySummary(
        plans: [p2],
        deposits: const [],
        nowYm: '2026-11',
      );
      expect(ys.every((e) => e.actualCents == 0), isTrue);
      // 计划额只覆盖 (2000000 - 800000) = 1200000
      expect(ys.fold<int>(0, (a, e) => a + e.plannedCents), 1200000);
    });

    test('[22] 多个目标同一年合并', () {
      final g2 = SavingsGoal(
        id: 'g2',
        name: '新电脑',
        targetCents: 600000,
        startYm: '2026-09',
        deadlineYm: '2026-11',
      );
      final p1 = SavingsEngine.compute(g, deps, '2026-11');
      final p2 = SavingsEngine.compute(g2, const [], '2026-11');
      final ys = SavingsEngine.yearlySummary(
        plans: [p1, p2],
        deposits: deps,
        nowYm: '2026-11',
      );
      final y26 = ys.firstWhere((e) => e.year == 2026);
      expect(y26.plannedCents, 500000 + 600000); // 5000 + 3×2000
      expect(y26.goalCount, 2);
      expect(y26.actualCents, 440000);
    });

    test('[23] 只有流水没有计划的年份也要出现', () {
      final stray = [
        Deposit(
          id: 'x',
          goalId: 'g1',
          ym: '2025-06',
          amountCents: 123400,
          createdAt: DateTime(2025, 6, 1),
        ),
      ];
      final ys = SavingsEngine.yearlySummary(
        plans: [plan],
        deposits: stray,
        nowYm: '2026-11',
      );
      expect(ys.first.year, 2025);
      expect(ys.first.plannedCents, 0);
      expect(ys.first.actualCents, 123400);
      expect(ys.first.progress, 1.0); // 没计划但存过 = 完成
    });

    test('[24] 完全没数据时返回空', () {
      expect(
        SavingsEngine.yearlySummary(
            plans: const [], deposits: const [], nowYm: '2026-11'),
        isEmpty,
      );
    });
  });
'''

# 追加到 main 的最后一个 } 之前
idx = s.rstrip().rfind('}')
s = s.rstrip()[: idx] + block + "}\n"
p.write_text(s, encoding="utf-8")
print("tests appended")
