/// 储蓄目标引擎（Dart 移植版，与 engine/savings-engine.mjs 逐行等价）
///
/// ── 设计要点 ─────────────────────────────────────────────
/// 1) 基准时间表：总额 / 期内月数 = 每月基准额，最后一月吸收取整误差。
///    历史月份的「计划额」永久固定 → 明细表不会因为后来补缴而漂移。
/// 2) 欠缴按「时间表累计应有 - 累计实存」在**上月末**结算，
///    本月存款只影响「本月是否达成」，不影响本月目标额本身。
/// 3) 补缴方式三选一：spread 摊到剩余月 / catchUpNow 下月补齐 / tail 留到末期。
/// 4) 重排模式：不看时间表，直接「还差多少 ÷ 还剩几个月」，超出进度自动减负。
///
/// 纯 Dart、零依赖（只用 dart:math / dart:core），金额一律用「分」的整数。
library;

import 'dart:math' as math;

enum SavingsModel { schedule, rebase }

enum ArrearsMode { spread, catchUpNow, tail }

enum GoalStatus { notStarted, onTrack, behind, overdue, done }

extension GoalStatusX on GoalStatus {
  String get label => switch (this) {
        GoalStatus.notStarted => '未开始',
        GoalStatus.onTrack => '按计划',
        GoalStatus.behind => '本月欠缴',
        GoalStatus.overdue => '已逾期',
        GoalStatus.done => '已完成',
      };
}

// ══════════════ 数据模型 ══════════════

class SavingsGoal {
  final String id;
  final String name;

  /// 目标金额，单位：分
  final int targetCents;

  /// 建目标前就已经存下的钱（期初已存，单位：分）。
  /// 它不计入任何一个月，只减小需要按月摊开的剩余额度。
  final int initialCents;

  /// 'YYYY-MM'
  final String startYm;
  final String deadlineYm;
  final SavingsModel model;
  final ArrearsMode arrearsMode;

  /// 允许欠缴不立刻摊还的缓冲月数
  final int graceMonths;
  final String note;
  final bool archived;
  final DateTime createdAt;

  /// 分配优先级：数字小的先补（补缴建议按这个顺序给钱）
  final int priority;

  /// 每月几号存这笔钱并提醒（1–28；0 表示跟随全局提醒，不单独提醒）
  final int payDay;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetCents,
    this.initialCents = 0,
    required this.startYm,
    required this.deadlineYm,
    this.model = SavingsModel.schedule,
    this.arrearsMode = ArrearsMode.spread,
    this.graceMonths = 0,
    this.note = '',
    this.archived = false,
    this.priority = 0,
    this.payDay = 0,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    String? name,
    int? targetCents,
    int? initialCents,
    String? startYm,
    String? deadlineYm,
    SavingsModel? model,
    ArrearsMode? arrearsMode,
    int? graceMonths,
    String? note,
    bool? archived,
    int? priority,
    int? payDay,
  }) =>
      SavingsGoal(
        id: id,
        name: name ?? this.name,
        targetCents: targetCents ?? this.targetCents,
        initialCents: initialCents ?? this.initialCents,
        startYm: startYm ?? this.startYm,
        deadlineYm: deadlineYm ?? this.deadlineYm,
        model: model ?? this.model,
        arrearsMode: arrearsMode ?? this.arrearsMode,
        graceMonths: graceMonths ?? this.graceMonths,
        note: note ?? this.note,
        archived: archived ?? this.archived,
        priority: priority ?? this.priority,
        payDay: payDay ?? this.payDay,
        createdAt: createdAt,
      );
}

class Deposit {
  final String id;
  final String goalId;

  /// 归属月份 'YYYY-MM'（支持补录历史月份）
  final String ym;
  final int amountCents;
  final String note;
  final DateTime createdAt;

  const Deposit({
    required this.id,
    required this.goalId,
    required this.ym,
    required this.amountCents,
    this.note = '',
    required this.createdAt,
  });
}

class MonthPlan {
  final String ym;
  final int plannedCents;
  final int actualCents;
  final int deltaCents;
  final int cumPlannedCents;
  final int cumActualCents;
  final bool isPast;
  final bool isCurrent;
  final bool isFuture;

  const MonthPlan({
    required this.ym,
    required this.plannedCents,
    required this.actualCents,
    required this.deltaCents,
    required this.cumPlannedCents,
    required this.cumActualCents,
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
  });
}

class GoalComputation {
  final String goalId;
  final String name;
  final int targetCents;
  final int initialCents;
  final int savedTotalCents;
  final int gapCents;
  final int overCents;
  final double progress;
  final int totalMonths;
  final int monthsLeftInclThis;
  final int baseMonthlyCents;
  final int arrearsCents;
  final int requiredThisMonthCents;
  final int paidThisMonthCents;
  final int scheduledCumBeforeCents;
  final String basis;
  final GoalStatus status;
  final String? projectedFinishYm;
  final List<MonthPlan> months;

  /// 每月几号存并提醒（0 = 不单独提醒）
  final int payDay;

  const GoalComputation({
    required this.goalId,
    required this.name,
    required this.targetCents,
    required this.initialCents,
    required this.savedTotalCents,
    required this.gapCents,
    required this.overCents,
    required this.progress,
    required this.totalMonths,
    required this.monthsLeftInclThis,
    required this.baseMonthlyCents,
    required this.arrearsCents,
    required this.requiredThisMonthCents,
    required this.paidThisMonthCents,
    required this.scheduledCumBeforeCents,
    required this.basis,
    required this.status,
    required this.projectedFinishYm,
    required this.months,
    this.payDay = 0,
  });

  int get remainingThisMonthCents =>
      math.max(0, requiredThisMonthCents - paidThisMonthCents);
}

class Aggregate {
  int requiredThisMonthCents = 0;
  int paidThisMonthCents = 0;
  int savedTotalCents = 0;
  int targetCents = 0;
  int gapCents = 0;
  int behindCount = 0;
  int doneCount = 0;
  int overdueCount = 0;

  double get progress => targetCents > 0
      ? math.min(1.0, savedTotalCents / targetCents).toDouble()
      : 0.0;
}

// ══════════════ 纯函数引擎 ══════════════

/// 按年汇总：这一年计划存多少、实际存了多少
///
/// 计划额来自各目标月度时间表在这一年的合计，实存额来自流水。
/// 期初已存不归属任何一年（那是建目标之前就有的钱），
/// 所以这里的「实存」只算这一年新存进去的。
class YearSummary {
  final int year;
  final int plannedCents;
  final int actualCents;
  final int depositsCount;
  final int goalCount;
  final bool isCurrent;
  final bool isFuture;

  const YearSummary({
    required this.year,
    required this.plannedCents,
    required this.actualCents,
    required this.depositsCount,
    required this.goalCount,
    required this.isCurrent,
    required this.isFuture,
  });

  /// 这一年还差多少（负数表示超额）
  int get gapCents => plannedCents - actualCents;

  bool get met => plannedCents > 0 && actualCents >= plannedCents;

  /// 没有计划的年份，只要存过就算完成
  double get progress {
    if (plannedCents <= 0) return actualCents > 0 ? 1 : 0;
    return (actualCents / plannedCents).clamp(0.0, 1.0);
  }
}

class SavingsEngine {
  const SavingsEngine._();

  // ── 时间：一律转成绝对月序号，避免跨年/月底的边界问题 ──
  static int ymIndex(String ym) {
    final p = ym.split('-');
    final y = int.parse(p[0]);
    final m = int.parse(p[1]);
    return y * 12 + (m - 1);
  }

  static String indexYm(int i) {
    final y = i ~/ 12;
    final m = i % 12 + 1;
    return '$y-${m.toString().padLeft(2, '0')}';
  }

  static int monthsInclusive(String fromYm, String toYm) =>
      ymIndex(toYm) - ymIndex(fromYm) + 1;

  static String todayYm([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// 分 → 「元.角分」字符串，不带货币符号
  static String fmt(int cents) {
    final sign = cents < 0 ? '-' : '';
    final v = cents.abs();
    return '$sign${v ~/ 100}.${(v % 100).toString().padLeft(2, '0')}';
  }

  /// 分 → 带千分位的完整金额，如 ¥12,000.00
  static String fmtMoney(int cents) {
    final sign = cents < 0 ? '-' : '';
    final v = cents.abs();
    final yuan = (v ~/ 100).toString();
    final buf = StringBuffer();
    for (var i = 0; i < yuan.length; i++) {
      if (i > 0 && (yuan.length - i) % 3 == 0) buf.write(',');
      buf.write(yuan[i]);
    }
    return '$sign¥$buf.${(v % 100).toString().padLeft(2, '0')}';
  }

  /// 时间表：返回每个月的基准额（最后一月吸收余数，保证 Σ == 需要按月存的部分）
  ///
  /// 期初已存的钱先扣掉，只有剩下的部分才摊到每个月。
  static List<int> buildSchedule(SavingsGoal goal) {
    final n = math.max(1, monthsInclusive(goal.startYm, goal.deadlineYm));
    final int remaining =
        math.max<int>(0, goal.targetCents - math.max<int>(0, goal.initialCents));
    final per = remaining ~/ n;
    final rows = List<int>.filled(n, per);
    rows[n - 1] += remaining - per * n;
    return rows;
  }


  /// 第 [i] 个月在基准时间表里的金额（最后一月吸收除法余数）
  static int _baseOfMonth(GoalComputation plan, int i) {
    final n = plan.months.length;
    if (i < 0 || i >= n) return 0;
    if (i < n - 1) return plan.baseMonthlyCents;
    final total =
        math.max<int>(0, plan.targetCents - math.max<int>(0, plan.initialCents));
    return math.max<int>(0, total - plan.baseMonthlyCents * (n - 1));
  }

  /// 按年聚合：返回有数据（有计划或有流水）的每一年，按年份升序
  static List<YearSummary> yearlySummary({
    required List<GoalComputation> plans,
    required List<Deposit> deposits,
    required String nowYm,
  }) {
    final planned = <int, int>{};
    final goalsOf = <int, Set<String>>{};
    for (final plan in plans) {
      for (var i = 0; i < plan.months.length; i++) {
        final y = int.parse(plan.months[i].ym.substring(0, 4));
        // 用基准额，不用「含补缴的应存」：否则一个老欠缴会把这年的计划额撑大，
        // 年度进度永远显示没达成，也不符合「这一年本该存多少」的语义。
        planned[y] = (planned[y] ?? 0) + _baseOfMonth(plan, i);
        (goalsOf[y] ??= <String>{}).add(plan.goalId);
      }
    }

    final actual = <int, int>{};
    final count = <int, int>{};
    for (final d in deposits) {
      final y = int.parse(d.ym.substring(0, 4));
      actual[y] = (actual[y] ?? 0) + d.amountCents;
      count[y] = (count[y] ?? 0) + 1;
    }

    final years = <int>{...planned.keys, ...actual.keys}.toList()..sort();
    final nowYear = int.parse(nowYm.substring(0, 4));
    return [
      for (final y in years)
        YearSummary(
          year: y,
          plannedCents: planned[y] ?? 0,
          actualCents: actual[y] ?? 0,
          depositsCount: count[y] ?? 0,
          goalCount: goalsOf[y]?.length ?? 0,
          isCurrent: y == nowYear,
          isFuture: y > nowYear,
        ),
    ];
  }

  /// 反向规划：已知每月能存 [monthlyCents]，算出需要多少个月
  /// 例：目标 200000、期初 0、每月 5000 → 40 个月
  static int monthsNeeded(int targetCents, int monthlyCents, {int initialCents = 0}) {
    final remaining = math.max<int>(0, targetCents - math.max<int>(0, initialCents));
    if (remaining == 0) return 1;
    if (monthlyCents <= 0) return 0;
    return _ceilDiv(remaining, monthlyCents);
  }

  /// 反向规划：按每月能存多少，推出截止月份
  static String deadlineFor({
    required int targetCents,
    required int monthlyCents,
    required String startYm,
    int initialCents = 0,
  }) {
    final n = monthsNeeded(targetCents, monthlyCents, initialCents: initialCents);
    if (n <= 0) return startYm;
    return indexYm(ymIndex(startYm) + n - 1);
  }

  /// 需要按月摊开的金额（目标额 − 期初已存）
  static int remainingToSave(SavingsGoal goal) =>
      math.max<int>(0, goal.targetCents - math.max<int>(0, goal.initialCents));

  static int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

  /// 核心：算某个目标在 nowYm 时点的「本月该存多少 / 欠了多少 / 每月明细 / 状态」
  static GoalComputation compute(
    SavingsGoal goal,
    List<Deposit> allDeposits,
    String nowYm,
  ) {
    final target = goal.targetCents;
    final startIdx = ymIndex(goal.startYm);
    final endIdx = ymIndex(goal.deadlineYm);
    final nowIdx = ymIndex(nowYm);
    final totalMonths = monthsInclusive(goal.startYm, goal.deadlineYm);
    final model = goal.model;
    final arrearsMode = goal.arrearsMode;
    final grace = math.max(0, goal.graceMonths);

    final schedule = buildSchedule(goal);
    final baseMonthly = schedule.first;

    // 按归属月份聚合一笔笔存入
    final mine = allDeposits.where((d) => d.goalId == goal.id).toList();
    final byMonth = <String, int>{};
    for (final d in mine) {
      byMonth[d.ym] = (byMonth[d.ym] ?? 0) + d.amountCents;
    }

    int sumMonths(int fromIdx, int toIdx) {
      var s = 0;
      for (var i = fromIdx; i <= toIdx; i++) {
        s += byMonth[indexYm(i)] ?? 0;
      }
      return s;
    }

    final int initial = math.max<int>(0, goal.initialCents);
    final savedTotal = initial + mine.fold<int>(0, (s, d) => s + d.amountCents);
    final savedThisMonth = byMonth[nowYm] ?? 0;
    // 期初已存视作「开始之前就已经在账上」，所以欠缴结算也要把它算进去
    final savedBefore = initial + sumMonths(startIdx, nowIdx - 1);
    final gap = math.max(0, target - savedTotal);
    final over = math.max(0, savedTotal - target);

    // 时间表在「上月末」的累计应有（只算已进入的期数）
    final settledMonths = math.max(0, math.min(nowIdx - startIdx, totalMonths));
    var scheduledCumBefore = 0;
    for (var k = 0; k < settledMonths; k++) {
      scheduledCumBefore += schedule[k];
    }

    final arrears = math.max(0, scheduledCumBefore - savedBefore);
    final monthsLeftInclThis = math.max(0, endIdx - nowIdx + 1);
    final monthsAfterThis = math.max(0, monthsLeftInclThis - 1);

    final baseThisMonth = (nowIdx < startIdx || nowIdx > endIdx)
        ? 0
        : schedule[math.min(nowIdx - startIdx, schedule.length - 1)];

    var required = 0;
    var catchUp = 0;
    var basis = '';

    if (savedTotal >= target) {
      basis = '已完成${over > 0 ? '，超出 ${fmt(over)}' : ''}';
    } else if (nowIdx > endIdx) {
      required = gap;
      basis = '期限已过，缺口全额补';
    } else if (nowIdx < startIdx) {
      basis = '计划 ${goal.startYm} 开始';
    } else if (model == SavingsModel.rebase) {
      final remaining = math.max(1, monthsLeftInclThis - grace);
      required = _ceilDiv(math.max(0, target - savedBefore), remaining);
      catchUp = required - baseThisMonth;
      basis = '重排：还差 ${fmt(math.max(0, target - savedBefore))} / 剩 $remaining 个月';
    } else {
      if (arrears > 0 && monthsAfterThis > 0) {
        switch (arrearsMode) {
          case ArrearsMode.catchUpNow:
            catchUp = arrears;
            basis = '基准 ${fmt(baseThisMonth)} + 补缴 ${fmt(arrears)}';
          case ArrearsMode.spread:
            final spreadable = math.max(1, monthsAfterThis - grace);
            catchUp = _ceilDiv(arrears, spreadable);
            basis =
                '基准 ${fmt(baseThisMonth)} + 补缴 ${fmt(catchUp)}（${fmt(arrears)} 摊 $spreadable 月）';
          case ArrearsMode.tail:
            catchUp = 0;
            basis = '基准 ${fmt(baseThisMonth)}，${fmt(arrears)} 留到末期补齐';
        }
      } else if (arrears > 0) {
        catchUp = arrears;
        basis = '基准 ${fmt(baseThisMonth)} + 末期补齐 ${fmt(arrears)}';
      } else {
        basis = '基准 ${fmt(baseThisMonth)}';
      }
      required = math.min(gap, math.max(0, baseThisMonth + catchUp));
    }

    // 月度明细：历史月用时间表、本月用 required、未来月用基准（会随补缴重算）
    final months = <MonthPlan>[];
    var cumPlanned = 0;
    var cumActual = initial;
    final upper = math.max(endIdx, nowIdx);
    for (var i = startIdx; i <= upper; i++) {
      final ym = indexYm(i);
      final actual = byMonth[ym] ?? 0;
      final isPast = i < nowIdx;
      final isCurrent = i == nowIdx;
      final schedIdx = i - startIdx;
      final schedBase =
          (schedIdx >= 0 && schedIdx < schedule.length) ? schedule[schedIdx] : 0;

      final planned = isCurrent ? required : schedBase;

      cumPlanned += planned;
      cumActual += actual;
      months.add(MonthPlan(
        ym: ym,
        plannedCents: planned,
        actualCents: actual,
        deltaCents: actual - planned,
        cumPlannedCents: cumPlanned,
        cumActualCents: cumActual,
        isPast: isPast,
        isCurrent: isCurrent,
        isFuture: i > nowIdx,
      ));
    }

    final GoalStatus status;
    if (savedTotal >= target) {
      status = GoalStatus.done;
    } else if (nowIdx > endIdx) {
      status = GoalStatus.overdue;
    } else if (nowIdx < startIdx) {
      status = GoalStatus.notStarted;
    } else if (savedThisMonth >= required) {
      status = GoalStatus.onTrack;
    } else {
      status = GoalStatus.behind;
    }

    String? projectedFinishYm;
    if (status == GoalStatus.done) {
      projectedFinishYm = nowYm;
    } else if (status != GoalStatus.overdue) {
      final pace = math.max(1, math.max(required, baseThisMonth));
      final needMonths = _ceilDiv(math.max(0, target - savedTotal), pace);
      projectedFinishYm = indexYm(nowIdx + needMonths);
    }

    return GoalComputation(
      goalId: goal.id,
      name: goal.name,
      targetCents: target,
      initialCents: initial,
      savedTotalCents: savedTotal,
      gapCents: gap,
      overCents: over,
      progress:
          target > 0 ? math.min(1.0, savedTotal / target).toDouble() : 0.0,
      totalMonths: totalMonths,
      monthsLeftInclThis: monthsLeftInclThis,
      baseMonthlyCents: baseMonthly,
      arrearsCents: arrears,
      requiredThisMonthCents: required,
      paidThisMonthCents: savedThisMonth,
      scheduledCumBeforeCents: scheduledCumBefore,
      basis: basis,
      status: status,
      projectedFinishYm: projectedFinishYm,
      months: months,
      payDay: goal.payDay,
    );
  }

  static Aggregate aggregate(List<GoalComputation> plans) {
    final a = Aggregate();
    for (final p in plans) {
      a.requiredThisMonthCents += p.requiredThisMonthCents;
      a.paidThisMonthCents += p.paidThisMonthCents;
      a.savedTotalCents += p.savedTotalCents;
      a.targetCents += p.targetCents;
      a.gapCents += p.gapCents;
      switch (p.status) {
        case GoalStatus.behind:
          a.behindCount++;
        case GoalStatus.done:
          a.doneCount++;
        case GoalStatus.overdue:
          a.overdueCount++;
        default:
          break;
      }
    }
    return a;
  }
}
