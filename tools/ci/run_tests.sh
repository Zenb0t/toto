#!/usr/bin/env bash
# Runs exactly what CI runs: import, the GUT suite, then a headless boot of the game.
# Usage: tools/ci/run_tests.sh <path-to-godot-4.4.1-binary> [results-dir]
# Exits non-zero if the import fails, any test fails, or the game logs a SCRIPT ERROR while booting.
# Writes <results-dir>/junit.xml and the three logs (default results-dir: build/test-results).
# When $GITHUB_STEP_SUMMARY is set (GitHub Actions), appends a short summary there.
set -uo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <godot-binary> [results-dir]" >&2
	exit 2
fi

GODOT="$(realpath "$1")"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$(mkdir -p "${2:-$ROOT/build/test-results}" && cd "${2:-$ROOT/build/test-results}" && pwd)"
BOOT_FRAMES=900      # ~15 s of game time at 60 fps
BOOT_TIMEOUT=90      # seconds of wall time before the boot counts as hung
cd "$ROOT"

status=0
summary=()

section() { printf '\n==> %s\n' "$1"; }
fail() { echo "FAIL: $1" >&2; summary+=("❌ $1"); status=1; }
pass() { echo "OK: $1"; summary+=("✅ $1"); }

# 1. Import: registers class_name scripts and imports assets. Godot exits 0 on success; the
#    headless dummy renderer prints harmless "Parameter \"t\" is null" errors along the way.
section "Import"
if "$GODOT" --headless --path . --import >"$OUT/import.log" 2>&1; then
	pass "Import"
else
	fail "Import (exit $?, see import.log)"
	tail -50 "$OUT/import.log"
fi

# 2. Tests: GUT exits 1 when any test fails (GutRunner._handle_quit), 0 otherwise.
#    The JUnit file is a second, independent check, and catches a run that died before writing it.
section "Tests"
rm -f "$OUT/junit.xml"
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gjunit_xml_file="$OUT/junit.xml" \
	2>&1 | tee "$OUT/gut.log"
gut_exit=${PIPESTATUS[0]}
totals="$(sed -n 's/^<testsuites [^>]*failures="\([0-9]*\)" tests="\([0-9]*\)".*/\2 tests, \1 failing/p' \
	"$OUT/junit.xml" 2>/dev/null)"
if [[ $gut_exit -ne 0 ]]; then
	fail "Tests: GUT exited $gut_exit (${totals:-no results})"
elif [[ -z "$totals" ]]; then
	fail "Tests: no JUnit results written"
elif [[ "$totals" != *" 0 failing" ]]; then
	fail "Tests: $totals"
elif grep -q "SCRIPT ERROR" "$OUT/gut.log"; then
	fail "Tests: $totals, but the log has a SCRIPT ERROR"
	grep -n -A2 "SCRIPT ERROR" "$OUT/gut.log" | head -40
else
	pass "Tests: $totals"
fi

# 3. Boot smoke check: run the main scene headless for a few hundred frames and fail on any
#    GDScript runtime error (they don't crash the game, so the exit code alone wouldn't show them).
section "Boot"
timeout "$BOOT_TIMEOUT" "$GODOT" --headless --path . --quit-after "$BOOT_FRAMES" >"$OUT/boot.log" 2>&1
boot_exit=$?
if [[ $boot_exit -eq 124 ]]; then
	fail "Boot: still running after ${BOOT_TIMEOUT}s"
elif [[ $boot_exit -ne 0 ]]; then
	fail "Boot: Godot exited $boot_exit"
elif grep -q "SCRIPT ERROR" "$OUT/boot.log"; then
	fail "Boot: SCRIPT ERROR in the log"
	grep -n -A2 "SCRIPT ERROR" "$OUT/boot.log" | head -40
else
	pass "Boot: $BOOT_FRAMES frames, no script errors"
fi
[[ $boot_exit -ne 0 || $status -ne 0 ]] && tail -30 "$OUT/boot.log"

section "Summary"
printf '%s\n' "${summary[@]}"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
	{
		echo "### Toto tests"
		printf -- '- %s\n' "${summary[@]}"
		if [[ -f "$OUT/junit.xml" ]] && grep -q '<testcase [^>]*status="fail"' "$OUT/junit.xml"; then
			echo
			echo "Failing tests:"
			grep '<testcase [^>]*status="fail"' "$OUT/junit.xml" |
				sed 's/.* name="\([^"]*\)".* classname="\([^"]*\)".*/- `\2` › `\1`/' | head -50
		fi
	} >>"$GITHUB_STEP_SUMMARY"
fi
exit $status
