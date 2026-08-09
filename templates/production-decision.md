<!-- Decisión final del Orchestrator (§17). SIEMPRE se emite (aunque sea REJECTED).
     Guardar en .claude/multi-agent/reports/orchestration/DECISION-TASK-NNN-ITER-K.md -->
```yaml
task_id: TASK-NNN
iteration: K
decided_by: orchestrator
status: APPROVED | REJECTED | HUMAN_REQUIRED
acceptance_criteria:
  - { id: AC1, met: true, evidence: "<comando/resultado>" }
gates:
  qa: PASS | FAIL | N/A
  red_team: PASS | FAIL | N/A
  appsec: PASS | FAIL | N/A
blockers:
  - { id: FINDING-NNN, type: SECURITY|FUNCTIONAL|APPSEC, severity: "", source: "" }
overrides:
  - { finding: FINDING-NNN, adr: ADR-NNN, authorized_by: "" }
required_action: ""        # qué falta, o qué decisión se pide al humano
evidence_summary: |
  ""                       # resumen verificable: comandos ejecutados y su salida, diffs
change_summary: |
  ""                       # git diff --stat resumido; qué archivos y por qué
notes: |
  ""                       # recordatorio: APPROVED != desplegado. Deploy requiere autorización aparte.
```
