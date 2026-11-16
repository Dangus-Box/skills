# skills

Agent skills for Claude Code, Codex and other agents that read `~/.agents/skills`.

```sh
npx skills add dancorreia-swe/skills -g -y   # install all, globally
npx skills update -g -y                      # update
```

| Skill | What it is for |
|---|---|
| `coordinating` | Running work across agents in Orca or T3 Code: sizing a task, picking a Claude or Codex model and effort per tier, briefs, waiting without polling, handoffs, decisions. Setup, optional guard hooks and suggested global instructions: [SETUP.md](skills/coordinating/SETUP.md). |
