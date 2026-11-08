import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/engine.dart';
import 'palette.dart';

/// 累计曲线：计划累计 vs 实际累计。一眼看出「存得比计划快还是慢」
/// X 轴标签抽稀：每 step 个显示一个；末尾月若离上一个标签不足 step 就跳过，
/// 否则会出现「27-06 27-07」两个标签叠在一起。
bool _showAxisLabel(int i, int length, int step) {
  if (i % step == 0) return true;
  final last = length - 1;
  if (i != last) return false;
  final prev = last - (last % step);
  return last - prev >= step;
}

class CumulativeChart extends StatelessWidget {
  const CumulativeChart({
    super.key,
    required this.months,
    this.height = 176,
  });

  final List<MonthPlan> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (months.isEmpty) return const SizedBox.shrink();

    final lastCurrent = months.lastIndexWhere((m) => !m.isFuture);
    final cut = lastCurrent < 0 ? 0 : lastCurrent;

    final plannedSpots = [
      for (var i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), months[i].cumPlannedCents / 100),
    ];
    final actualSpots = [
      for (var i = 0; i <= cut; i++)
        FlSpot(i.toDouble(), months[i].cumActualCents / 100),
    ];

    final maxY = math.max(
      months.map((m) => m.cumPlannedCents).reduce(math.max) / 100,
      1.0,
    );
    final step = months.length > 12 ? (months.length / 6).ceil() : 2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (months.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.12,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: p.border, strokeWidth: 1, dashArray: [4, 6]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 3,
                getTitlesWidget: (v, meta) => Text(
                  _shortMoney(v),
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  if (!_showAxisLabel(i, months.length, step)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    months[i].ym.substring(2),
                    style: TextStyle(color: p.faint, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: plannedSpots,
              isCurved: false,
              color: p.muted.withValues(alpha: 0.75),
              barWidth: 2,
              dashArray: const [5, 5],
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: actualSpots,
              isCurved: true,
              curveSmoothness: 0.24,
              color: p.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    p.green.withValues(alpha: 0.28),
                    p.green.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 每月应存 / 实存 双柱
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.months,
    this.height = 176,
  });

  final List<MonthPlan> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (months.isEmpty) return const SizedBox.shrink();

    final maxY = months
            .map((m) => math.max(m.plannedCents, m.actualCents))
            .reduce(math.max) /
        100;
    final step = months.length > 12 ? (months.length / 6).ceil() : 2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: math.max(maxY * 1.15, 1),
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(maxY / 3, 1),
            getDrawingHorizontalLine: (v) =>
                FlLine(color: p.border, strokeWidth: 1, dashArray: [4, 6]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: math.max(maxY / 3, 1),
                getTitlesWidget: (v, meta) => Text(
                  _shortMoney(v),
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  if (!_showAxisLabel(i, months.length, step)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    months[i].ym.substring(2),
                    style: TextStyle(color: p.faint, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => p.cardHi,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final m = months[group.x];
                return BarTooltipItem(
                  '${m.ym}\n应存 ${SavingsEngine.fmt(m.plannedCents)}\n实存 ${SavingsEngine.fmt(m.actualCents)}',
                  TextStyle(color: p.text, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(
                    toY: months[i].plannedCents / 100,
                    width: months.length > 18 ? 4 : 6,
                    color: months[i].isFuture
                        ? p.muted.withValues(alpha: 0.28)
                        : p.muted.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  BarChartRodData(
                    toY: months[i].actualCents / 100,
                    width: months.length > 18 ? 4 : 6,
                    color: months[i].actualCents >= months[i].plannedCents
                        ? p.green
                        : p.warn,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}


/// 每年应存 / 实存 双柱。年份少，标签全显示。
class YearlyBarChart extends StatelessWidget {
  const YearlyBarChart({
    super.key,
    required this.years,
    this.height = 168,
  });

  final List<YearSummary> years;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (years.isEmpty) return const SizedBox.shrink();

    final maxY =
        years.map((y) => math.max(y.plannedCents, y.actualCents)).reduce(math.max) /
            100;
    // 年份少的时候把柱子加粗，否则两根细柱孤零零挂在中间
    final barWidth = years.length <= 2
        ? 30.0
        : years.length <= 4
            ? 22.0
            : 13.0;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: math.max(maxY * 1.18, 1),
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(maxY / 3, 1),
            getDrawingHorizontalLine: (v) =>
                FlLine(color: p.border, strokeWidth: 1, dashArray: [4, 6]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: math.max(maxY / 3, 1),
                getTitlesWidget: (v, meta) => Text(
                  _shortMoney(v),
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= years.length) {
                    return const SizedBox.shrink();
                  }
                  final y = years[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${y.year}',
                      style: TextStyle(
                        color: y.isCurrent ? p.green : p.faint,
                        fontSize: 10,
                        fontWeight:
                            y.isCurrent ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => p.cardHi,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final y = years[group.x];
                return BarTooltipItem(
                  '${y.year} 年\n'
                  '应存 ${SavingsEngine.fmt(y.plannedCents)}\n'
                  '实存 ${SavingsEngine.fmt(y.actualCents)}\n'
                  '${y.depositsCount} 笔',
                  TextStyle(color: p.text, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < years.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: years[i].plannedCents / 100,
                    width: barWidth,
                    color: years[i].isFuture
                        ? p.muted.withValues(alpha: 0.28)
                        : p.muted.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  BarChartRodData(
                    toY: years[i].actualCents / 100,
                    width: barWidth,
                    color: years[i].met ? p.green : p.warn,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _shortMoney(double yuan) {
  if (yuan >= 10000) {
    final w = yuan / 10000;
    return '${w.toStringAsFixed(w >= 10 ? 0 : 1)}万';
  }
  return yuan.toStringAsFixed(0);
}

/// 图例
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  /// (颜色, 文案)
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
