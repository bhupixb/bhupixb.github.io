#!/bin/bash
# Copy a blog post to the clipboard as rich HTML and open a new Medium story
# in Brave's "Personal" profile. Then click the title field and press Cmd+V.
#
# Usage: to-medium.sh <post/index.md|mdx> [brave-profile-name]
set -euo pipefail

post="$1"
profile_name="${2:-Personal}"
here="$(cd "$(dirname "$0")" && pwd)"
out="${TMPDIR:-/tmp}/medium-$(basename "$(dirname "$post")").html"

python3 -I "$here/md2medium.py" "$post" "$out"

hex=$(xxd -p "$out" | tr -d '\n')
osascript -e "set the clipboard to «data HTML${hex}»"

local_state="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Local State"
profile_dir=$(python3 -I -c '
import json, sys
cache = json.load(open(sys.argv[1]))["profile"]["info_cache"]
print(next((k for k, v in cache.items() if v.get("name") == sys.argv[2]), "Default"))
' "$local_state" "$profile_name")

open -na "Brave Browser" --args --profile-directory="$profile_dir" "https://medium.com/new-story"
echo "Copied $out to clipboard. Opened Medium in Brave profile '$profile_name' ($profile_dir)."
