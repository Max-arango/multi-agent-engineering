---
description: Multi-Agent Engineering — dirige el equipo virtual de agentes (run/status/review/findings/history/pause/resume/stop)
argument-hint: "<run|status|review|findings|history|pause|resume|stop> \"<tarea>\""
---

Invoca la skill **multi-agent-engineering** y actúa como su ORCHESTRATOR siguiendo su
`SKILL.md`. Argumentos recibidos: `$ARGUMENTS`.

- El primer token de `$ARGUMENTS` es el subcomando (por defecto `run` si solo hay una tarea).
- Ejecuta el dispatch de la sección §1 de la skill: crea/lee el estado en
  `.claude/multi-agent/`, selecciona el pipeline, delega en los subagentes y aplica los gates.
- No construyas el código tú mismo: delega en Builder/Optimizer. La decisión de producción es
  del Orchestrator y no puede aprobar con blockers.

> Alias de conveniencia. Equivale a `/multi-agent-engineering $ARGUMENTS`. Copia este archivo
> a `~/.claude/commands/mae.md` (usuario) o `<proyecto>/.claude/commands/mae.md`.
