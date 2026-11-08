# -*- coding: utf-8 -*-
"""README 记录 v1.5.0：按年统计。"""
import pathlib

p = pathlib.Path(r"D:\dev\saving-goal-app\README.md")
s = p.read_text(encoding="utf-8")

# 1) 已实现表：插一行
s = s.replace(
    "| **累计曲线 / 每月应存柱状图** | `ui/charts.dart`（`CumulativeChart` / `MonthlyBarChart`）+ 统计页 |",
    "| **累计曲线 / 每月应存柱状图** | `ui/charts.dart`（`CumulativeChart` / `MonthlyBarChart`）+ 统计页 |\n"
    "| **按年统计：每年应存 / 实存列表 + 年度柱状图** | `engine.yearlySummary()` → `YearSummary`；`ui/charts.dart` 的 `YearlyBarChart` + `ui/insights_page.dart` 的 `_YearRow` |",
    1,
)

# 2) 里程碑
s = s.replace(
    "| M3.9 | 品牌化：改名「一个小目标」+ 新图标 + 关于页 | ✅ v1.4.0 |",
    "| M3.9 | 品牌化：改名「一个小目标」+ 新图标 + 关于页 | ✅ v1.4.0 |\n"
    "| M3.10 | 按年统计（年度应存/实存列表 + 年度柱状图） | ✅ v1.5.0 |",
    1,
)

# 3) 版本历史：插在最前面
s = s.replace(
    "### 版本历史\n\n- **v1.4.0**（2026-11）",
    """### 版本历史

- **v1.5.0**（2026-11）
  - **按年存钱**：统计页新增「按年存钱」区块 —— 上面一张年度双柱图（灰=应存、绿/橙=实存，今年高亮），下面逐年一行：`2026 今年 · 2 个目标 · 4 笔 · 完成 34% · ¥3,900.00`，再跟一条进度条和「还差 X / 计划 Y」；未来年份显示「计划 X · 还没到」
  - **年度计划额用基准口径**（`buildSchedule`），不是「含补缴的应存」：否则一笔老欠缴会把当年计划额撑大、年度进度永远显示没达成。这条取舍写进了 `engine.dart` 的注释，有 5 组测试守着（`[20]`–`[24]`）
  - **期初已存不计入任何一年**：那是建目标之前就有的钱，年度「实存」只算当年新存进去的
  - 只有流水、没有计划年份（比如补录了去年的存入）也会单独列出来
- **v1.4.0**（2026-11）""",
    1,
)

p.write_text(s, encoding="utf-8")
print("readme ok")
