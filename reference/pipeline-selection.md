# Reference — Pipeline Selection (Loop inteligente)

El Orchestrator **no corre todos los agentes siempre**. Clasifica la tarea y elige el pipeline
mínimo que da garantía suficiente. Correr gates de sobra quema tiempo; saltarse los que
aplican rompe una garantía. Este documento es la guía; el juicio final es tuyo, con
justificación escrita en `reports/orchestration/`.

## Paso 1 — Clasificar la tarea
Etiqueta la tarea con uno o varios de estos ejes:
- **Tipo:** bug · feature · refactor · mejora · cambio de arquitectura · cambio de seguridad.
- **Superficie:** frontend · backend/API · datos/persistencia · auth/authz · infra/config · CLI/lib.
- **Riesgo:** toca entradas no confiables · maneja secretos/credenciales · cruza trust
  boundaries · expone red · migración de datos · irreversible.

## Paso 2 — Fijar los flags de seguridad (Planner propone, tú confirmas)
```
security_required  = superficie ∈ {API, auth, datos, infra} OR riesgo toca entradas no confiables
red_team_required  = maneja entradas no confiables / auth / API expuesta / secretos
appsec_required    = cambio de auth, cripto, dependencias, config de seguridad, o arquitectura
```
Ante la duda en un cambio con superficie de seguridad: **incluye el gate**. La ausencia de
prueba no es prueba de ausencia.

## Paso 3 — Elegir el pipeline
| Clase de tarea | Pipeline |
|---|---|
| Bug de frontend / UI | Planner → Builder → Optimizer → QA → Orchestrator |
| Refactor interno sin cambio de comportamiento | Planner → Builder → Optimizer → QA → Orchestrator |
| Nueva API / endpoint backend | Planner → Builder → Optimizer → QA → **AppSec** → **Red Team** → Orchestrator |
| Cambio crítico de auth/authz | Planner → Builder → Optimizer → **AppSec** → **Red Team** → QA → Orchestrator |
| Manejo de datos sensibles / secretos | Planner → Builder → Optimizer → **AppSec** → **Red Team** → QA → Orchestrator |
| Nueva feature de producto/UX | **Creative** → Planner → Orchestrator(autoriza) → Builder → QA → Orchestrator |
| Cambio de arquitectura | Planner → (ADR) → Builder → Optimizer → QA → **AppSec** → (**Red Team** si toca superficie) → Orchestrator |
| Security issue / vulnerabilidad reportada | Planner → **Red Team**(reproduce) → Builder(fix) → **Red Team**(retest) → **AppSec** → QA → Orchestrator |

Notas de orden:
- En cambios de **seguridad**, AppSec suele ir **antes** que Red Team (primero "¿está bien
  construido?", luego "¿puedo romperlo?"), y QA valida que además sigue funcionando.
- **Creative** solo entra en generación de valor/UX y **nunca** ordena implementación:
  su salida va a Planner.
- En **security issue**, Red Team primero **reproduce** la vulnerabilidad (evidencia del
  problema) y luego, tras el fix, **re-testea** (evidencia de la solución).

## Paso 4 — Reducción en iteraciones de mitigación
Cuando vuelves a iterar por un finding, **no re-corras el pipeline completo**: corre solo el
Builder/Optimizer para el fix y **el gate que abrió el finding** para el retest. Re-corre un
gate adicional solo si el fix pudo afectar su dominio (p. ej. un fix de authz puede reabrir
QA funcional → re-corre QA también). Documenta por qué incluiste/excluiste cada gate.
