<!-- Artefacto de comunicación entre agentes (§15). Guardar en
     .claude/multi-agent/handoffs/TASK-NNN-ITER-K-<from>-<to>.md -->
```yaml
task_id: TASK-NNN
iteration: 0
from_agent: ""
to_agent: ""
status: ""                 # enum del contrato del agente emisor
summary: ""
work_completed: []
files_changed: []          # "ruta: qué cambió y por qué"
tests:
  command: ""
  result: ""               # PASS|FAIL|N/A
  evidence: |              # SALIDA REAL del comando, recortada. Nunca inventada.
    ""
findings: []               # IDs FINDING-NNN
blockers: []
recommendation: ""
next_action: ""
```
