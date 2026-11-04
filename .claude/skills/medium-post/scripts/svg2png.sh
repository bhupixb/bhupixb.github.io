#!/bin/bash
# Render an SVG to a PNG at 2x with headless Chrome, sized from the SVG's own
# width/height attributes.
#
# Usage: svg2png.sh <in.svg> [out.png] [scale]
#
# Headless Chrome needs access to the display, so in Claude Code run this with
# the sandbox disabled. Brave's headless mode hangs on macOS; Chrome works.
set -euo pipefail

svg="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
png="${2:-${svg%.svg}.png}"
scale="${3:-2}"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

read -r w h < <(python3 -I -c '
import re, sys
s = open(sys.argv[1]).read()
tag = re.search(r"<svg[^>]*>", s).group(0)
w = re.search(r"\bwidth=\"([\d.]+)", tag); h = re.search(r"\bheight=\"([\d.]+)", tag)
if not (w and h):
    vb = re.search(r"viewBox=\"[\d.\s-]+?([\d.]+)\s+([\d.]+)\"", tag).groups()
    print(round(float(vb[0])), round(float(vb[1])))
else:
    print(round(float(w.group(1))), round(float(h.group(1))))
' "$svg")

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
printf '<html><body style="margin:0"><img src="file://%s" width="%s" height="%s" style="display:block"></body></html>' \
  "$svg" "$w" "$h" > "$work/page.html"

rm -f "$png"
"$chrome" --headless --disable-gpu --hide-scrollbars --no-first-run \
  --user-data-dir="$work/profile" --allow-file-access-from-files \
  --window-size="$w,$h" --force-device-scale-factor="$scale" \
  --screenshot="$png" "file://$work/page.html" >"$work/log" 2>&1 &
pid=$!
for _ in $(seq 1 120); do [ -s "$png" ] && break; /bin/sleep 0.5; done
/bin/sleep 1
kill "$pid" 2>/dev/null || true

[ -s "$png" ] || { echo "render failed, see log:"; grep -v CVDisplayLink "$work/log" | tail -5; exit 1; }
echo "$png ($((w * scale))x$((h * scale)))"
