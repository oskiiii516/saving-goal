import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/allocate.dart';
import '../core/engine.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'palette.dart';
import 'widgets.dart';

Future<void> showAllocationSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AllocationSheet(),
  );
}

class _AllocationSheet extends ConsumerStatefulWidget {
  const _AllocationSheet();

  @override
  ConsumerState<_AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends ConsumerState<_AllocationSheet> {
  final _controller = TextEditingController();
  bool _inited = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _budgetCents => parseYuanToCents(_controller.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final plans = ref.watch(computationsProvider);
    final agg = ref.watch(aggregateProvider);
    final nowYm = ref.watch(nowYmProvider);

    if (!_inited && plans.isNotEmpty) {
      final shortfall =
          agg.requiredThisMonthCents - agg.paidThisMonthCents;
      _controller.text = SavingsEngine.fmt(shortfall > 0 ? shortfall : 0);
      _inited = true;
    }

    final result = allocate(plans, _budgetCents);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.86,
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                children: [
                  IconBadge(icon: Icons.alt_route_rounded, color: p.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('这笔钱怎么分',
                            style: TextStyle(
                                color: p.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('按优先级先补本月缺口，剩下的提前预存',
                            style: TextStyle(color: p.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: p.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: p.text, fontSize: 20, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: '本月能拿出多少钱（元）',
                  prefixIcon: Icon(Icons.payments_outlined, color: p.green),
                  suffixIcon: TextButton(
                    onPressed: () {
                      final shortfall =
                          agg.requiredThisMonthCents - agg.paidThisMonthCents;
                      setState(() {
                        _controller.text =
                            SavingsEngine.fmt(shortfall > 0 ? shortfall : 0);
                      });
                    },
                    child: const Text('按需'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                children: [
                  if (plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('还没有目标',
                            style: TextStyle(color: p.muted, fontSize: 13)),
                      ),
                    ),
                  for (final item in result.items) _AllocationTile(item: item),
                  const SizedBox(height: 6),
                  if (result.unassignedCents > 0)
                    Panel(
                      color: p.cardHi,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 15, color: p.warn),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '还有 ${SavingsEngine.fmt(result.unassignedCents)} 元没分出去'
                              '（各目标都到顶了，可以少存点或少填点）',
                              style: TextStyle(color: p.warn, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  18, 12, 18, 12 + media.padding.bottom),
              decoration: BoxDecoration(
                color: p.card,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('合计分配',
                          style: TextStyle(color: p.muted, fontSize: 12)),
                      const Spacer(),
                      Money(
                        SavingsEngine.fmt(result.assignedCents),
                        size: 20,
                        color: p.green,
                      ),
                      Text(' 元',
                          style: TextStyle(color: p.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: result.assignedCents <= 0
                        ? null
                        : () async {
                            final items = [
                              for (final i in result.items)
                                if (i.suggestedCents > 0)
                                  (
                                    goalId: i.plan.goalId,
                                    ym: nowYm,
                                    cents: i.suggestedCents,
                                    note: i.meetsThisMonth ? '本月分配' : '本月分配+预存',
                                  ),
                            ];
                            await ref
                                .read(repositoryProvider)
                                .addDepositsBatch(items);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '已记账 ${items.length} 笔，合计 ${SavingsEngine.fmtMoney(result.assignedCents)}'),
                              ),
                            );
                          },
                    child: const Text('按这个方案记账'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({required this.item});

  final AllocationItem item;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final plan = item.plan;
    final got = item.suggestedCents;
    final need = plan.remainingThisMonthCents;
    final color = got == 0
        ? p.faint
        : (item.meetsThisMonth ? p.green : p.warn);

    final String detail;
    if (got == 0) {
      detail = need > 0
          ? '本月还差 ${SavingsEngine.fmt(need)}，这轮没分到'
          : '本月已满足';
    } else if (item.meetsThisMonth) {
      final extra = got - need;
      detail = extra > 0
          ? '补满本月 ${SavingsEngine.fmt(need)} + 预存 ${SavingsEngine.fmt(extra)}'
          : '补满本月缺口';
    } else {
      detail = '补 ${SavingsEngine.fmt(got)}，本月还差 ${SavingsEngine.fmt(item.stillShortThisMonth)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          children: [
            IconBadge(
              icon: got > 0 ? Icons.south_west_rounded : Icons.remove_rounded,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: p.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plan.status.label,
                        style: TextStyle(
                            color: p.forStatus(plan.status.name), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: TextStyle(
                          color: p.faint, fontSize: 10.5, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Money(SavingsEngine.fmt(got), size: 15, color: color),
          ],
        ),
      ),
    );
  }
}
