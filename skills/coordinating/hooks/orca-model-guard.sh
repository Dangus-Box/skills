#!/usr/bin/env bash
# PreToolUse(Bash): a shell launch of an agent must name a model from the coordinating
# skill's models.yaml and an effort, otherwise it inherits a default model:
#   Orca  worker-start / worktree create / agent launch --agent claude|codex: --model, --effort
#   T3    t3 thread start: --model, --option effort=… (Claude) or reasoningEffort=… (Codex)
# Shared by Claude and Codex. ORCA_MODEL_GUARD=0 disables (the name predates the T3 check).
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
q='["'"'"']?' # optional quote before a flag value

# runs <words-regex>: true if a shell command in $cmd starts with these words (after env
# assignments, env/command/exec/nohup, or a path), so text that only mentions them, such as
# a commit message, does not count.
runs() {
  printf '%s\n' "$cmd" | tr ';&|()`' '\n' | grep -Eq \
    "^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*((env|command|exec|nohup)[[:space:]]+)*([^[:space:]]*/)?$1([[:space:]]|$)"
}

if runs 'orca[[:space:]]+(orchestration[[:space:]]+worker-start|worktree[[:space:]]+create|agent[[:space:]]+launch)'; then
  printf '%s' "$cmd" | grep -Eq -- "--agent[= ]+${q}(claude|codex)\b" || exit 0
  host=Orca default="the default (Opus 5.5, high effort)" effort_re='--effort[= ]'
  effort_hint="--effort <level>" family_hint="--agent claude for a Claude model, --agent codex for a Codex model"
elif runs 't3[[:space:]]+thread[[:space:]]+start'; then
  host=T3 default="the project's default model" effort_re="--option[= ]+${q}(effort|reasoningEffort)="
  effort_hint="--option effort=<level> (Claude) or --option reasoningEffort=<level> (Codex)"
  family_hint="--provider <instance id> for the model's family (orchestrator_capabilities lists them)"
else
  exit 0
fi

model=$(printf '%s' "$cmd" | grep -Eo -- "--model[= ]+${q}[^\"'[:space:]]+" | head -1 |
  sed -E "s/^--model[= ]+[\"']?//")

problem=""
if [ -z "$model" ]; then
  problem="launches an agent without --model, so it would get $default"
elif ! model_allowed "$model"; then
  problem="uses --model '$model', which is not a tier in models.yaml"
elif ! printf '%s' "$cmd" | grep -Eq -- "$effort_re"; then
  problem="names --model but no effort ($effort_hint)"
fi
[ -z "$problem" ] && exit 0

tiers=$(tiers_summary)
jq -n --arg r "$host model guard: this $problem. Size the task with the coordinating skill (~/.agents/skills/coordinating/SKILL.md, sections 1-2) and pick a tier from $MODEL_TIERS_FILE${tiers:+ ($tiers)}. Use $family_hint, and pass --model plus $effort_hint. Heavy is fine when chosen on purpose. An id outside the tiers needs an extra_allowed entry in models.yaml first." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
