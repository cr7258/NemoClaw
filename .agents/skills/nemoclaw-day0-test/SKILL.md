---
name: nemoclaw-day0-test
description: Executes NemoClaw DevTest test cases end-to-end, including install, onboard, and interactive TUI steps. Captures before/after terminal screenshots via tmux at each step and generates a human-reviewable report. Knows how to install, uninstall, onboard, and configure NemoClaw even when the test case only lists prerequisites. Use when running DevTest tasks, day-0 validation, interactive terminal testing, or any test that needs auditable proof. Trigger keywords - day0 test, devtest task, run test case, tui test, interactive test, tmux test, manual test, onboard test, install test.
user_invocable: true
---

# NemoClaw Day-0 Test Execution

Execute DevTest test cases end-to-end with auditable proof. Read reference files for details on each area.

## Execution flow

```
1. Get test cases     → read references/devtest-mcp.md
2. Check environment  → read references/install-and-onboard.md
3. Execute tests      → read references/tmux-testing.md
4. Output results     → follow "Output format" below
5. File bugs          → read references/nvbug-report.md (for any FAIL)
```

## Step 1: Get test case details

User provides **task IDs** or **folder ID** + **project_id** + **username**.

Use DevTest MCP tools to fetch task details. See `references/devtest-mcp.md` for query methods and MCP setup.

Key fields to extract from each task:
- `Title` — test name
- `Fields.Test Procedure.Value` — steps to execute
- `Fields.Expected Result.Value` — what to verify

## Step 2: Check environment

Before executing, verify install and sandbox state. See `references/install-and-onboard.md` for:
- How to check if NemoClaw is installed and at the right version
- How to install / uninstall
- How to check if a sandbox exists and can be reused
- How to onboard interactively (wizard prompt sequence)
- How to destroy and re-create

**Key rules:**
- If correct version is installed, skip install
- If a usable sandbox exists (Ready, correct config), skip onboard
- Only destroy/reinstall when the test explicitly requires it
- If the test needs secrets (API keys, tokens, credentials), **ask the user** before proceeding — never guess, hardcode, or reuse from previous sessions

## Step 3: Execute tests

Use tmux to run interactive commands, capturing before/after screenshots at every action. See `references/tmux-testing.md` for:
- How to set up tmux sessions
- The capture-act-capture loop (BEFORE → ACTION → AFTER → VERDICT)
- How to handle different TUI widgets (menus, checkboxes, text input, yes/no)
- When to use non-interactive fallback instead of tmux

**Key rules:**
- Every `send-keys` MUST have a BEFORE and AFTER capture
- Wait for the prompt before acting
- Use isolated tmux socket (`-L tui-test`)
- Report path: `/private/tmp/claude/report-<TASK_ID>.txt`
- **Do NOT use `/elev on` unless the test step explicitly requires shell command execution by the agent.** Built-in agent tools (web_search, web_fetch, etc.) work without elevated mode. Only use `/elev on` when the test requires the agent to run arbitrary shell commands (e.g., curl, ls). Unnecessary privilege escalation is a test validity issue.

## Step 4: Handle wrong DevTest steps

If execution doesn't match the test procedure:

1. Read NemoClaw source code to confirm correct behavior (ask user for code path if needed)
2. Complete the test using the correct behavior
3. In the report, note: what DevTest says vs. what actually happens vs. what's correct
4. After completion, tell the user the corrected steps

## Output format

### Per-task detail report

Each task → `/private/tmp/claude/report-<TASK_ID>.txt`

```
══════════════════════════════════════════════════════════
  DEVTEST TASK <ID> — <Title>
  Test Execution Report
══════════════════════════════════════════════════════════
  Date / Platform / Method / Tester

(for each interaction step:)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  STEP N: <title>
  TIME: <timestamp>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [HH:MM:SS] BEFORE action:
  ┌──────────────────────────────────────────────────────
  │ (terminal screenshot)
  └──────────────────────────────────────────────────────

  [HH:MM:SS] ACTION: send-keys <keys> (<why>)

  [HH:MM:SS] AFTER action:
  ┌──────────────────────────────────────────────────────
  │ (terminal screenshot)
  └──────────────────────────────────────────────────────

  [HH:MM:SS] PASS/FAIL: <what was checked>

(end with:)
══════════════════════════════════════════════════════════
  TEST SUMMARY
══════════════════════════════════════════════════════════
  # | Expected Result                       | Verdict
  --+---------------------------------------+---------
  1 | ...                                   | PASS
  2 | ...                                   | FAIL
  OVERALL: PASS or FAIL
══════════════════════════════════════════════════════════
```

### Execution summary (multiple tasks)

Save to `/private/tmp/claude/summary.txt` AND output to the user:

```
══════════════════════════════════════════════════════════
  NemoClaw Day-0 Test — Execution Summary
  Date: <date>    Platform: <platform>
══════════════════════════════════════════════════════════

  Task ID | Title                                    | Result | Report
  --------+------------------------------------------+--------+------------------
  432499  | Onboard with Cloud API (default flow)    | PASS   | report-432499.txt
  432519  | SEC-1: Gateway and sandbox different UIDs | PASS   | report-432519.txt
  432520  | SEC-2: Sandbox cannot kill gateway        | FAIL   | report-432520.txt

  TOTAL: 3 tasks — 2 PASS, 1 FAIL

  DevTest Step Corrections:
  ──────────────────────────────────────────────────────
  Task 432499:
    ERROR: Step 3 says "Select NVIDIA Cloud API"
           -> actual option is "NVIDIA Endpoints"
    CORRECTED FULL STEPS (copy-paste ready):
    ────────────────────────────────────────────
    Pre-condition:
    1. NemoClaw CLI installed
    2. Docker running, no existing sandbox
    3. NVIDIA API key available

    Steps:
    1. Run: nemoclaw onboard
    2. Enter sandbox name (e.g. my-assistant)
    3. Select "NVIDIA Endpoints" as inference provider    <-- corrected
    4. Select default model (nemotron-3-super-120b-a12b)
    5. Enter NVIDIA API key when prompted
    6. Wait for gateway + sandbox creation
    7. Verify: nemoclaw my-assistant status
    ────────────────────────────────────────────

══════════════════════════════════════════════════════════
```

When DevTest steps need correction, always provide the **complete corrected steps** (not just the diff) so the user can copy-paste directly into DevTest to replace the original.

### Bug report for FAILED steps (nvbug)

For any task with FAIL verdicts, generate a bug report file. See `references/nvbug-report.md` for the file format, root cause analysis requirements, and key rules.
