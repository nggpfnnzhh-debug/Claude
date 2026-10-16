#!/bin/bash
# Erzeugt App-Store-Screenshots im iPhone- (6,9") und iPad-Simulator (13").
# Aufruf: scripts/screenshots.sh <Pfad zur Simulator-.app> <Ausgabeordner>
set -euo pipefail

APP="$1"
OUT="$2"
BUNDLE_ID="de.podolskis.kleineentdecker"
SCREENS=(home counting letters shapes patterns)
mkdir -p "$OUT"

find_device() {
  xcrun simctl list devices available -j | python3 -c '
import json, re, sys
pattern = re.compile(sys.argv[1])
devices = json.load(sys.stdin)["devices"]
matches = [d for runtime, ds in sorted(devices.items()) if "iOS" in runtime for d in ds if pattern.search(d["name"])]
print(matches[-1]["udid"] if matches else "")
' "$1"
}

shoot() {
  local label="$1" pattern="$2"
  local udid
  udid=$(find_device "$pattern")
  if [ -z "$udid" ]; then
    echo "::error::Kein Simulator für $label gefunden ($pattern)"
    xcrun simctl list devices available
    exit 1
  fi
  echo "== $label: $udid"
  xcrun simctl boot "$udid" || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 || true
  xcrun simctl install "$udid" "$APP"
  local i=1
  for screen in "${SCREENS[@]}"; do
    xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" -screenshot "$screen" >/dev/null
    sleep 8
    xcrun simctl io "$udid" screenshot "$OUT/${label}_${i}_${screen}.png"
    i=$((i + 1))
  done
  xcrun simctl shutdown "$udid" || true
}

shoot iPhone 'iPhone.*Pro Max'
shoot iPad 'iPad Pro 13-inch'

for f in "$OUT"/*.png; do
  echo "$(basename "$f"): $(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}')"
done
