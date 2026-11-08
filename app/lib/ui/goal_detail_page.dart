import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'charts.dart';
import 'deposit_form_sheet.dart';
import 'goal_form_sheet.dart';
import 'palette.dart';
import 'widgets.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    final comp = ref.watch(computationProvider(goalId));
    final goalRows = ref.watch(goalsProvider).asData?.value ?? const <GoalRow>[];
    GoalRow? row;
    for (final r in goalRows) {
      if (r.id == goalId) row = r;
    }

    if (comp == null || row == null) {
      return Scaffold(body: Center(child: Text('目标不存在', style: TextStyle(color: p.muted))));
    }

    final goal = row.toModel();
    final deposits = ref.watch(depositsOfGoalProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: Text(comp.name),
        actions: [
          PopupMenuButton<String>(
            color: p.cardHi,
            onSelected: (v) async {
              if (v == 'edit') {
                await showGoalFormSheet(context, ref, editing: goal);
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('删除目标？'),
                    content: Text('「${goal.name}」的 ${deposits.length} 条存入记录也会一起删掉。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('删除',
                            style: TextStyle(color: p.danger)),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(repositoryProvider).deleteGoal(goalId);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑目标')),
              PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: p.danger)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _HeadCard(comp: comp),
          const SizedBox(height: 20),
          const SectionTitle('趋势'),
          const SizedBox(height: 6),
          Panel(
            padding: const EdgeInsets.fromLTRB(6, 14, 14, 8),
            child: Column(
              children: [
                CumulativeChart(months: comp.months, height: 150),
                const SizedBox(height: 6),
                ChartLegend(items: [
                  (p.green, '实际累计'),
                  (p.muted, '计划累计'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StrategyBlock(goal: goal),
          const SizedBox(height: 20),
          const SectionTitle('月度明细'),
          const SizedBox(height: 8),
          _MonthTable(comp: comp),
          const SizedBox(height: 10),
          Text(
            '累计实存从期初已存起算；未来月显示基准值，补缴后会自动重算。',
            style: TextStyle(color: p.faint, fontSize: 11, height: 1.6),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => showDepositFormSheet(context, ref, goal: goal),
            icon: const Icon(Icons.add_card, size: 18),
            label: const Text('记一笔存入'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showGoalFormSheet(context, ref, editing: goal),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('编辑目标'),
          ),
          const SizedBox(height: 22),
          SectionTitle(
            '存入记录',
            trailing: Text('${deposits.length} 笔',
                style: TextStyle(color: p.muted, fontSize: 11.5)),
          ),
          const SizedBox(height: 8),
          if (deposits.isEmpty)
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('还没有存入记录',
                    style: TextStyle(color: p.muted, fontSize: 12)),
              ),
            )
          else
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < deposits.length; i++) ...[
                    _DepositTile(
                      deposit: deposits[i],
                      onDelete: () async {
                        await ref
                            .read(repositoryProvider)
                            .deleteDeposit(deposits[i].id);
                      },
                    ),
                    if (i != deposits.length - 1)
                      Divider(height: 1, indent: 14, endIndent: 14, color: p.border),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeadCard extends StatelessWidget {
  const _HeadCard({required this.comp});

  final GoalComputation comp;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Panel(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [p.heroFrom, p.heroTo],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: comp.status),
              const Spacer(),
              Text(
                '${comp.monthsLeftInclThis} / ${comp.totalMonths} 个月',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Money(SavingsEngine.fmt(comp.savedTotalCents),
                  size: 30, weight: FontWeight.w800),
              const SizedBox(width: 4),
              Text(
                '/ ${SavingsEngine.fmt(comp.targetCents)} 元',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SlimProgress(value: comp.progress, height: 7),
          const SizedBox(height: 15),
          Row(
            children: [
              StatColumn(
                label: '本月应存',
                value: SavingsEngine.fmt(comp.requiredThisMonthCents),
                color: comp.status == GoalStatus.done ? p.muted : p.warn,
              ),
              const SizedBox(width: 18),
              StatColumn(
                label: '本月已存',
                value: SavingsEngine.fmt(comp.paidThisMonthCents),
                color: p.green,
              ),
              const Spacer(),
              StatColumn(
                label: comp.overCents > 0 ? '超额' : '还差',
                value: SavingsEngine.fmt(
                    comp.overCents > 0 ? comp.overCents : comp.gapCents),
                color: comp.overCents > 0 ? p.blue : p.danger,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(comp.basis,
              style: TextStyle(color: p.muted, fontSize: 11, height: 1.6)),
          if (comp.payDay >= 1 && comp.payDay <= 28) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 12, color: p.muted),
                const SizedBox(width: 5),
                Text(
                  '每月 ${comp.payDay} 号存这笔钱，当天提醒',
                  style: TextStyle(color: p.muted, fontSize: 11),
                ),
              ],
            ),
          ],
          if (comp.initialCents > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.savings_outlined, size: 12, color: p.muted),
                const SizedBox(width: 5),
                Text(
                  '其中期初已存 ${SavingsEngine.fmt(comp.initialCents)}（不在月度明细里）',
                  style: TextStyle(color: p.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 策略切换：欠缴怎么补 + 计算方式
class _StrategyBlock extends ConsumerWidget {
  const _StrategyBlock({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    Future<void> patch(SavingsGoal g) =>
        ref.read(repositoryProvider).updateGoal(g);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('存少了怎么补'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in ArrearsMode.values)
              _ChoiceChip(
                label: switch (m) {
                  ArrearsMode.spread => '摊到剩余每月',
                  ArrearsMode.catchUpNow => '下月一次补齐',
                  ArrearsMode.tail => '留到末期补',
                },
                selected: goal.arrearsMode == m,
                onTap: () => patch(goal.copyWith(arrearsMode: m)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionTitle('计算方式'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: '固定月供',
                expand: true,
                selected: goal.model == SavingsModel.schedule,
                onTap: () => patch(goal.copyWith(model: SavingsModel.schedule)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChoiceChip(
                label: '滚动重排',
                expand: true,
                selected: goal.model == SavingsModel.rebase,
                onTap: () => patch(goal.copyWith(model: SavingsModel.rebase)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          goal.model == SavingsModel.schedule
              ? '每月基准额固定，欠的部分按上面策略补；多存会减少后续应存。'
              : '每月按「剩余金额 ÷ 剩余月数」重算，多存立刻减负，欠存立刻加压。',
          style: TextStyle(color: p.faint, fontSize: 11, height: 1.6),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: expand ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.green.withValues(alpha: 0.13) : p.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? p.green.withValues(alpha: 0.55) : p.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? p.green : p.muted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 月度明细表（最近月在上）
class _MonthTable extends StatelessWidget {
  const _MonthTable({required this.comp});

  final GoalComputation comp;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final rows = comp.months.reversed.toList();
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _Th('月份')),
                Expanded(flex: 3, child: _Th('应存', right: true)),
                Expanded(flex: 3, child: _Th('实存', right: true)),
                Expanded(flex: 3, child: _Th('差额', right: true)),
                Expanded(flex: 3, child: _Th('累计实存', right: true)),
              ],
            ),
          ),
          for (final m in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: m.isCurrent ? p.green.withValues(alpha: 0.08) : null,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      m.ym,
                      style: TextStyle(
                        color: m.isCurrent
                            ? p.green
                            : m.isFuture
                                ? p.faint
                                : p.text,
                        fontSize: 12.5,
                        fontWeight:
                            m.isCurrent ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Td(SavingsEngine.fmt(m.plannedCents),
                        color: m.isFuture ? p.faint : null),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Td(
                      SavingsEngine.fmt(m.actualCents),
                      color: m.actualCents > 0 ? p.green : p.faint,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Td(
                      m.isFuture
                          ? '—'
                          : m.deltaCents == 0
                              ? '—'
                              : '${m.deltaCents > 0 ? '+' : ''}${SavingsEngine.fmt(m.deltaCents)}',
                      color: m.isFuture
                          ? p.faint
                          : m.deltaCents > 0
                              ? p.green
                              : m.deltaCents < 0
                                  ? p.danger
                                  : p.faint,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Td(SavingsEngine.fmt(m.cumActualCents),
                        color: p.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text, {this.right = false});

  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: Palette.of(context).muted, fontSize: 11),
      );
}

class _Td extends StatelessWidget {
  const _Td(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color ?? Palette.of(context).text,
          fontSize: 12.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.deposit, required this.onDelete});

  final Deposit deposit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 4, 9),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Text(deposit.ym,
                style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              deposit.note.isEmpty ? '存入' : deposit.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontSize: 13),
            ),
          ),
          Money('+${SavingsEngine.fmt(deposit.amountCents)}',
              size: 14, color: p.green),
          IconButton(
            onPressed: () => onDelete(),
            icon: Icon(Icons.close_rounded, size: 16, color: p.faint),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
