# -*- coding: utf-8 -*-
"""修 charts.dart 里被写成真实换行的工具提示字符串。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\app\lib\ui\charts.dart")
s = p.read_text(encoding="utf-8")

broken = (
    "                  '${y.year} 年\n'\n"
    "                  '应存 ${SavingsEngine.fmt(y.plannedCents)}\n'\n"
    "                  '实存 ${SavingsEngine.fmt(y.actualCents)}\n'\n"
    "                  '${y.depositsCount} 笔',\n"
)
fixed = (
    "                  '${y.year} 年\\n'\n"
    "                  '应存 ${SavingsEngine.fmt(y.plannedCents)}\\n'\n"
    "                  '实存 ${SavingsEngine.fmt(y.actualCents)}\\n'\n"
    "                  '${y.depositsCount} 笔',\n"
)

assert broken in s, "没找到损坏的片段"
p.write_text(s.replace(broken, fixed, 1), encoding="utf-8")
print("fixed")
