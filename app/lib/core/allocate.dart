import 'engine.dart';

/// 一条分配建议：某个目标这次建议存多少
class AllocationItem {
  const AllocationItem({required this.plan, required this.suggestedCents});

  final GoalComputation plan;
  final int suggestedCents;

  /// 分完之后本月还差多少
  int get stillShortThisMonth {
    final v = plan.remainingThisMonthCents - suggestedCents;
    return v > 0 ? v : 0;
  }

  bool get meetsThisMonth => plan.remainingThisMonthCents <= suggestedCents;
}

class AllocationResult {
  const AllocationResult({
    required this.budgetCents,
    required this.assignedCents,
    required this.items,
  });

  final int budgetCents;
  final int assignedCents;
  final List<AllocationItem> items;

  int get unassignedCents => budgetCents - assignedCents;
  bool get fullyAssigned => unassignedCents <= 0;
  int get satisfiedCount => items.where((i) => i.meetsThisMonth && i.suggestedCents > 0).length;
}

/// 把「本月能拿出的一笔钱」按优先级分配下去。
///
/// 规则（对用户可解释，不用黑箱权重）：
/// 1. 顺序就是优先级顺序，调用方已经按 priority / 逾期程度排好；
/// 2. 第一轮：谁这个月还欠多少，就先给谁补满，给到预算见底为止；
/// 3. 第二轮：还有富余，就按「离目标总额还差多少」的比例提前预存，
///    每个目标最多预存到缺口为止，不会出现建议超过剩余目标的情况。
AllocationResult allocate(
  List<GoalComputation> plans,
  int budgetCents, {
  bool allowAdvance = true,
}) {
  final budget = budgetCents < 0 ? 0 : budgetCents;
  var left = budget;
  final given = <String, int>{for (final p in plans) p.goalId: 0};

  // 第一轮：本月缺口
  for (final p in plans) {
    if (left <= 0) break;
    final need = p.remainingThisMonthCents;
    if (need <= 0) continue;
    final give = need < left ? need : left;
    given[p.goalId] = given[p.goalId]! + give;
    left -= give;
  }

  // 第二轮：提前预存（按缺口比例）
  if (left > 0 && allowAdvance) {
    int room(GoalComputation p) {
      final gap = p.gapCents - given[p.goalId]!;
      return gap > 0 ? gap : 0;
    }

    final open = plans.where((p) => room(p) > 0).toList();
    final totalRoom = open.fold<int>(0, (s, p) => s + room(p));
    if (totalRoom > 0) {
      var distributed = 0;
      for (final p in open) {
        final r = room(p);
        final share = (left * r) ~/ totalRoom;
        final give = share < r ? share : r;
        given[p.goalId] = given[p.goalId]! + give;
        distributed += give;
      }
      left -= distributed;
      // 整除的零头，按顺序补给还有空间的目标
      for (final p in open) {
        if (left <= 0) break;
        final r = room(p);
        if (r <= 0) continue;
        final give = r < left ? r : left;
        given[p.goalId] = given[p.goalId]! + give;
        left -= give;
      }
    }
  }

  final items = [
    for (final p in plans)
      AllocationItem(plan: p, suggestedCents: given[p.goalId]!),
  ];
  final assigned = given.values.fold<int>(0, (a, b) => a + b);
  return AllocationResult(
    budgetCents: budget,
    assignedCents: assigned,
    items: items,
  );
}
