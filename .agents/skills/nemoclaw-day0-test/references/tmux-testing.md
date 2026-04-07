# tmux TUI Testing Method

## Architecture

```
tmux session (isolated socket: tui-test)
  |-- runs the CLI command under test
        <-> send-keys / capture-pane
Claude Code (this agent)
  |-- reads screen -> decides action -> sends keys -> captures result -> writes report
```

- `tmux capture-pane -p` outputs the rendered screen as clean text (no ANSI codes) — equivalent to a terminal screenshot
- `tmux send-keys` injects keystrokes including arrow keys, Space, Enter, Ctrl sequences — handles raw-mode TUI widgets that `expect` cannot

## Initialize tmux session

Always start with a shell, then send the command — prevents the session from dying if the command exits:

```bash
tmux -L tui-test kill-server 2>/dev/null || true
tmux -L tui-test new-session -d -s test -x 120 -y 40
tmux -L tui-test send-keys -t test '<command>' Enter
```

- `-L tui-test`: isolated socket (won't touch user's tmux)
- `-x 120 -y 40`: wide enough for full TUI output

## The capture-act-capture loop

For **every** interactive action, follow this exact sequence:

### 1. Wait for prompt

```bash
while ! tmux -L tui-test capture-pane -t test -p | grep -qE '<pattern>'; do
  sleep 5
done
```

### 2. Capture BEFORE

```bash
tmux -L tui-test capture-pane -t test -p  # -> append to report as "BEFORE action"
```

### 3. Log action and send keys

```bash
# Log what we're doing and why
tmux -L tui-test send-keys -t test Enter
sleep 2-5  # wait for TUI to respond
```

### 4. Capture AFTER

```bash
tmux -L tui-test capture-pane -t test -p  # -> append to report as "AFTER action"
```

### 5. Assert and record verdict

```bash
tmux -L tui-test capture-pane -t test -p | grep -q '<expected>'
# -> log PASS or FAIL
```

## Handle different TUI widget types

| Widget | Example prompt | How to interact |
|--------|---------------|-----------------|
| Text input | `Sandbox name:` | `send-keys 'my-assistant' Enter` |
| Number menu | `Choose [1]:` | `send-keys Enter` (default) or `send-keys '3' Enter` |
| Yes/No | `[y/N]:` or `[Y/n]:` | `send-keys Enter` (default) or `send-keys 'y' Enter` |
| Password/Key | `API Key:` | `send-keys '<value>' Enter` |
| Checkbox TUI | `Space Enter` | `send-keys Down Down Space Enter` |
| Toggle menu | `Press 1-3 to toggle` | `send-keys '1' Enter` |

## Non-interactive fallback

When the test doesn't require interactive input (e.g., Docker commands, file permission checks), skip tmux and run directly:

```bash
output=$(docker run --rm --entrypoint "" $IMAGE bash -c "id -u gateway; id -u sandbox" 2>&1)

if [ "$(echo "$output" | head -1)" != "$(echo "$output" | tail -1)" ]; then
  echo "PASS: UIDs are different"
fi
```

Use tmux only when the test requires interactive input. Many security tests (SEC-1 through SEC-10) are non-interactive.

## Cleanup

```bash
tmux -L tui-test kill-server 2>/dev/null || true
```

## Golden rules

1. **Every send-keys MUST have a BEFORE and AFTER capture** — no exceptions
2. **Wait for the prompt before acting** — poll with `capture-pane | grep`
3. **Use isolated tmux socket** (`-L tui-test`) — never touch user's tmux
4. **Start tmux with a shell** then send the command — prevents session death
5. **Sleep after send-keys** — 2-5s for prompts, longer for builds
6. **Log the ACTION description** — what key and why, for reviewer clarity
7. **Assert against screen content** — use `capture-pane | grep`, not assumptions
8. **Report path**: `/private/tmp/claude/report-<TASK_ID>.txt`
9. **Clean lock files** before re-running (`~/.nemoclaw/onboard.lock`)
10. **Gateway startup takes 2-3 minutes** on first run — set wait timeouts accordingly

## Helper library

A reusable bash function library is available at `references/tmux-test-lib.sh` with functions:
- `test_init` / `test_finish` — session + report lifecycle
- `test_send` — auto before/after capture
- `test_wait` — wait for pattern
- `test_assert` / `test_assert_not` — assertions
- `test_step` / `test_note` / `test_skip` — report structure
- `test_run_cmd` — run external commands and log output
