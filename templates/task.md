<!-- Copiar a .claude/multi-agent/tasks/TASK-NNN.md y rellenar. Campos: reference/state-schema.md -->
```yaml
id: TASK-NNN
title: ""
description: ""
status: BACKLOG            # BACKLOG|PLANNING|READY|IN_PROGRESS|IN_REVIEW|BLOCKED|HUMAN_REQUIRED|DONE|REJECTED
priority: MEDIUM           # LOW|MEDIUM|HIGH|CRITICAL
classification:
  tipo: ""                 # bug|feature|refactor|mejora|arquitectura|seguridad
  superficie: ""           # frontend|api|datos|auth|infra|cli/lib
  riesgo: ""               # entradas-no-confiables|secretos|trust-boundary|red|migracion|irreversible|ninguno
assigned_agent: orchestrator
dependencies: []
acceptance_criteria:
  - { id: AC1, text: "", verify: "", met: false, evidence: null }
files: []
risks: []
security_required: false
red_team_required: false
appsec_required: false
pipeline: []               # p.ej. [planner, builder, optimizer, qa, appsec, red-team, orchestrator]
iteration: 0
findings: []
created: ""                # Bash: date
updated: ""
```
