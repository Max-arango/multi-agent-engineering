# Reference — State & Handoff Schema

Formatos de los artefactos persistentes. Las plantillas vivas están en `templates/`; esto
documenta los campos y las invariantes. **Todo estado se persiste**: si la sesión se reinicia,
estos archivos son la fuente de verdad, no la conversación.

## Numeración de IDs
- Tareas: `TASK-001`, `TASK-002`, … (secuencial, no se reutiliza).
- Findings: `FINDING-001`, … (globales al proyecto, no por tarea, para trazar reincidencias).
- Fixes/retests dentro de un finding: `FIX-001`, `RETEST-001` (correlativos al finding).
- ADRs: `ADR-001`, …

**Asignación de IDs de finding (regla dura, ver ADR de referencia):** el **Orchestrator** es el
único que asigna `FINDING-NNN`. Los agentes de gate NO reservan IDs mirando `ls` — bajo gates en
paralelo eso es una *race condition* (dos agentes ven el mismo máximo y colisionan). Los gates
devuelven sus hallazgos en el handoff con un `local_ref` propio (`qa-1`, `rt-2`, `as-1`); al
reconciliar la wave, el Orchestrator **deduplica por `signature` (`archivo:línea:tipo`)** y asigna
el `FINDING-NNN` canónico (un mismo problema hallado por dos gates → un finding con `source`
múltiple). Ruta canónica única: `findings/` (nunca `reports/findings/`). Para tareas/ADRs, sí vale
`ls` + max (los crea solo el Orchestrator, sin concurrencia).

## Task Object (`tasks/TASK-NNN.md`)
```yaml
id: TASK-001
title: <corto>
description: <la petición del usuario, resumida sin perder intención>
status: BACKLOG | PLANNING | READY | IN_PROGRESS | IN_REVIEW | BLOCKED | HUMAN_REQUIRED | DONE | REJECTED
priority: LOW | MEDIUM | HIGH | CRITICAL
classification: {tipo, superficie, riesgo}     # ver pipeline-selection.md
assigned_agent: <rol activo ahora>
dependencies: []                               # otros TASK-NNN que deben cerrarse antes
acceptance_criteria:                           # verificables, con cómo se comprueban
  - { id: AC1, text: <...>, verify: <comando/inspección>, met: false, evidence: null }
files: []                                      # archivos que se espera tocar
risks: []
security_required: false
red_team_required: false
appsec_required: false
pipeline: [<secuencia de agentes elegida>]
iteration: 0
findings: []                                   # IDs de findings ligados a esta tarea
created: <fecha>
updated: <fecha>
```
> Fechas: usa la fecha real del entorno (Bash `date`), no una inventada.

## Handoff (`handoffs/TASK-NNN-ITER-K-<from>-<to>.md`)
Protocolo de comunicación entre agentes (§15). Nunca confíes solo en texto informal: cada
transición produce este bloque.
```yaml
task_id: TASK-NNN
iteration: K
from_agent: <rol>
to_agent: <rol>
status: <enum del contrato del emisor>
summary: <2-3 líneas>
work_completed: []
files_changed: []
tests: { command, result, evidence }     # evidence = salida real
findings: [<IDs>]
blockers: []
recommendation: <...>
next_action: <...>
```

## Estado de sesión (`state/`)
- **`current-task.md`** — puntero a la tarea activa, iteración y `run_status`
  (`RUNNING | PAUSED | STOPPED | HUMAN_REQUIRED | DONE`). Es lo primero que lees en `resume`.
- **`project-state.md`** — hechos OBSERVADOS del repo: stack, comandos reales de
  test/lint/build (citados de dónde salieron), rama, `git status`, últimos commits, y la
  política efectiva (de `policy.yml`). Se regenera si el repo cambió.
- **`agent-state.md`** — tablero: por agente, uno de `IDLE | PENDING | RUNNING | DONE | ERROR`,
  su último handoff y timestamp. Fuente del render de `/…​ status`.
- **`run-log.md`** — timeline append-only para `/… history` y observabilidad (§29).

## Finding (`findings/FINDING-NNN.md`)
Historial completo, nunca sobrescrito. Ver `templates/finding.md`. Estados:
`OPEN → ASSIGNED → FIXED → RETEST → (RESOLVED | REOPENED) → [ACCEPTED_RISK]`.
Cada transición añade una entrada con su evidencia; las anteriores se conservan.
