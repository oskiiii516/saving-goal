"""把 icon_1024.png 切成 Android 各密度的 ic_launcher.png。"""
from PIL import Image
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2] / "app" / "android" / "app" / "src" / "main" / "res"
SRC = pathlib.Path(__file__).parent / "icon_1024.png"

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

img = Image.open(SRC).convert("RGBA")
for folder, size in SIZES.items():
    out = ROOT / folder / "ic_launcher.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(out)
    print("wrote", out, size)
