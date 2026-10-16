#!/usr/bin/env bash
# Builds the phone playtest bundle: a Web export packed for hosts that only serve web file types
# (the engine is gzipped and the game data renamed; toto-playtest.html unpacks them in the browser).
# Usage: tools/web_playtest/package.sh <path-to-godot-4.4-binary> [output-dir]
set -euo pipefail

GODOT="$1"
OUT="${2:-build/web_playtest}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$ROOT"
mkdir -p build/web "$OUT"
"$GODOT" --headless --path . --export-release "Web" build/web/index.html

cp build/web/index.js build/web/index.audio.worklet.js build/web/index.audio.position.worklet.js "$OUT"/
gzip -9 -c build/web/index.wasm > "$OUT/engine.gz.wasm"
cp build/web/index.pck "$OUT/gamedata.pck.wasm"
cp tools/web_playtest/toto-playtest.html "$OUT"/
echo "Bundle ready in $OUT (open toto-playtest.html through any static server)."
