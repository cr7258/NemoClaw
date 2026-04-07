#!/usr/bin/env bash
# ── tmux-test-lib.sh ── Generic TUI test helper library ──────────
#
# Source this file to get reusable functions for tmux-based TUI testing.
# Works across any interactive CLI, not just NemoClaw.
#
# Usage:
#   source tmux-test-lib.sh
#   test_init "432499" "Onboard with Cloud API" "nemoclaw onboard"
#   test_step "1/8" "Preflight checks"
#   test_wait "Choose" 300
#   test_send "Select default provider" Enter
#   test_assert "NVIDIA Endpoints" "Provider list contains NVIDIA"
#   test_finish

TMUX_SOCKET="tui-test"
TMUX_SESSION="test"
REPORT=""
_STEP_NUM=0
_PASS=0
_FAIL=0
_SKIP=0

# ── init ──────────────────────────────────────────────────────────
# Creates tmux session + report file.
# Usage: test_init <task_id> <title> <command>
test_init() {
  local task_id="$1" title="$2" cmd="$3"
  REPORT="/private/tmp/claude/report-${task_id}.txt"

  cat > "$REPORT" <<EOF
══════════════════════════════════════════════════════════════════
  DEVTEST TASK ${task_id} — ${title}
  Test Execution Report
══════════════════════════════════════════════════════════════════
  Date:      $(date '+%Y-%m-%d')
  Platform:  $(uname -s) $(uname -m)
  Method:    tmux interactive (step-by-step capture)
  Tester:    Claude Code (automated via tmux send-keys)
══════════════════════════════════════════════════════════════════

EOF

  tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
  tmux -L "$TMUX_SOCKET" new-session -d -s "$TMUX_SESSION" -x 120 -y 40
  tmux -L "$TMUX_SOCKET" send-keys -t "$TMUX_SESSION" "$cmd" Enter
  _log "SESSION: tmux -L $TMUX_SOCKET (command: $cmd)"
  _log ""
}

# ── internal helpers ──────────────────────────────────────────────
_log() { printf '%s\n' "$*" >> "$REPORT"; }
_ts()  { date '+%H:%M:%S'; }
_capture_raw() {
  tmux -L "$TMUX_SOCKET" capture-pane -t "$TMUX_SESSION" -p 2>/dev/null \
    || echo "(session ended)"
}

# ── capture current screen to report ─────────────────────────────
# Usage: test_capture [label]
test_capture() {
  local label="${1:-SCREEN}"
  _log "  [$(_ts)] ${label}:"
  _log "  ┌──────────────────────────────────────────────────────────────"
  _capture_raw | while IFS= read -r line; do _log "  │ $line"; done
  _log "  └──────────────────────────────────────────────────────────────"
  _log ""
}

# ── wait for pattern on screen ────────────────────────────────────
# Usage: test_wait <grep_pattern> [timeout_sec]
# Returns 0 on match, 1 on timeout.
test_wait() {
  local pattern="$1" timeout="${2:-300}" elapsed=0
  while ! _capture_raw | grep -qE "$pattern" 2>/dev/null; do
    sleep 5
    elapsed=$((elapsed + 5))
    if [ "$elapsed" -ge "$timeout" ]; then
      _log "  [$(_ts)] TIMEOUT (${timeout}s) waiting for: ${pattern}"
      return 1
    fi
  done
  return 0
}

# ── send keys with before/after capture ───────────────────────────
# Usage: test_send <description> <keys...>
# Example:
#   test_send "Select default provider" Enter
#   test_send "Type sandbox name" "my-assistant" Enter
#   test_send "Toggle checkbox item" Down Down Space Enter
test_send() {
  local desc="$1"; shift
  local delay="${SEND_DELAY:-3}"

  _STEP_NUM=$((_STEP_NUM + 1))
  _log "── ACTION #${_STEP_NUM}: ${desc} ──────────────────────────"
  _log ""

  test_capture "BEFORE"

  local keys_str="$*"
  _log "  [$(_ts)] SEND: ${keys_str}"
  for key in "$@"; do
    tmux -L "$TMUX_SOCKET" send-keys -t "$TMUX_SESSION" "$key"
  done

  sleep "$delay"

  test_capture "AFTER"
}

# ── assert screen contains pattern ────────────────────────────────
# Usage: test_assert <grep_pattern> <description>
test_assert() {
  local pattern="$1" desc="$2"
  if _capture_raw | grep -qE "$pattern" 2>/dev/null; then
    _log "  [$(_ts)] ✅ PASS: ${desc}"
    _PASS=$((_PASS + 1))
  else
    _log "  [$(_ts)] ❌ FAIL: ${desc}"
    _FAIL=$((_FAIL + 1))
  fi
  _log ""
}

# ── assert screen does NOT contain pattern ────────────────────────
# Usage: test_assert_not <grep_pattern> <description>
test_assert_not() {
  local pattern="$1" desc="$2"
  if _capture_raw | grep -qE "$pattern" 2>/dev/null; then
    _log "  [$(_ts)] ❌ FAIL: ${desc}"
    _FAIL=$((_FAIL + 1))
  else
    _log "  [$(_ts)] ✅ PASS: ${desc}"
    _PASS=$((_PASS + 1))
  fi
  _log ""
}

# ── log a step header ─────────────────────────────────────────────
# Usage: test_step "3/8" "Provider selection"
test_step() {
  local num="$1" title="$2"
  _log ""
  _log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  _log "  STEP ${num}: ${title}"
  _log "  TIME: $(date '+%Y-%m-%d %H:%M:%S')"
  _log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  _log ""
}

# ── skip a step ───────────────────────────────────────────────────
test_skip() {
  local desc="$1"
  _log "  [$(_ts)] ⏭️ SKIP: ${desc}"
  _SKIP=$((_SKIP + 1))
  _log ""
}

# ── note (informational, no verdict) ─────────────────────────────
test_note() {
  _log "  [$(_ts)] NOTE: $*"
  _log ""
}

# ── run an external command and log output ────────────────────────
# Usage: test_run_cmd "nemoclaw my-assistant status"
test_run_cmd() {
  local cmd="$1"
  _log "  [$(_ts)] Running: ${cmd}"
  _log "  ┌──────────────────────────────────────────────────────────────"
  eval "$cmd" 2>&1 | while IFS= read -r line; do _log "  │ $line"; done
  _log "  └──────────────────────────────────────────────────────────────"
  _log ""
}

# ── finish: summary + cleanup ─────────────────────────────────────
test_finish() {
  _log ""
  _log "══════════════════════════════════════════════════════════════════"
  _log "  TEST SUMMARY"
  _log "  Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  _log "══════════════════════════════════════════════════════════════════"
  _log ""
  _log "  ✅ PASS: ${_PASS}"
  _log "  ❌ FAIL: ${_FAIL}"
  _log "  ⏭️ SKIP: ${_SKIP}"
  _log "  TOTAL:  $((_PASS + _FAIL + _SKIP))"
  _log ""

  if [ "$_FAIL" -eq 0 ]; then
    _log "  OVERALL: ✅ ALL CHECKS PASSED"
  else
    _log "  OVERALL: ❌ ${_FAIL} CHECK(S) FAILED"
  fi
  _log ""
  _log "══════════════════════════════════════════════════════════════════"

  tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true

  echo ""
  echo "Report: $REPORT"
  echo "Result: PASS=${_PASS} FAIL=${_FAIL} SKIP=${_SKIP}"
}
