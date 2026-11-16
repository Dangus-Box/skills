# Host map: Orca

Exact syntax: `orca skills get orchestration` (coordination) and the `orca-cli` skill
(worktrees, terminals, handoffs). `--help` on any command is authoritative.

| Need | Orca |
|---|---|
| Start a worker | `orca orchestration worker-start --spec-file <file> --agent claude\|codex --model <id> --effort <level>`. `--agent` = the family that runs the model (section 2). With the guard hooks installed (SETUP.md), a claude/codex launch whose `--model` is missing or not in models.yaml, or that has no `--effort`, is denied. |
| List existing | `orca worktree list`, `orca orchestration worker-list` |
| Wake | Orca types "You have N orchestration message(s)…" into the terminal. Run one `orca orchestration check --run <id> --json`, then replies + `worker-release` + `check --ack <delivery_id>` in one chained call. |
| Headless runs only | A background `orca orchestration check --wait --timeout-ms 900000`, for automations where no nudge arrives. |
| Worker asks / finishes | `orca orchestration ask`; `worker_done` with `--report-path`. Interactive prompts stall a worker. |
| Device loop (QA helper) | `orca emulator` has no wait command. One call per step: `orca emulator tap X Y && sleep 1 && orca emulator ax --json \| jq …`. Keep tap loops in a dedicated QA worker, never the coordinator. |
| New owner | `orca-cli`: new worktree or terminal with `--agent` set to your own family (`claude` or `codex`) and your own model, prompt = the section 6 pointer. |
| Remove merged worktree | `orca worktree rm` |
