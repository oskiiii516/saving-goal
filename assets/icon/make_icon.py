"""生成 App 图标：深色底 + 绿色存钱罐 + 金币。一次性脚本，产物是 PNG。"""
from PIL import Image, ImageDraw, ImageFont
import pathlib

S = 1024
BG = (13, 17, 23, 255)
GREEN = (63, 185, 80, 255)
GREEN_DARK = (46, 160, 67, 255)
GOLD = (240, 200, 70, 255)
SLOT = (10, 14, 18, 255)

img = Image.new("RGBA", (S, S), BG)

# 背景径向微光（单独图层做 alpha 合成，直接画会覆盖掉背景的 alpha）
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for i in range(70):
    r = 640 - i * 9
    if r <= 0:
        break
    a = int(9 * (1 - i / 70))
    gd.ellipse([S / 2 - r, S / 2 - r - 40, S / 2 + r, S / 2 + r - 40],
               fill=(63, 185, 80, a))
img = Image.alpha_composite(img, glow)
d = ImageDraw.Draw(img)

# 腿
d.rounded_rectangle([300, 790, 400, 880], radius=34, fill=GREEN_DARK)
d.rounded_rectangle([620, 790, 720, 880], radius=34, fill=GREEN_DARK)

# 身体
d.ellipse([190, 360, 834, 830], fill=GREEN)
# 耳朵
d.ellipse([300, 300, 400, 400], fill=GREEN_DARK)
d.ellipse([600, 300, 700, 400], fill=GREEN_DARK)
# 鼻子
d.ellipse([430, 570, 610, 700], fill=GREEN_DARK)
d.ellipse([470, 605, 495, 630], fill=SLOT)
d.ellipse([545, 605, 570, 630], fill=SLOT)

# 投币口
d.rounded_rectangle([400, 400, 640, 448], radius=24, fill=SLOT)

# 金币（落在投币口上）
cx, cy, r = 520, 250, 118
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD)
d.ellipse([cx - r + 16, cy - r + 16, cx + r - 16, cy + r - 16],
          outline=(190, 150, 30, 255), width=8)

# 金币上的 ¥
font = None
for p in [r"C:\Windows\Fonts\msyhbd.ttc", r"C:\Windows\Fonts\msyh.ttc",
          r"C:\Windows\Fonts\simhei.ttf"]:
    if pathlib.Path(p).exists():
        font = ImageFont.truetype(p, 150)
        break
if font:
    txt = "¥"
    box = d.textbbox((0, 0), txt, font=font)
    d.text((cx - (box[2] - box[0]) / 2 - box[0],
            cy - (box[3] - box[1]) / 2 - box[1] - 6),
           txt, font=font, fill=(120, 90, 10, 255))

out = pathlib.Path(__file__).parent / "icon_1024.png"
img.save(out)
print("saved", out)
