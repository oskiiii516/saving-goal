"""生成 App 图标（简约版）：深色底 + 绿色进度环 + 中心圆点。

设计说明
--------
- 图形只有两个元素：一段 3/4 的圆环（进度）与中心一个圆点（钱/目标）
- 与 App 内的 SlimProgress 进度条语言一致，缩小到 48px 仍然认得出
- 环用 4x 超采样绘制后缩放，避免锯齿；线宽与环径的比例是手调的
- 输出 icon_1024.png（整方，用于文档/iOS）与 foreground_*.png（透明底，给自适应图标）
"""
from PIL import Image, ImageDraw
import math
import pathlib

OUT = pathlib.Path(__file__).parent

# ---- 尺寸与颜色 -------------------------------------------------------------
FINAL = 1024
SS = 4                      # 超采样倍数
S = FINAL * SS

BG = (11, 14, 20, 255)      # #0B0E14，与 App 深色背景一致
RING_BRIGHT = (86, 211, 100)
RING_DEEP = (35, 134, 54)
DOT = (63, 185, 80)

CX = CY = S / 2
R = S * 0.352               # 弧线的外半径（PIL 的 arc 从 box 向内画）
W = int(S * 0.088)          # 环线宽
R_MID = R - W / 2           # 环中心线半径，端点圆头要落在这一圈上
START = 315                 # 从右上方起笔，缺口对称留在正上方
SWEEP = 270                 # 顺时针扫 3/4


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def draw_ring(img):
    """在给定 RGBA 图上画环 + 中心点（透明底，便于复用为前景层）。"""
    d = ImageDraw.Draw(img)
    box = [CX - R, CY - R, CX + R, CY + R]

    seg = 72
    step = SWEEP / seg
    for i in range(seg):
        a0 = START + i * step
        t = i / (seg - 1)
        # 由深到亮：顺时针走一圈等于「朝目标推进」
        col = lerp(RING_DEEP, RING_BRIGHT, t)
        # 每段多画 1 度，避免段间出现细缝
        d.arc(box, a0, a0 + step + 1, fill=col + (255,), width=W)

    # 两端补圆头，让环的收口干净
    for ang, col in ((START, RING_DEEP), (START + SWEEP, RING_BRIGHT)):
        rad = math.radians(ang)
        px = CX + R_MID * math.cos(rad)
        py = CY + R_MID * math.sin(rad)
        d.ellipse([px - W / 2, py - W / 2, px + W / 2, py + W / 2], fill=col + (255,))

    # 中心圆点
    dot = S * 0.078
    d.ellipse([CX - dot, CY - dot, CX + dot, CY + dot], fill=DOT + (255,))


# ---- 整方图标（带背景） -----------------------------------------------------
full = Image.new("RGBA", (S, S), BG)
draw_ring(full)
icon = full.resize((FINAL, FINAL), Image.LANCZOS)
icon.save(OUT / "icon_1024.png")
print("wrote", OUT / "icon_1024.png")

# ---- 前景层（透明底，内容缩到安全区内，供 adaptive icon 用） ----------------
# Android 自适应图标：108dp 画布，中间 72dp 为可见安全区，四周会被裁切
front = Image.new("RGBA", (S, S), (0, 0, 0, 0))
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw_ring(fg)
fg = fg.resize((int(S * 0.60), int(S * 0.60)), Image.LANCZOS)
off = (S - fg.width) // 2
front.alpha_composite(fg, (off, off))
for name, size in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                   ("xxhdpi", 324), ("xxxhdpi", 432)):
    front.resize((size, size), Image.LANCZOS).save(OUT / f"foreground_{name}.png")
print("wrote foreground_*.png")

# ---- 检查：角像素必须是不透明深色 ------------------------------------------
print("corner:", icon.getpixel((2, 2)), "center:", icon.getpixel((512, 512)))
