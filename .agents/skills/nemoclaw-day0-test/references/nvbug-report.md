# Bug Report (nvbug) for Failed Test Cases

## When to generate

For each task with **any FAIL verdict**, generate `/private/tmp/claude/nvbug-<TASK_ID>.txt`.

## Before writing

**Read the relevant NemoClaw source code** to identify the root cause:
- Trace from the CLI command through `bin/lib/` or `nemoclaw/src/` to find the exact code path
- For policy/preset issues, check `nemoclaw-blueprint/policies/presets/*.yaml` for binary and endpoint definitions
- For proxy enforcement issues, check the preset YAML `binaries:` field
- Include file paths and line numbers in the report

## File format

```
[Description]
[tag <version>]
<One-line summary: what command/action fails and how>

[Environment]
Device: <OS, arch, GPU>
NemoClaw: <version>
OpenShell: <version>
OpenClaw: <version>

[Steps to Reproduce]
1. <exact commands, copy-pasteable>
2. ...

[Expected Result]
<what the test case expected>

[Actual Result]
<exact terminal output showing the failure — paste from report screenshots>

[Root Cause]
<source code analysis>
- File: <path>:<line>
- Code: <relevant snippet or logic description>
- Why: <explanation of why the code produces the actual result instead of the expected result>
- Suggested fix: <brief description if obvious, otherwise "needs investigation">
```

## Key rules

- One nvbug file per failed task (not per failed step — combine all failures for the same task into one file)
- Always include **actual terminal output** from the report captures
- Always trace the source code — do not guess the root cause
- If root cause spans multiple files, list all relevant files
- After generating, tell the user: the nvbug file path and a one-line summary of each root cause found
