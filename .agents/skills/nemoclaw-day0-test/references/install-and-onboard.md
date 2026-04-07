# NemoClaw Install and Onboard Reference

## Hardware requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 vCPU | 4+ vCPU |
| RAM | 8 GB | 16 GB |
| Disk | 20 GB free | 40 GB free |

The sandbox image is ~2.4 GB compressed. Systems with <8 GB RAM may need 8 GB swap.

## Software requirements

- Node.js 22.16+, npm 10+
- Container runtime: Docker (Linux), Colima/Docker Desktop (macOS), Docker Desktop+WSL (Windows)
- `tmux` — needed for TUI testing (`brew install tmux` on macOS)

## Check before install — skip if version matches

```bash
nemoclaw --version 2>/dev/null
```

If the output matches the version required by the test case (e.g., `v0.0.7`), **skip installation**. Only install/reinstall when:
- NemoClaw is not installed
- The installed version does not match the test target version
- The test case explicitly requires a fresh install or uninstall/reinstall cycle

## Install

Reference docs: https://docs.nvidia.com/nemoclaw/latest/get-started/quickstart.html

```bash
curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
```

Onboard is always interactive — use tmux to operate it (see `references/tmux-testing.md`).

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/NVIDIA/NemoClaw/refs/heads/main/uninstall.sh | bash
```

Flags: `--yes` (skip confirm), `--keep-openshell`, `--delete-models`

Only uninstall when the test case requires it or you need a clean-slate reinstall.

## Check before onboard — skip if sandbox exists

```bash
nemoclaw list 2>/dev/null
nemoclaw <name> status 2>/dev/null
```

If a sandbox exists in `Ready` state with correct model/provider, **skip onboard**. Only re-onboard when:
- No sandbox exists (`No sandboxes registered`)
- The test case explicitly requires a fresh onboard
- The existing sandbox has wrong model/provider/config
- The test is specifically testing the onboard flow itself

## Onboard wizard prompt sequence

The `nemoclaw onboard` wizard follows this sequence:

```
[1/8] Preflight checks     — Docker, runtime, openshell, ports, GPU
[2/8] Gateway startup       — pulls/starts OpenShell gateway image (~2-3 min first time)
[3/8] Inference config      — provider selection -> API key -> model selection
[4/8] Inference provider    — creates gateway route (automatic)
[5/8] Messaging channels    — Telegram/Discord/Slack token entry (optional)
[6/8] Sandbox creation      — name input -> Docker image build -> upload (~3-5 min)
[7/8] OpenClaw setup        — launches OpenClaw inside sandbox (automatic)
[8/8] Policy presets        — TUI checkbox selector for egress policies
```

Interactive prompts in order:
1. **Provider selection** — `Choose [1]:` with options: NVIDIA Endpoints, OpenAI, Other OpenAI-compatible, Anthropic, Other Anthropic-compatible, Google Gemini, Local Ollama
2. **API key** — `NVIDIA API Key:` (only if NVIDIA Endpoints selected)
3. **Model selection** — `Choose model [1]:` with cloud model list
4. **Brave Web Search** — `Enable Brave Web Search? [y/N]:`
5. **Messaging channels** — `Press 1-3 to toggle, Enter when done:`
6. **Sandbox name** — `Sandbox name [...] [my-assistant]:`
7. **Policy presets** — TUI checkbox with arrow keys/space/enter

## Destroy and re-create (only when needed)

```bash
# Destroy existing sandbox
echo "y" | nemoclaw <name> destroy

# Clean lock files and credentials for fresh start
rm -f ~/.nemoclaw/onboard.lock
rm -f ~/.nemoclaw/credentials.json

# Then re-run onboard
nemoclaw onboard
```

## Common CLI commands

```bash
nemoclaw <name> status       # show sandbox status
nemoclaw <name> connect      # shell into sandbox
nemoclaw <name> logs --follow # tail sandbox logs
nemoclaw <name> policy-add   # add egress policy preset
nemoclaw <name> policy-list  # list active policies
nemoclaw <name> destroy      # destroy sandbox
nemoclaw list                # list all sandboxes
nemoclaw onboard             # create new sandbox
```
