#!/usr/bin/env bash
# PostToolUse(*): nudges the main agent to write its handoff and rotate (coordinating skill, section 6).
# Fires once when context reaches ROTATE_TOKENS (default 250000; 190000 for Codex, whose window is ~258k),
# then every further 20k, and once at ROTATE_ROUNDS orchestration rounds (default 25: delegate_task calls,
# `orca orchestration check`, and `t3 thread start|send` run from a shell), then every further 10.
# Main agent only. ROTATION_NUDGE=0 disables.
set -u
input=$(cat)
[ "${ROTATION_NUDGE:-1}" = "0" ] && exit 0
[ -n "$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)" ] && exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
f="${TMPDIR:-/tmp}/rotation-nudge-${sid}"
{ read -r rounds tok_band round_band < "$f"; } 2>/dev/null || { rounds=0; tok_band=0; round_band=0; }

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r '.tool_input | if type == "object" then (.command // .cmd // .input // "") else (. // "") end | if type == "array" then join(" ") else tostring end' 2>/dev/null)
# A shell command counts when it runs one of these (not when text only mentions it).
runs_round() {
  printf '%s\n' "$cmd" | tr ';&|()`' '\n' | grep -Eq \
    "^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*((env|command|exec|nohup)[[:space:]]+)*([^[:space:]]*/)?(orca[[:space:]]+orchestration[[:space:]]+check|t3[[:space:]]+thread[[:space:]]+(start|send))([[:space:]]|$)"
}
if [[ $tool =~ ^mcp__t3[-_]code__delegate_task$ ]] || { [ "$tool" = "Bash" ] && runs_round; }; then
  rounds=$((rounds + 1))
fi

tokens=0; default_t=250000
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$tp" ] && [ -r "$tp" ]; then
  # Claude transcript: assistant usage; Codex rollout: token_count events (input_tokens includes cached)
  tokens=$(tail -n 40 "$tp" | jq -r '
    if .type == "assistant" and (.isSidechain | not) then .message.usage | select(. != null)
      | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
    elif .type == "event_msg" and .payload.type == "token_count" then .payload.info.last_token_usage.input_tokens // empty
    else empty end' 2>/dev/null | tail -n 1)
  tokens=${tokens:-0}
  tail -n 40 "$tp" | grep -q "\"type\":\"event_msg\"" && default_t=190000 # Codex rollout
fi

limit_t=${ROTATE_TOKENS:-$default_t}; limit_r=${ROTATE_ROUNDS:-25}
msg=""
if [ "$tokens" -ge "$limit_t" ]; then
  band=$(( (tokens - limit_t) / 20000 + 1 ))
  [ "$band" -gt "$tok_band" ] && { tok_band=$band; msg="context is at ~$((tokens / 1000))k tokens"; }
fi
if [ "$rounds" -ge "$limit_r" ]; then
  band=$(( (rounds - limit_r) / 10 + 1 ))
  [ "$band" -gt "$round_band" ] && { round_band=$band; msg="${msg:+$msg and }this session has run $rounds orchestration rounds"; }
fi
echo "$rounds $tok_band $round_band" > "$f"
[ -z "$msg" ] && exit 0
jq -n --arg c "Rotation nudge: $msg. Hand off or compact? Decide now by the coordinating skill's section 6 table: a coordinator, a phase end, a second compaction, a context full of wrong turns, or a different model next means hand off; one agent a few steps from done, on its first compaction, may keep going (write what a summary must not lose to a notes file first). To hand off: finish the current step, write the handoff file (path and sections: section 6), launch the successor yourself with the section 6 pointer (host map, New owner), reply with its link, and stop." \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
