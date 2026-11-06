#!/usr/bin/env bash
# Regenerates docs/demo.gif and docs/*.png by driving the real launcher in a sandbox (nothing of yours is touched).
# Needs: Plasma 6, plasmawindowed, kpackagetool6, python3 + Pillow.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
ID=io.github.darasamii.launchertest
TMP=$(mktemp -d)
trap 'kpackagetool6 -t Plasma/Applet -r $ID >/dev/null 2>&1; rm -rf "$TMP"' EXIT
mkdir -p "$TMP/out/frames" "$ROOT/docs"
cp -r "$ROOT/launcher" "$TMP/pkg"
sed -i "s/io.github.darasamii.launcher\"/$ID\"/" "$TMP/pkg/metadata.json"
python3 "$ROOT/tests/patch.py" "$TMP/pkg" "$HERE/Demo.qml" "$TMP/out" || exit 2
kpackagetool6 -t Plasma/Applet -u "$TMP/pkg" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$TMP/pkg" >/dev/null 2>&1 || exit 2
while pgrep -f "plasmawindowed $ID" >/dev/null; do sleep 1; done
since=$(date +"%Y-%m-%d %H:%M:%S")
timeout 120 plasmawindowed $ID >/dev/null 2>&1 &
for _ in $(seq 1 120); do sleep 1; journalctl --user --since "$since" -o cat 2>/dev/null | grep -q "DEMO DONE" && break; done
sleep 2; pkill -f "plasmawindowed $ID" 2>/dev/null
python3 "$HERE/make_gif.py" "$TMP/out" "$ROOT/docs"
