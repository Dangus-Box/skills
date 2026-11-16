#!/usr/bin/env bash
# PreToolUse(Bash): an Orca launch of a claude/codex agent must name --model from the
# coordinating skill's models.yaml and an --effort, otherwise it inherits the default
# (Opus 5.5 high). Shared by Claude and Codex. ORCA_MODEL_GUARD=0 disables.
set -u
input=$(cat)
[ "${ORCA_MODEL_GUARD:-1}" = "0" ] && exit 0
# The helper sits next to the real script; $0 may be a ~/.claude or ~/.codex symlink.
lib=$(dirname "$0")/_model-tiers.sh
[ -r "$lib" ] || lib=$(dirname "$(readlink "$0" 2>/dev/null || printf '%s' "$0")")/_model-tiers.sh
# shellcheck source=/dev/null
if [ -r "$lib" ]; then . "$lib"; else # no helper: fall back to "a model is named"
  MODEL_TIERS_FILE=models.yaml; model_allowed() { return 0; }; tiers_summary() { :; }
fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input | if type == "object" then (.command // .cmd // .input // "") else (. // "") end | if type == "array" then join(" ") else tostring end' 2>/dev/null)
printf '%s' "$cmd" | grep -Eq 'orca[[:space:]]+(orchestration[[:space:]]+worker-start|worktree[[:space:]]+create|agent[[:space:]]+launch)' || exit 0
printf '%s' "$cmd" | grep -Eq -- '--agent[= ]+["'"'"']?(claude|codex)\b' || exit 0

model=$(printf '%s' "$cmd" | grep -Eo -- '--model[= ]+["'"'"']?[^"'"'"'[:space:]]+' | head -1 |
  sed -E 's/^--model[= ]+["'"'"']?//')

problem=""
if [ -z "$model" ]; then
  problem="launches a claude/codex agent without --model, so it would inherit the default (Opus 5.5, high effort)"
elif ! model_allowed "$model"; then
  problem="uses --model '$model', which is not a tier in models.yaml"
elif ! printf '%s' "$cmd" | grep -Eq -- '--effort[= ]'; then
  problem="names --model but no --effort"
fi
[ -z "$problem" ] && exit 0

tiers=$(tiers_summary)
jq -n --arg r "Orca model guard: this $problem. Size the task with the coordinating skill (~/.agents/skills/coordinating/SKILL.md, sections 1-2) and pick a tier from $MODEL_TIERS_FILE${tiers:+ ($tiers)}. Use --agent claude for a Claude model and --agent codex for a Codex model, and pass both --model and --effort. Heavy is fine when chosen on purpose. An id outside the tiers needs an extra_allowed entry in models.yaml first." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
