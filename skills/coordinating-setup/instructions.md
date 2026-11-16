## Coordinating agents
- Before spawning any helper (Orca worker, T3 delegated task or thread, native subagent), picking a model or effort for one, coordinating, working a dispatched task, or handing off: load the `coordinating` skill.

## Context hygiene
- Rotate, don't compact. Write the handoff and stop at the first of: ~{{ROTATE_TOKENS}} tokens of context, any auto-compact warning, 25 orchestration rounds (`orca orchestration check` plus `delegate_task` calls), or a phase end (plan → build → verify, a wave boundary).
- Handoff file path and sections: `coordinating` skill §6. Then launch the successor yourself (T3: new thread; Orca: new terminal; how: the skill's host map, "New owner") with the §6 pointer, reply with its link, and stop. This standing rule is my request for that new thread; ask me only if the launch fails.
