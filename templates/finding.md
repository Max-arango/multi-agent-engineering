<!-- Historial de un hallazgo (§18). NUNCA se sobrescribe: cada transición AÑADE una entrada.
     Guardar en .claude/multi-agent/findings/FINDING-NNN.md -->
```yaml
id: FINDING-NNN
task_id: TASK-NNN
source: ""                 # qa|red-team|appsec|optimizer
type: ""                   # FUNCTIONAL|SECURITY|APPSEC|PERFORMANCE
severity: ""               # CRITICAL|HIGH|MEDIUM|LOW|INFO
confidence: ""             # CONFIRMED|HIGH|MEDIUM|LOW
status: OPEN               # OPEN|ASSIGNED|FIXED|RETEST|RESOLVED|REOPENED|ACCEPTED_RISK|STUCK
signature: ""              # archivo:línea:tipo — para detectar reincidencia (anti-loop)
affected_component: ""
description: ""
reproduction: ""           # pasos controlados y no destructivos
impact: ""
evidence: |
  ""                       # salida real / cita de código
recommended_fix: ""
verification_method: ""
```

## Historial (append-only)
```
[iter K] OPEN      — detectado por <source>. Evidencia: <...>
[iter K] ASSIGNED  — a <agente> (FIX-001)
[iter K] FIXED     — FIX-001: <qué cambió>. Diff: <ref>
[iter K] RETEST    — RETEST-001 por <gate original>. Resultado: <PASS|FAIL> · evidencia: <...>
[iter K] RESOLVED  — verificado por <gate>. (o REOPENED si volvió a fallar)
```
