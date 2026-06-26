#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"
MANIFEST="${2:-tests/test_manifest_mvp.txt}"
GODOT_BIN="${GODOT_BIN:-godot.cmd}"
LOG_FILE="${LOG_FILE:-/tmp/wanguxingtu-mainline-tests.log}"

cd "$ROOT_DIR"
# Convert Git Bash path (e.g., /d/path) to Windows path (D:/path) for Godot
ROOT_DIR_WIN=$(echo "$ROOT_DIR" | sed 's|^/\([a-zA-Z]\)/|\1:/|')
: > "$LOG_FILE"

if [[ ! -f "$MANIFEST" ]]; then
  echo "MANIFEST_MISSING=$MANIFEST" | tee -a "$LOG_FILE"
  exit 2
fi

mapfile -t TESTS < <(grep -Ev '^[[:space:]]*($|#)' "$MANIFEST")
if [[ "${#TESTS[@]}" -eq 0 ]]; then
  echo "MANIFEST_EMPTY=$MANIFEST" | tee -a "$LOG_FILE"
  exit 2
fi

echo "RUNNING_TEST_COUNT=${#TESTS[@]}" | tee -a "$LOG_FILE"
for test_path in "${TESTS[@]}"; do
  if [[ ! -f "$test_path" ]]; then
    echo "TEST_FILE_MISSING=$test_path" | tee -a "$LOG_FILE"
    exit 3
  fi
  echo "== $test_path ==" | tee -a "$LOG_FILE"
  set +e
  "$GODOT_BIN" --headless --path "$ROOT_DIR_WIN" --script "res://$test_path" 2>&1 | tee -a "$LOG_FILE"
  status=${PIPESTATUS[0]}
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "TEST_EXIT_FAILED=$test_path status=$status" | tee -a "$LOG_FILE"
    exit "$status"
  fi
done

if grep -E 'SCRIPT ERROR|Parse Error|Compile Error' "$LOG_FILE" >/dev/null; then
  echo "GODOT_STRICT_ERROR_FOUND" | tee -a "$LOG_FILE"
  exit 4
fi

echo "MVP_MANIFEST_CLEAN" | tee -a "$LOG_FILE"
