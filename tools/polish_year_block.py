# -*- coding: utf-8 -*-
"""年度柱宽自适应 + 未来年份文案调整。"""
import pathlib

c = pathlib.Path(r"D:\dev\saving-goal-app\app\lib\ui\charts.dart")
cs = c.read_text(encoding="utf-8")

cs = cs.replace("""    final maxY =
        years.map((y) => math.max(y.plannedCents, y.actualCents)).reduce(math.max) /
            100;""",
"""    final maxY =
        years.map((y) => math.max(y.plannedCents, y.actualCents)).reduce(math.max) /
            100;
    // 年份少的时候把柱子加粗，否则两根细柱孤零零挂在中间
    final barWidth = years.length <= 2
        ? 30.0
        : years.length <= 4
            ? 22.0
            : 13.0;""", 1)

cs = cs.replace("""                    toY: years[i].plannedCents / 100,
                    width: 13,""",
"""                    toY: years[i].plannedCents / 100,
                    width: barWidth,""", 1)
cs = cs.replace("""                    toY: years[i].actualCents / 100,
                    width: 13,""",
"""                    toY: years[i].actualCents / 100,
                    width: barWidth,""", 1)
c.write_text(cs, encoding="utf-8")

i = pathlib.Path(r"D:\dev\saving-goal-app\app\lib\ui\insights_page.dart")
s = i.read_text(encoding="utf-8")

old = """            Text(
              y.gapCents > 0
                  ? '还差 ${SavingsEngine.fmt(y.gapCents)} / 计划 ${SavingsEngine.fmt(y.plannedCents)}'
                  : '已达成 · 应存 ${SavingsEngine.fmt(y.plannedCents)}',
              style: TextStyle(color: p.faint, fontSize: 11),
            ),"""

new = """            Text(
              y.isFuture
                  ? '计划 ${SavingsEngine.fmt(y.plannedCents)} · 还没到'
                  : y.gapCents > 0
                      ? '还差 ${SavingsEngine.fmt(y.gapCents)} / 计划 ${SavingsEngine.fmt(y.plannedCents)}'
                      : '已达成 · 应存 ${SavingsEngine.fmt(y.plannedCents)}',
              style: TextStyle(color: p.faint, fontSize: 11),
            ),"""

assert old in s
s = s.replace(old, new, 1)
i.write_text(s, encoding="utf-8")
print("ok")
