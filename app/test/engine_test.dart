import 'package:flutter_test/flutter_test.dart';
import 'package:saving_goal/core/engine.dart';

/// 与 engine/engine.test.mjs 一一对应的算法验收用例。
/// 目标 12000 元 / 2026-01 ~ 2026-12，基准月供 1000。
void main() {
  final g1 = SavingsGoal(
    id: 'g1',
    name: '旅行基金',
    targetCents: 1200000,
    startYm: '2026-01',
    deadlineYm: '2026-12',
    createdAt: DateTime(2026, 1, 1),
  );

  Deposit dep(String ym, num yuan, {String goalId = 'g1', String id = 'd'}) =>
      Deposit(
        id: '$id-$ym',
        goalId: goalId,
        ym: ym,
        amountCents: (yuan * 100).round(),
        createdAt: DateTime(2026, 1, 1),
      );

  group('时间工具', () {
    test('月序号与格式化', () {
      expect(SavingsEngine.monthsInclusive('2026-01', '2026-12'), 12);
      expect(SavingsEngine.monthsInclusive('2026-11', '2027-02'), 4);
      expect(SavingsEngine.indexYm(SavingsEngine.ymIndex('2026-01')), '2026-01');
      expect(SavingsEngine.indexYm(SavingsEngine.ymIndex('2027-01')), '2027-01');
      expect(SavingsEngine.fmt(100000), '1000.00');
      expect(SavingsEngine.fmt(-60000), '-600.00');
      expect(SavingsEngine.fmtMoney(1200000), '¥12,000.00');
      expect(SavingsEngine.todayYm(DateTime(2026, 11, 8)), '2026-11');
    });
  });

  group('核心算法', () {
    test('[1] 按时存 → 按计划', () {
      final p = SavingsEngine.compute(
        g1,
        [dep('2026-01', 1000), dep('2026-02', 1000)],
        '2026-02',
      );
      expect(p.requiredThisMonthCents, 100000);
      expect(p.status, GoalStatus.onTrack);
      expect(p.arrearsCents, 0);
    });

    test('[2] 本月少存 → 目标额不变，状态落后', () {
      final p = SavingsEngine.compute(
        g1,
        [dep('2026-01', 1000), dep('2026-02', 500)],
        '2026-02',
      );
      expect(p.requiredThisMonthCents, 100000, reason: '本月目标额不因本周存入而变');
      expect(p.paidThisMonthCents, 50000);
      expect(p.status, GoalStatus.behind);
    });

    test('[3] 拖到 5 月：欠 2500 摊到剩余 7 个月', () {
      final p = SavingsEngine.compute(
        g1,
        [dep('2026-01', 1000), dep('2026-02', 500)],
        '2026-05',
      );
      expect(p.arrearsCents, 250000);
      expect(p.requiredThisMonthCents, 135715); // 1000 + ceil(2500/7)=357.15
      expect(p.basis, contains('摊 7 月'));
    });

    test('[4] 三种补缴策略对比', () {
      final ds = [dep('2026-01', 1000), dep('2026-02', 500)];
      final spread = SavingsEngine.compute(g1, ds, '2026-05');
      final now = SavingsEngine.compute(
          g1.copyWith(arrearsMode: ArrearsMode.catchUpNow), ds, '2026-05');
      final tail = SavingsEngine.compute(
          g1.copyWith(arrearsMode: ArrearsMode.tail), ds, '2026-05');
      expect(spread.requiredThisMonthCents, 135715);
      expect(now.requiredThisMonthCents, 350000);
      expect(tail.requiredThisMonthCents, 100000);
    });

    test('[5] 末期一分未存 → 全额', () {
      final p = SavingsEngine.compute(g1, const [], '2026-12');
      expect(p.requiredThisMonthCents, 1200000);
    });

    test('[6] 重排模式：大额存入自动减负', () {
      final p = SavingsEngine.compute(
        g1.copyWith(model: SavingsModel.rebase),
        [dep('2026-01', 1000), dep('2026-02', 5000)],
        '2026-03',
      );
      expect(p.requiredThisMonthCents, 60000); // 已存 6000，剩 10 月 → 600
      expect(p.status, GoalStatus.behind); // 3 月本身还没存
    });

    test('[7] 重排模式：欠缴自动摊平', () {
      final p = SavingsEngine.compute(
        g1.copyWith(model: SavingsModel.rebase),
        [dep('2026-01', 500)],
        '2026-04',
      );
      expect(p.requiredThisMonthCents, 127778); // ceil(11500/9)
      expect(p.status, GoalStatus.behind);
    });

    test('[8] 超额 → 已完成并展示超出额', () {
      final p = SavingsEngine.compute(g1, [dep('2026-03', 13000)], '2026-03');
      expect(p.status, GoalStatus.done);
      expect(p.overCents, 100000);
      expect(p.requiredThisMonthCents, 0);
      expect(p.progress, 1.0);
    });

    test('[9] 逾期 → 缺口全额催缴', () {
      final p = SavingsEngine.compute(g1, [dep('2026-01', 3000)], '2027-03');
      expect(p.status, GoalStatus.overdue);
      expect(p.requiredThisMonthCents, 900000);
    });

    test('[10] 宽限期让补缴摊得更薄', () {
      final ds = [dep('2026-01', 1000)];
      final none = SavingsEngine.compute(g1.copyWith(graceMonths: 0), ds, '2026-04');
      final two = SavingsEngine.compute(g1.copyWith(graceMonths: 2), ds, '2026-04');
      expect(none.requiredThisMonthCents, 125000); // 2000 摊 8 月
      expect(two.requiredThisMonthCents, 133334); // 2000 摊 6 月
      expect(two.requiredThisMonthCents, greaterThan(none.requiredThisMonthCents));
    });

    test('[11] 多目标汇总', () {
      final g2 = SavingsGoal(
        id: 'g2',
        name: '买电脑',
        targetCents: 800000,
        startYm: '2026-03',
        deadlineYm: '2026-08',
        createdAt: DateTime(2026, 1, 1),
      );
      final plans = [
        SavingsEngine.compute(g1, [dep('2026-01', 1000)], '2026-04'),
        SavingsEngine.compute(g2, const [], '2026-04'),
      ];
      final agg = SavingsEngine.aggregate(plans);
      expect(agg.requiredThisMonthCents,
          plans[0].requiredThisMonthCents + plans[1].requiredThisMonthCents);
      // g2 在 4 月是第 2 期：基准 1333.33 + 3 月欠缴 1333.33 摊 4 月 = 333.34 → 1666.67
      expect(agg.requiredThisMonthCents, 125000 + 166667);
      expect(agg.targetCents, 2000000);
    });

    test('[12] 取整收敛：Σ 时间表 == 目标额', () {
      final odd = g1.copyWith(
          targetCents: 100000, startYm: '2026-01', deadlineYm: '2026-03');
      expect(SavingsEngine.buildSchedule(odd), [33333, 33333, 33334]);
      expect(SavingsEngine.buildSchedule(odd).fold<int>(0, (a, b) => a + b), 100000);

      final odd2 = odd.copyWith(targetCents: 100001);
      expect(SavingsEngine.buildSchedule(odd2), [33333, 33333, 33335]);
      expect(SavingsEngine.buildSchedule(odd2).fold<int>(0, (a, b) => a + b), 100001);
    });

    test('[13] 中途改目标金额：历史不变、本月重算', () {
      final p = SavingsEngine.compute(
        g1.copyWith(targetCents: 1800000),
        [dep('2026-01', 1000), dep('2026-02', 1000)],
        '2026-06',
      );
      expect(p.baseMonthlyCents, 150000); // 18000/12
      expect(p.months[0].plannedCents, 150000); // 历史月也按新目标的时间表
      expect(p.arrearsCents, 550000); // 1-5 月应有 7500，实存 2000
      expect(p.requiredThisMonthCents, 241667); // 1500 + ceil(5500/6)=916.67
    });
  });

  group('明细表与边界', () {
    test('明细行覆盖开始月到 max(截止月, 本月)', () {
      final p = SavingsEngine.compute(g1, const [], '2026-04');
      expect(p.months.length, 12);
      expect(p.months.first.ym, '2026-01');
      expect(p.months.last.ym, '2026-12');
      expect(p.months[3].isCurrent, isTrue);
      expect(p.months[4].isFuture, isTrue);
      expect(p.months[2].isPast, isTrue);
    });

    test('逾期时明细延伸到本月', () {
      final p = SavingsEngine.compute(g1, const [], '2027-03');
      expect(p.months.length, 15);
      expect(p.months.last.ym, '2027-03');
    });

    test('未开始状态', () {
      final future = g1.copyWith(startYm: '2026-06', deadlineYm: '2027-05');
      final p = SavingsEngine.compute(future, const [], '2026-01');
      expect(p.status, GoalStatus.notStarted);
      expect(p.requiredThisMonthCents, 0);
      expect(p.basis, contains('2026-06'));
    });

    test('跨年：12 月 → 次年 1 月连续', () {
      final g = g1.copyWith(
          targetCents: 300000, startYm: '2026-11', deadlineYm: '2027-01');
      expect(SavingsEngine.monthsInclusive(g.startYm, g.deadlineYm), 3);
      expect(SavingsEngine.buildSchedule(g), [100000, 100000, 100000]);
      final p = SavingsEngine.compute(g, const [], '2026-11');
      expect(p.months.map((m) => m.ym).toList(), ['2026-11', '2026-12', '2027-01']);
    });

    test('补录历史月份立刻改变本月应存额', () {
      final before = SavingsEngine.compute(g1, const [], '2026-04');
      expect(before.arrearsCents, 300000); // 1-3 月应有 3000，实存 0
      final after =
          SavingsEngine.compute(g1, [dep('2026-02', 1000)], '2026-04');
      expect(after.arrearsCents, 200000);
      expect(after.requiredThisMonthCents,
          lessThan(before.requiredThisMonthCents));
    });
  });

  group('期初已存（建目标前就有的钱）', () {
    test('剩下的部分才按月摊：12000 已存 2000 → 每月 833.33', () {
      final g = g1.copyWith(initialCents: 200000);
      expect(SavingsEngine.remainingToSave(g), 1000000);
      expect(SavingsEngine.buildSchedule(g).first, 83333);
      final p = SavingsEngine.compute(g, const [], '2026-01');
      expect(p.baseMonthlyCents, 83333);
      expect(p.requiredThisMonthCents, 83333);
      expect(p.savedTotalCents, 200000);
      expect(p.gapCents, 1000000);
      expect(p.progress, closeTo(200000 / 1200000, 1e-9));
    });

    test('进度与还差都按含期初的已存算', () {
      final g = g1.copyWith(initialCents: 600000);
      final p = SavingsEngine.compute(g, [dep('2026-01', 500)], '2026-01');
      expect(p.savedTotalCents, 650000);
      expect(p.gapCents, 550000);
      expect(p.progress, closeTo(650000 / 1200000, 1e-9));
    });

    test('累计实存从期初起算', () {
      final g = g1.copyWith(initialCents: 200000);
      final p = SavingsEngine.compute(g, [dep('2026-01', 833.33)], '2026-02');
      expect(p.months.first.cumActualCents, 200000 + 83333);
      expect(p.months[1].cumActualCents, 200000 + 83333);
    });

    test('期初已存会先抵掉欠缴', () {
      final g = g1.copyWith(initialCents: 200000);
      // 1、2 月都没存，第 3 月：应有 833.33×2，期初 2000 足以覆盖 → 不欠
      final p = SavingsEngine.compute(g, const [], '2026-03');
      expect(p.scheduledCumBeforeCents, 83333 * 2);
      expect(p.arrearsCents, 0);
      expect(p.requiredThisMonthCents, 83333);
    });

    test('期初已存超过目标 → 直接完成，剩余为 0', () {
      final g = g1.copyWith(initialCents: 1300000);
      expect(SavingsEngine.remainingToSave(g), 0);
      expect(SavingsEngine.buildSchedule(g).every((v) => v == 0), true);
      final p = SavingsEngine.compute(g, const [], '2026-01');
      expect(p.status, GoalStatus.done);
      expect(p.gapCents, 0);
      expect(p.overCents, 100000);
      expect(p.requiredThisMonthCents, 0);
    });

    test('余数仍然收敛：10000.01 − 2000 摊 3 月', () {
      final g = g1.copyWith(
        targetCents: 1000001,
        initialCents: 200000,
        startYm: '2026-01',
        deadlineYm: '2026-03',
      );
      final rows = SavingsEngine.buildSchedule(g);
      expect(rows.fold<int>(0, (a, b) => a + b), 800001);
      expect(rows, [266667, 266667, 266667]);
    });

    test('改期初已存立刻改月供（编辑目标场景）', () {
      final before = SavingsEngine.compute(g1, const [], '2026-01');
      final after = SavingsEngine.compute(
          g1.copyWith(initialCents: 400000), const [], '2026-01');
      expect(before.requiredThisMonthCents, 100000);
      expect(after.requiredThisMonthCents, lessThan(before.requiredThisMonthCents));
      expect(after.requiredThisMonthCents, 66666);
    });
  });

  group('反向规划（按每月能存多少倒推时间）', () {
    test('200000 每月 5000 → 40 个月，2026-11 起 2030-02 完成', () {
      final n = SavingsEngine.monthsNeeded(20000000, 500000);
      expect(n, 40);
      expect(
        SavingsEngine.deadlineFor(
          targetCents: 20000000,
          monthlyCents: 500000,
          startYm: '2026-11',
        ),
        '2030-02',
      );
    });

    test('除不尽就向上取整', () {
      // 12000 / 5000 = 2.4 → 3 期，最后一个月只需存 2000
      expect(SavingsEngine.monthsNeeded(1200000, 500000), 3);
      expect(
        SavingsEngine.deadlineFor(
          targetCents: 1200000,
          monthlyCents: 500000,
          startYm: '2026-11',
        ),
        '2027-01',
      );
    });

    test('期初已存先扣掉再算月数', () {
      expect(
        SavingsEngine.monthsNeeded(20000000, 500000, initialCents: 5000000),
        30,
      );
    });

    test('一个月就够', () {
      expect(SavingsEngine.monthsNeeded(300000, 500000), 1);
      expect(
        SavingsEngine.deadlineFor(
          targetCents: 300000,
          monthlyCents: 500000,
          startYm: '2026-11',
        ),
        '2026-11',
      );
    });

    test('月供为 0 或目标已达成时的边界', () {
      expect(SavingsEngine.monthsNeeded(100000, 0), 0);
      expect(SavingsEngine.monthsNeeded(100000, 0, initialCents: 200000), 1);
    });
  });
}
