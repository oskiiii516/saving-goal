"""把 icon_1024.png / foreground_*.png 装进 Android 资源，并写好自适应图标声明。"""
from PIL import Image
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2] / "app" / "android" / "app" / "src" / "main" / "res"
HERE = pathlib.Path(__file__).parent

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

icon = Image.open(HERE / "icon_1024.png").convert("RGBA")
for d, size in LEGACY.items():
    out = ROOT / f"mipmap-{d}" / "ic_launcher.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.LANCZOS).save(out)
    print("legacy", out.relative_to(ROOT), size)

for d, size in FOREGROUND.items():
    src = Image.open(HERE / f"foreground_{d}.png").convert("RGBA")
    out = ROOT / f"mipmap-{d}" / "ic_launcher_foreground.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    src.resize((size, size), Image.LANCZOS).save(out)
    print("fg", out.relative_to(ROOT), size)

# 自适应图标（Android 8+），不写就会退回上面那张方的 legacy 图
anydpi = ROOT / "mipmap-anydpi-v26"
anydpi.mkdir(parents=True, exist_ok=True)
(anydpi / "ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background" />\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
    '</adaptive-icon>\n',
    encoding="utf-8",
)
print("wrote", anydpi / "ic_launcher.xml")

# 背景色写进 values/colors.xml
colors = ROOT / "values" / "colors.xml"
xml = colors.read_text(encoding="utf-8")
if "ic_launcher_background" not in xml:
    xml = re.sub(
        r"\n</resources>",
        "\n    <color name=\"ic_launcher_background\">#FF0B0E14</color>\n</resources>",
        xml,
    )
    colors.write_text(xml, encoding="utf-8")
    print("added ic_launcher_background")
