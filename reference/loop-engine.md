# Reference — Loop Engine

Mecánica detallada del bucle que ejecuta el Orchestrator. SKILL.md §3 es el esqueleto; esto
es el detalle que cargas cuando el bucle se complica (findings recurrentes, estancamiento,
fallo de agente).

## Controles del bucle (de `config/policy.yml`)
```
max_iterations      : 6      # cota dura; al alcanzarla → HUMAN_REQUIRED
stall_threshold     : 2      # iteraciones sin progreso significativo → LOOP_STALLED
per_agent_timeout   : hint   # si un subagente no converge, córtalo y trátalo como AGENT_FAILURE
max_fix_attempts    : 3      # por finding; al superarlo → escalar ese finding
```
Estos son *presupuestos*, no promesas. El objetivo no es agotarlos: es terminar antes con
evidencia, o parar honestamente.

## Una iteración, paso a paso
1. **Log de apertura** en `run-log.md`: `── ITER K · TASK-NNN ──`.
2. **Selección de pipeline** (`pipeline-selection.md`). En iteraciones de mitigación, el
   pipeline se **reduce** a lo afectado por los findings abiertos (no re-corras todo si solo
   cambió una función y su gate).
3. **Ejecución de etapas** vía delegación (SKILL.md §6). Gates independientes en paralelo.
4. **Persistencia**: cada handoff → `handoffs/`; cada reporte → `reports/<área>/...-ITER-K.md`;
   cada problema → `findings/FINDING-NNN.md` (crear o transicionar, nunca sobrescribir).
5. **Orchestrator review** → evalúa `TERMINATION_OK` (SKILL.md §5).
6. **PROGRESS_SCORE** (abajo). 7. **Decisión**: APPROVED | continuar | HUMAN_REQUIRED.

## Mitigation loop (cuando hay blockers)
```
para cada finding abierto (ordenado por severidad desc):
    CLASSIFY  → tipo (funcional/seguridad/appsec), severidad, agente responsable
    ASSIGN    → Builder (o Optimizer si es de rendimiento) con el finding como scope
    FIX       → el agente aplica el cambio mínimo; registra FIX-NNN en el finding
    RETEST    → re-corre SOLO el gate que lo abrió (QA/Red Team/AppSec) → RETEST-NNN
    VERIFY    → el gate original confirma; si PASS → RESOLVED; si no → +1 intento
    si intentos > max_fix_attempts → marcar finding STUCK y escalar
```
Quien arregla no verifica (§6 separación). El historial del finding acumula
`FIX-NNN / RETEST-NNN`, no se sobrescribe.

## PROGRESS_SCORE (anti-bucle-infinito, §22)
No es un número mágico; es un juicio con señales concretas que escribes cada iteración:
```
PROGRESO(K) = Δ(acceptance_criteria cumplidos)
            + Δ(findings RESOLVED)
            − (findings reabiertos)
            − (fixes que revirtieron cambios anteriores)
```
Señales de **estancamiento** (si se dan, cuenta la iteración como "sin progreso"):
- El **mismo finding** (por firma archivo:línea:tipo) reaparece tras un supuesto FIX.
- Un fix **revierte** un cambio de una iteración previa (ping-pong).
- Dos agentes se **contradicen** sin que puedas arbitrar con evidencia.
- Ningún acceptance criterion nuevo se cumplió y ningún finding se cerró.

`sin_progreso >= stall_threshold` → `LOOP_STALLED` → escala a humano con el historial que lo
demuestra (no "no avanza", sino "FINDING-003 reabierto en iter 2 y 3 con el mismo fix").

## Failure recovery (§33 — AGENT_FAILURE)
Cuando un subagente falla, devuelve basura, o no converge:
1. **Registrar** el error en `run-log.md` y en el handoff (`status: ERROR`).
2. **¿Reintentable?** Sí si fue transitorio (herramienta falló, prompt ambiguo). Reintenta
   **cambiando algo** (prompt más acotado, menos scope) — nunca idéntico.
3. **Cambiar estrategia**: partir la tarea, dar más contexto, o usar el fallback general-purpose.
4. **Reasignar** si otro rol puede cubrirlo.
5. **Escalar** si tras lo anterior no puedes continuar. Nunca termines el pipeline en silencio
   por un fallo.

## Terminación (resumen; detalle en severity-gates.md y SKILL.md §5)
El bucle solo termina en: `APPROVED` (TERMINATION_OK), `HUMAN_REQUIRED`, o
`MAX_ITERATIONS_REACHED` (que a su vez escala a humano). Todo otro estado = seguir iterando.
