#!/bin/bash
# Erzeugt App-Store-Screenshots im iPhone- (6,9") und iPad-Simulator (13").
# Aufruf: scripts/screenshots.sh <Pfad zur Simulator-.app> <Ausgabeordner>
set -euo pipefail

APP="$1"
OUT="$2"
BUNDLE_ID="de.podolskis.kleineentdecker"
SCREENS=(home counting syllables clock letters)
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
  # Aufwärmen: Der erste Start eines frischen Simulators dauert lange.
  xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshot home >/dev/null
  sleep 40
  local i=1
  for screen in "${SCREENS[@]}"; do
    local file="$OUT/${label}_${i}_${screen}.png"
    # „home@halloween“ = Startbildschirm im Halloween-Schmuck (nur für die Vorschau).
    local name="${screen%@*}" season_args=()
    if [[ "$screen" == *@* ]]; then season_args=(-season "${screen#*@}"); fi
    local attempt
    for attempt in 1 2 3 4; do
      xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" -screenshot "$name" ${season_args[@]+"${season_args[@]}"} >/dev/null
      sleep $((10 * attempt))
      xcrun simctl io "$udid" screenshot "$file"
      # Ein leerer Startbildschirm ist eine einfarbige Fläche und als PNG winzig.
      if [ "$(stat -f%z "$file")" -gt 120000 ]; then break; fi
      echo "Bild $file sieht leer aus (Versuch $attempt) – wiederhole"
    done
    i=$((i + 1))
  done
  xcrun simctl shutdown "$udid" || true
}

shoot iPhone 'iPhone.*Pro Max'
shoot iPad 'iPad Pro 13-inch'
# Nur für die Vorschau: normales 6,1"-iPhone (Größe wie iPhone 13–17), nicht für den App Store.
if [ "${PREVIEW_SMALL_IPHONE:-}" = "1" ]; then
  SCREENS+=(home@halloween counting@halloween memory@halloween)
  shoot iPhoneKlein '^iPhone 1[3-9]$'
fi

for f in "$OUT"/*.png; do
  echo "$(basename "$f"): $(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}')$(stat -f%z "$f") Bytes"
done
