# DevTest MCP — Query Methods

## MCP setup

The DevTest MCP server must be configured in `~/.claude.json`:

```json
{
  "mcpServers": {
    "devtest": {
      "type": "sse",
      "url": "http://cqax.nvidia.com:5050/mcp/devtest/sse"
    }
  }
}
```

If `mcp__devtest__*` tools are not available, ask the user to add this config.

## Query by task ID (most common)

```
mcp__devtest__fetch_task_details(project_id=<project_id>, task_ids=[<id1>, <id2>, ...])
```

Key fields in the response:
- `Title` — test case name
- `Fields.Task State.Value` — Gated, Fail, Pass, etc.
- `Fields.Test Procedure.Value` — test steps to execute
- `Fields.Expected Result.Value` — what to verify
- `Fields.Bugs_CSV.Value` — linked bug IDs
- `Fields.Template Priority.Value` — P0, P1, etc.
- `TaskOwner.LoginId` — who owns the task

## Query by folder

1. Get folder ID (if user gives a path):
   ```
   mcp__devtest__get_folder_id(folder_path="\\Nvidia Root Folder\\...")
   ```
   - Path must start with `\Nvidia Root Folder\`, not `\DevTest\`
   - Returns `-1` if not found — ask the user for the numeric folder ID instead

2. Get tasks in that folder:
   ```
   mcp__devtest__fetch_user_tasks(username=<username>, project_id=<project_id>, tp_folder_id=<folder_id>)
   ```
   - Returns a list of task IDs — then use `fetch_task_details` to get full info

## Other useful queries

- List user's projects: `mcp__devtest__fetch_user_projects(username=<username>)`
- Task test history: `mcp__devtest__fetch_test_history(project_id=<id>, template_id=<id>)`
- Find similar tests: `mcp__devtest__find_similar_test(template_id=<id>)`

## What the user must provide

- **project_id** — the DevTest work project ID (ask if not known)
- **folder_id** or **task_ids** — where to find the test cases
- **username** — DevTest login ID (needed for `fetch_user_tasks`)
