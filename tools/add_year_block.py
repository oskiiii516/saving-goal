# -*- coding: utf-8 -*-
"""在统计页加入「按年存钱」区块：年度双柱图 + 年度明细列表。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\app\lib\ui\insights_page.dart")
s = p.read_text(encoding="utf-8")

# 1) import
s = s.replace(
    "import '../core/engine.dart';",
    "import '../core/engine.dart';\n"
    "import '../data/database.dart';\n"
    "import '../data/repository.dart';",
    1,
)

# 2) build 里算年度数据
s = s.replace(
    "    final combined = _combineMonths(plans, nowYm);",
    "    final combined = _combineMonths(plans, nowYm);\n"
    "    final depositRows =\n"
    "        ref.watch(depositsProvider).asData?.value ?? const <DepositRow>[];\n"
    "    final yearly = SavingsEngine.yearlySummary(\n"
    "      plans: plans,\n"
    "      deposits: [for (final r in depositRows) r.toModel()],\n"
    "      nowYm: nowYm,\n"
    "    );",
    1,
)

# 3) 年度区块插在「各目标进度」之前
block = """              const SizedBox(height: 18),
              SectionTitle('按年存钱',
                  trailing: ChartLegend(items: [
                    (p.muted, '应存'),
                    (p.green, '实存'),
                  ])),
              Panel(
                padding: const EdgeInsets.fromLTRB(6, 14, 14, 8),
                child: YearlyBarChart(years: yearly),
              ),
              const SizedBox(height: 10),
              Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < yearly.length; i++) ...[
                      if (i > 0) Divider(color: p.border, height: 1, indent: 16),
                      _YearRow(summary: yearly[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('各目标进度'),"""

s = s.replace("              const SizedBox(height: 18),\n              const SectionTitle('各目标进度'),", block, 1)

# 4) 追加 _YearRow 组件
row_cls = '''
/// 年度一行：年份 + 目标数/笔数 + 实存/应存 + 进度条
class _YearRow extends StatelessWidget {
  const _YearRow({required this.summary});

  final YearSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final y = summary;
    final color = y.isFuture
        ? p.muted
        : y.met
            ? p.green
            : (y.actualCents > 0 ? p.warn : p.muted);

    final String sub;
    if (y.plannedCents <= 0) {
      sub = y.depositsCount > 0 ? '${y.depositsCount} 笔存入' : '无计划';
    } else {
      final pct = (y.progress * 100).round();
      sub = '${y.goalCount} 个目标 · ${y.depositsCount} 笔 · 完成 $pct%';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${y.year}',
                style: TextStyle(
                  color: y.isCurrent ? p.text : p.text.withValues(alpha: 0.82),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (y.isCurrent) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('今年',
                      style: TextStyle(
                          color: p.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 11)),
                ),
              ),
              Text(
                SavingsEngine.fmtMoney(y.actualCents),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (y.plannedCents > 0) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: y.progress,
                minHeight: 5,
                backgroundColor: p.cardHi,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              y.gapCents > 0
                  ? '还差 ${SavingsEngine.fmt(y.gapCents)} / 计划 ${SavingsEngine.fmt(y.plannedCents)}'
                  : '已达成 · 应存 ${SavingsEngine.fmt(y.plannedCents)}',
              style: TextStyle(color: p.faint, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
'''

idx = s.rstrip().rfind("}")
s = s.rstrip()[: idx + 1] + "\n" + row_cls
p.write_text(s, encoding="utf-8")
print("insights ok")
