# Multi-Agent Setup (Mishi)

- Workspace: `/Users/yuanyuan/Documents/workspace/mishi`
- Agents: `pm-agent`, `arch-agent`, `frontend-agent`, `backend-agent`, `app-agent`, `coordinator-agent`
- Shared collaboration root: `collab/`

Prompt files:
- `docs/agents/prompts/pm-agent.prompt.md`
- `docs/agents/prompts/arch-agent.prompt.md`
- `docs/agents/prompts/frontend-agent.prompt.md`
- `docs/agents/prompts/backend-agent.prompt.md`
- `docs/agents/prompts/app-agent.prompt.md`
- `docs/agents/prompts/coordinator-agent.prompt.md`

Governance files (must read before execution):
- `docs/agents/shared-workspace.md`
- `collab/handoff/dependency-queue.md`
- `collab/handoff/daily-sync.md`

Scheduling policy:
- Coordinator is the only writer of `collab/handoff/*`
- Other roles submit `Scheduling Request` in their domain docs

## Auto-Collaboration Runtime

Runtime scripts:
- `devops/agents/mishi_multi_agent_orchestrator.sh` (single cycle)
- `devops/agents/start_multi_agent_loop.sh` (background loop)
- `devops/agents/stop_multi_agent_loop.sh`
- `devops/agents/status_multi_agent_loop.sh`

Default cycle order:
1. `coordinator-agent` (plan and assign)
2. `pm-agent`
3. `arch-agent`
4. `backend-agent`
5. `frontend-agent`
6. `app-agent`
7. `coordinator-agent` (merge updates and move queue states)

### Run once

```bash
cd /Users/yuanyuan/Documents/workspace/mishi
./devops/agents/mishi_multi_agent_orchestrator.sh
```

### Run continuously (every 30 minutes by default)

```bash
cd /Users/yuanyuan/Documents/workspace/mishi
./devops/agents/start_multi_agent_loop.sh
./devops/agents/status_multi_agent_loop.sh
```

Stop:

```bash
cd /Users/yuanyuan/Documents/workspace/mishi
./devops/agents/stop_multi_agent_loop.sh
```

### Tuning

- `INTERVAL_SECONDS` controls loop interval (default `1800`)
- `TIMEOUT_SECONDS` controls each agent turn timeout (default `3600`)
- `OPENCLAW_MODE` defaults to `--local`; set empty if you prefer gateway mode
- `OPENCLAW_BIN` defaults to `openclaw`
- `DRY_RUN=1` only validates orchestration flow without calling models

Example:

```bash
cd /Users/yuanyuan/Documents/workspace/mishi
INTERVAL_SECONDS=900 TIMEOUT_SECONDS=1200 ./devops/agents/start_multi_agent_loop.sh
```

Logs:
- `collab/handoff/runtime/loop.log`
- `collab/handoff/runtime/orchestrator.log`
