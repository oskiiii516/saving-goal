import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine.dart';
import '../state/providers.dart';
import 'charts.dart';
import 'palette.dart';
import 'widgets.dart';

/// 统计页：把多个目标叠在一起看趋势
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    final plans = ref.watch(computationsProvider);
    final agg = ref.watch(aggregateProvider);
    final nowYm = ref.watch(nowYmProvider);

    final combined = _combineMonths(plans, nowYm);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
          children: [
            Text('统计',
                style: TextStyle(
                    color: p.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
            const SizedBox(height: 3),
            Text('全部目标叠在一起的进度与节奏',
                style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 16),
            if (plans.isEmpty)
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 46),
                child: Column(
                  children: [
                    Icon(Icons.insights_rounded, size: 40, color: p.faint),
                    const SizedBox(height: 12),
                    Text('还没有数据',
                        style: TextStyle(color: p.muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('先加一个目标，这里就会出现累计曲线',
                        style: TextStyle(color: p.faint, fontSize: 11.5)),
                  ],
                ),
              )
            else ...[
              _Overview(aggregate: agg, goalCount: plans.length),
              const SizedBox(height: 18),
              SectionTitle('累计实存 vs 计划',
                  trailing: ChartLegend(items: [
                    (p.green, '实际累计'),
                    (p.muted, '计划累计'),
                  ])),
              Panel(
                padding: const EdgeInsets.fromLTRB(6, 14, 14, 8),
                child: CumulativeChart(months: combined),
              ),
              const SizedBox(height: 18),
              SectionTitle('每月应存 / 实存',
                  trailing: ChartLegend(items: [
                    (p.muted, '应存'),
                    (p.green, '实存'),
                  ])),
              Panel(
                padding: const EdgeInsets.fromLTRB(6, 14, 14, 8),
                child: MonthlyBarChart(months: combined),
              ),
              const SizedBox(height: 18),
              const SectionTitle('各目标进度'),
              for (final c in plans) ...[
                _GoalBar(plan: c),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              const SectionTitle('本月负担排行'),
              Panel(
                child: Column(
                  children: [
                    for (var i = 0; i < plans.length; i++) ...[
                      if (i > 0) Divider(color: p.border, height: 18),
                      _BurdenRow(
                        index: i + 1,
                        plan: plans[i],
                        total: agg.requiredThisMonthCents,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 把多个目标的月度明细按「月」加总成一条合计曲线
  static List<MonthPlan> _combineMonths(
      List<GoalComputation> plans, String nowYm) {
    if (plans.isEmpty) return const [];
    final starts = plans.map((c) => c.months.first.ym).toList()..sort();
    final ends = plans.map((c) => c.months.last.ym).toList()..sort();
    final from = SavingsEngine.ymIndex(starts.first);
    final to = SavingsEngine.ymIndex(ends.last);
    final nowIdx = SavingsEngine.ymIndex(nowYm);

    final byYm = <String, (int planned, int actual)>{};
    for (final c in plans) {
      for (final m in c.months) {
        final cur = byYm[m.ym] ?? (0, 0);
        byYm[m.ym] = (cur.$1 + m.plannedCents, cur.$2 + m.actualCents);
      }
    }

    final out = <MonthPlan>[];
    var cumPlanned = 0;
    var cumActual = 0;
    for (var i = from; i <= to; i++) {
      final ym = SavingsEngine.indexYm(i);
      final v = byYm[ym] ?? (0, 0);
      cumPlanned += v.$1;
      cumActual += v.$2;
      out.add(MonthPlan(
        ym: ym,
        plannedCents: v.$1,
        actualCents: v.$2,
        deltaCents: v.$2 - v.$1,
        cumPlannedCents: cumPlanned,
        cumActualCents: cumActual,
        isPast: i < nowIdx,
        isCurrent: i == nowIdx,
        isFuture: i > nowIdx,
      ));
    }
    return out;
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.aggregate, required this.goalCount});

  final Aggregate aggregate;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final a = aggregate;
    return Panel(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [p.heroFrom, p.heroTo],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$goalCount 个目标',
                  style: TextStyle(color: p.muted, fontSize: 11.5)),
              const Spacer(),
              Text('完成 ${(a.progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: p.green, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Money(SavingsEngine.fmt(a.savedTotalCents),
                  size: 28, weight: FontWeight.w800),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('/ ${SavingsEngine.fmt(a.targetCents)} 元',
                    style: TextStyle(color: p.muted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SlimProgress(value: a.progress, height: 7),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: '未完成', value: '${a.behindCount}', color: p.warn),
              _MiniStat(label: '已达成', value: '${a.doneCount}', color: p.green),
              _MiniStat(label: '已逾期', value: '${a.overdueCount}', color: p.danger),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.muted, fontSize: 10.5)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.plan});

  final GoalComputation plan;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = p.forStatus(plan.status.name);
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(
                '${SavingsEngine.fmt(plan.savedTotalCents)} / ${SavingsEngine.fmt(plan.targetCents)}',
                style: TextStyle(color: p.muted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                child: Text(
                  '${(plan.progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SlimProgress(value: plan.progress, height: 6, color: color),
        ],
      ),
    );
  }
}

class _BurdenRow extends StatelessWidget {
  const _BurdenRow({
    required this.index,
    required this.plan,
    required this.total,
  });

  final int index;
  final GoalComputation plan;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final share = total <= 0 ? 0.0 : plan.requiredThisMonthCents / total;
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text('$index',
              style: TextStyle(color: p.faint, fontSize: 11.5)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.text, fontSize: 12.5)),
                  ),
                  Text('${(share * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: p.faint, fontSize: 10.5)),
                ],
              ),
              const SizedBox(height: 5),
              SlimProgress(
                value: share,
                height: 4,
                color: p.forStatus(plan.status.name),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            SavingsEngine.fmt(plan.requiredThisMonthCents),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: p.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
