import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/app_info.dart';
import '../core/engine.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'allocation_sheet.dart';
import 'goal_detail_page.dart';
import 'goal_form_sheet.dart';
import 'palette.dart';
import 'widgets.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(computationsProvider);
    final agg = ref.watch(aggregateProvider);
    final rows = ref.watch(goalsProvider).asData?.value ?? const <GoalRow>[];
    final goalById = {for (final r in rows) r.id: r.toModel()};
    final p = Palette.of(context);

    return Scaffold(
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showGoalFormSheet(context, ref),
              backgroundColor: p.greenDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('新目标'),
            ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.green,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: SlidableAutoCloseBehavior(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
            children: [
              const _Header(),
              const SizedBox(height: 14),
              _MonthlySummary(aggregate: agg),
              const SizedBox(height: 18),
              if (goals.isEmpty)
                const _EmptyState()
              else ...[
                SectionTitle(
                  '目标（${goals.length}）',
                  trailing: Text(
                    '按优先级排列',
                    style: TextStyle(color: p.faint, fontSize: 11),
                  ),
                ),
                for (final c in goals) ...[
                  _SwipeableGoalTile(
                    plan: c,
                    goal: goalById[c.goalId],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final now = DateTime.now();
    final week = ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppInfo.name,
              style: TextStyle(
                color: p.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${now.year}年${now.month}月${now.day}日 · 周$week · 本月 ${SavingsEngine.todayYm()}',
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlySummary extends ConsumerWidget {
  const _MonthlySummary({required this.aggregate});

  final Aggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    final agg = aggregate;
    final required = agg.requiredThisMonthCents;
    final paid = agg.paidThisMonthCents;
    final progress = required == 0 ? 1.0 : (paid / required).clamp(0.0, 1.0);
    final shortfall = required - paid;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.heroFrom, p.heroTo],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('本月需存 · 全部目标合计',
                  style: TextStyle(color: p.muted, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () => showAllocationSheet(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: p.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: p.green.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alt_route_rounded, size: 13, color: p.green),
                      const SizedBox(width: 4),
                      Text('怎么分配',
                          style: TextStyle(color: p.green, fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Money(
                        SavingsEngine.fmt(required),
                        size: 36,
                        weight: FontWeight.w800,
                        color: p.text,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('元',
                        style: TextStyle(color: p.muted, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('本月已存',
                      style: TextStyle(color: p.muted, fontSize: 11)),
                  const SizedBox(height: 3),
                  Money(SavingsEngine.fmt(paid),
                      size: 18, color: paid >= required ? p.green : p.warn),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SlimProgress(
            value: progress,
            height: 8,
            color: progress >= 1 ? p.green : p.greenDeep,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('总目标 ${SavingsEngine.fmt(agg.targetCents)} 元',
                  style: TextStyle(color: p.muted, fontSize: 11.5)),
              const Spacer(),
              Text(
                '已存 ${SavingsEngine.fmt(agg.savedTotalCents)} 元'
                '（${(agg.progress * 100).toStringAsFixed(0)}%）',
                style: TextStyle(color: p.muted, fontSize: 11.5),
              ),
            ],
          ),
          if (shortfall > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: p.warn.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.warn.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      size: 14, color: p.warn),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      agg.behindCount > 0
                          ? '本月还差 ${SavingsEngine.fmt(shortfall)} 元，${agg.behindCount} 个目标没跟上'
                          : '本月还差 ${SavingsEngine.fmt(shortfall)} 元',
                      style: TextStyle(color: p.warn, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.plan});

  final GoalComputation plan;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final statusColor = p.forStatus(plan.status.name);
    final needed = plan.remainingThisMonthCents;

    return Panel(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GoalDetailPage(goalId: plan.goalId),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                IconBadge(
                  icon: plan.status == GoalStatus.done
                      ? Icons.check_circle_outline_rounded
                      : Icons.savings_outlined,
                  color: statusColor,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      StatusChip(status: plan.status),
                    ],
                  ),
                ),
                Text(
                  plan.status == GoalStatus.done
                      ? '已完成'
                      : '剩 ${plan.monthsLeftInclThis} 个月',
                  style: TextStyle(color: p.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 0),
            child: SlimProgress(
              value: plan.progress,
              height: 6,
              color: statusColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: StatColumn(
                    label: '本月应存',
                    value: SavingsEngine.fmt(plan.requiredThisMonthCents),
                    color: plan.status == GoalStatus.overdue
                        ? p.danger
                        : (needed > 0 ? p.warn : p.green),
                  ),
                ),
                Expanded(
                  child: StatColumn(
                    label: '本月已存',
                    value: SavingsEngine.fmt(plan.paidThisMonthCents),
                    color: plan.paidThisMonthCents >=
                            plan.requiredThisMonthCents
                        ? p.green
                        : p.muted,
                  ),
                ),
                Expanded(
                  child: StatColumn(
                    label: '还差',
                    value: SavingsEngine.fmt(plan.gapCents),
                    color: p.text,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.basis,
                    maxLines: 2,
                    style: TextStyle(color: p.faint, fontSize: 10.5, height: 1.35),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  plan.projectedFinishYm == null
                      ? '已达成'
                      : '预计 ${plan.projectedFinishYm} 完成',
                  style: TextStyle(color: p.faint, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 30),
      child: Column(
        children: [
          Icon(Icons.savings_outlined, size: 44, color: p.green),
          const SizedBox(height: 14),
          Text('还没有目标',
              style: TextStyle(
                  color: p.text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '先定一个金额和截止月份，剩下的每期该存多少、欠了怎么补，交给我算',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => showGoalFormSheet(context, ref),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('添加第一个目标'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await ref.read(repositoryProvider).seedDemo();
            },
            child: const Text('先导入示例看看'),
          ),
        ],
      ),
    );
  }
}

/// 目标卡：左滑露出「取消 / 编辑 / 删除」，右滑或点一下自动收回
class _SwipeableGoalTile extends ConsumerWidget {
  const _SwipeableGoalTile({required this.plan, required this.goal});

  final GoalComputation plan;
  final SavingsGoal? goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    final g = goal;
    if (g == null) return GoalCard(plan: plan);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Slidable(
        key: ValueKey('goal-${g.id}'),
        groupTag: 'goals',
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.64,
          children: [
            SlidableAction(
              onPressed: (ctx) => Slidable.of(ctx)?.close(),
              backgroundColor: p.cardHi,
              foregroundColor: p.muted,
              icon: Icons.close_rounded,
              label: '取消',
            ),
            SlidableAction(
              onPressed: (ctx) {
                Slidable.of(ctx)?.close();
                showGoalFormSheet(context, ref, editing: g);
              },
              backgroundColor: p.blue.withValues(alpha: 0.16),
              foregroundColor: p.blue,
              icon: Icons.edit_outlined,
              label: '编辑',
            ),
            SlidableAction(
              onPressed: (ctx) async {
                Slidable.of(ctx)?.close();
                await _confirmDelete(context, ref, g);
              },
              backgroundColor: p.danger.withValues(alpha: 0.16),
              foregroundColor: p.danger,
              icon: Icons.delete_outline_rounded,
              label: '删除',
            ),
          ],
        ),
        child: GoalCard(plan: plan),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  SavingsGoal goal,
) async {
  final p = Palette.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('删除目标'),
      content: Text(
        '「${goal.name}」以及它的全部存入记录都会被删掉，删除后不可恢复。',
        style: TextStyle(color: p.muted, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('再想想'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: p.danger),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(repositoryProvider).deleteGoal(goal.id);
    await ref.read(settingsProvider.notifier).syncReminder();
  }
}
