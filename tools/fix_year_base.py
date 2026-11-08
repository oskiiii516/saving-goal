# -*- coding: utf-8 -*-
"""年度计划额改用「基准时间表」口径，避免欠缴补缴让年度计划膨胀。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\app\lib\core\engine.dart")
s = p.read_text(encoding="utf-8")

old = """    final planned = <int, int>{};
    final goalsOf = <int, Set<String>>{};
    for (final plan in plans) {
      for (final m in plan.months) {
        final y = int.parse(m.ym.substring(0, 4));
        planned[y] = (planned[y] ?? 0) + m.plannedCents;
        (goalsOf[y] ??= <String>{}).add(plan.goalId);
      }
    }"""

new = """    final planned = <int, int>{};
    final goalsOf = <int, Set<String>>{};
    for (final plan in plans) {
      for (var i = 0; i < plan.months.length; i++) {
        final y = int.parse(plan.months[i].ym.substring(0, 4));
        // 用基准额，不用「含补缴的应存」：否则一个老欠缴会把这年的计划额撑大，
        // 年度进度永远显示没达成，也不符合「这一年本该存多少」的语义。
        planned[y] = (planned[y] ?? 0) + _baseOfMonth(plan, i);
        (goalsOf[y] ??= <String>{}).add(plan.goalId);
      }
    }"""

assert old in s
s = s.replace(old, new, 1)

helper = """
  /// 第 [i] 个月在基准时间表里的金额（最后一月吸收除法余数）
  static int _baseOfMonth(GoalComputation plan, int i) {
    final n = plan.months.length;
    if (i < 0 || i >= n) return 0;
    if (i < n - 1) return plan.baseMonthlyCents;
    final total =
        math.max<int>(0, plan.targetCents - math.max<int>(0, plan.initialCents));
    return math.max<int>(0, total - plan.baseMonthlyCents * (n - 1));
  }

  /// 按年聚合：返回有数据（有计划或有流水）的每一年，按年份升序"""

s = s.replace("\n  /// 按年聚合：返回有数据（有计划或有流水）的每一年，按年份升序", helper, 1)
p.write_text(s, encoding="utf-8")

# 测试期望改回基准口径
t = pathlib.Path(r"D:\dev\saving-goal-app\app\test\engine_test.dart")
ts = t.read_text(encoding="utf-8")
ts = ts.replace("""      // 8/9/10/12 各 1000，11 月含 10 月欠缴的补缴 75 → 1075
      expect(y26.plannedCents, 507500);""",
"""      // 基准口径：8~12 五个月 × 1000（不受 10 月欠缴摊还影响）
      expect(y26.plannedCents, 500000);""")
ts = ts.replace("      expect(y26.gapCents, 67500);", "      expect(y26.gapCents, 60000);")
ts = ts.replace("      expect(y26.progress, closeTo(440000 / 507500, 0.0001));",
                "      expect(y26.progress, closeTo(0.88, 0.0001));")
ts = ts.replace("      expect(y26.plannedCents, 507500 + 600000); // 含补缴的 5075 + 新电脑 3×2000",
                "      expect(y26.plannedCents, 500000 + 600000); // 5000 + 新电脑 3×2000")
t.write_text(ts, encoding="utf-8")
print("ok")
