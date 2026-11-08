#!/usr/bin/env bash
# 修复：sqlite3 包的 native assets build hook 会从 github.com 下载预编译 .so，
# 国内直连必然超时，导致 `Target build_hooks failed`。
# 这个脚本把下载地址改写成 GitHub 加速镜像（默认 gh-proxy.com）。
#
# 何时需要重跑：`flutter pub cache repair`、升级 sqlite3 包、清空 PUB_CACHE 之后。
# 用法： bash tools/patch-pubcache-mirror.sh [镜像前缀]
set -euo pipefail

MIRROR="${1:-${GH_MIRROR:-https://gh-proxy.com/}}"
PUB_CACHE="${PUB_CACHE:-D:/dev/pub-cache}"
ORIG="r'https://github.com/simolus3/sqlite3.dart/releases/download/\$RELEASE_TAG/\$FILENAME'"
NEW="r'${MIRROR}https://github.com/simolus3/sqlite3.dart/releases/download/\$RELEASE_TAG/\$FILENAME'"

found=0
for d in "$PUB_CACHE"/hosted/pub.dev/sqlite3-*/; do
  f="$d/lib/src/hook/compile/description.dart"
  [ -f "$f" ] || continue
  found=1
  python - "$f" "$ORIG" "$NEW" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
orig, new = sys.argv[2], sys.argv[3]
s = p.read_text(encoding='utf-8')
if new in s:
    print('  already patched:', p.parent.parent.parent.parent.name)
elif orig in s:
    p.write_text(s.replace(orig, new), encoding='utf-8')
    print('  patched:', p)
else:
    print('  pattern not found (版本变了，需要人工看):', p)
PY
done

[ "$found" = 1 ] || { echo "没找到 sqlite3 包，先跑 flutter pub get"; exit 1; }
echo "完成。mirror = $MIRROR"
