# skills

My set of skills for doing agentic work well: getting real results from coding agents
while staying flexible about the ADE (agentic development environment, such as
[Orca](https://github.com/stablyai/orca) or [T3 Code](https://github.com/pingdotgg/t3code)),
spending tokens carefully, and mixing providers (Claude and Codex) in the same run.

## Principles

- **Proficiency.** Size each task first, then give it the right crew: one agent for small work;
  a planner, builders, QA and a reviewer for large or risky work. Every brief is
  self-contained, because a helper sees none of your history.
- **Flexible about the ADE.** The skill decides what to spawn, on which model and with what
  brief. A small host map per ADE holds the commands. Orca and T3 Code are covered, and
  another host only needs a new map.
- **Token efficiency.** Smaller models by default and step up only on evidence. The
  coordinator waits for a wake-up instead of polling, keeps diffs and logs out of its own
  context, and hands off to a fresh session instead of compacting.
- **Multi-provider.** Every tier has a Claude and a Codex model in one shared
  `models.yaml`. The other family is the second opinion. Optional hooks deny any launch that
  names no model, an unlisted model, or no effort.

## Install

Works with Claude Code, Codex and other agents that read `~/.agents/skills`.

```sh
npx skills add dancorreia-swe/skills -g -y   # install all, globally
npx skills update -g -y                      # update
```

Then ask your agent to **"set up the coordinating skill"**. The `coordinating-setup` skill
picks your models, installs the guard hooks for Claude Code and Codex, and adds the
global instructions, showing every change first. Manual route:
[SETUP.md](skills/coordinating/SETUP.md).

## Skills

| Skill | What it is for |
|---|---|
| [`coordinating-setup`](skills/coordinating-setup/SKILL.md) | Start here. Installs, checks or removes `coordinating`'s hooks and global instructions for Claude Code and Codex, with a dry run and backups. |
| [`coordinating`](skills/coordinating/SKILL.md) | Running work across agents in Orca or T3 Code: sizing a task, picking a Claude or Codex model and effort per tier, briefing helpers, waiting without polling, handoffs, decisions, and landing PRs. |
