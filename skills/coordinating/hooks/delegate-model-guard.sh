#!/usr/bin/env bash
# PreToolUse(mcp__t3[-_]code__delegate_task): a T3 delegation must name target.model from the
# coordinating skill's models.yaml and an effort (Claude `effort`, Codex `reasoningEffort`),
# otherwise the child inherits the parent's model. Shared by Claude and Codex.
# DELEGATE_MODEL_GUARD=0 disables.
set -u
input=$(cat)
[ "${DELEGATE_MODEL_GUARD:-1}" = "0" ] && exit 0
# The helper sits next to the real script; $0 may be a ~/.claude or ~/.codex symlink.
lib=$(dirname "$0")/_model-tiers.sh
[ -r "$lib" ] || lib=$(dirname "$(readlink "$0" 2>/dev/null || printf '%s' "$0")")/_model-tiers.sh
# shellcheck source=/dev/null
if [ -r "$lib" ]; then . "$lib"; else # no helper: fall back to "a model is named"
  MODEL_TIERS_FILE=models.yaml; model_allowed() { return 0; }; tiers_summary() { :; }
fi

model=$(printf '%s' "$input" | jq -r '.tool_input.target.model // empty' 2>/dev/null)
effort=$(printf '%s' "$input" | jq -r '
  .tool_input.target.options // {}
  | if type == "array" then (map({key: .id, value: .value}) | from_entries) else . end
  | (.effort // .reasoningEffort // empty) | tostring' 2>/dev/null)

problem=""
if [ -z "$model" ]; then
  problem="names no target.model, so the child would inherit this thread's model"
elif ! model_allowed "$model"; then
  problem="uses '$model', which is not a tier in models.yaml"
elif [ -z "$effort" ]; then
  problem="names no effort in target.options (Claude: effort; Codex: reasoningEffort)"
fi
[ -z "$problem" ] && exit 0

tiers=$(tiers_summary)
jq -n --arg r "Delegate model guard: this delegate_task $problem. Size the task with the coordinating skill (~/.agents/skills/coordinating/SKILL.md, sections 1-2) and pick a tier from $MODEL_TIERS_FILE${tiers:+ ($tiers)}. Prefer your own family; the other family is the second opinion. Set target.model and the effort in target.options. Heavy is fine when chosen on purpose. An id outside the tiers needs an extra_allowed entry in models.yaml first." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
