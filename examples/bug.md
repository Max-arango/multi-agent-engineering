# Ejemplo — Bug de frontend: "El filtro de rango de fechas excluye el último día"

Pipeline **corto** (bug de UI sin superficie de seguridad): no se convocan Red Team ni AppSec.

## 1. Orchestrator — clasificación
```
tipo: bug · superficie: frontend · riesgo: ninguno
security_required: false · red_team_required: false · appsec_required: false
pipeline: [planner, builder, optimizer, qa, orchestrator]
```

## 2. Planner
```yaml
status: PLAN_READY
what: "El comparador usa `<` en lugar de `<=` para el límite superior del rango."
simple_vs_proposed: "SIMPLE gana: cambiar el operador + un test que fije el borde. Nada más."
acceptance_criteria:
  - {id: AC1, text: "Un ítem con fecha == fin-del-rango aparece en el resultado", verify: "test unit del filtro"}
  - {id: AC2, text: "No hay regresión en el borde inferior", verify: "suite existente"}
proportionality: PROPORTIONATE
```

## 3. Builder → Optimizer → QA
- **Builder** aplica el **mínimo cambio** (`<` → `<=`) y añade un test que **falla antes** del
  fix (prueba de que el test puede fallar) y pasa después. Evidencia: `git diff` de 1 línea +
  `npm test -- dateFilter` → `4 passed`.
- **Optimizer**: `NO_CHANGES_JUSTIFIED` — no hay nada que mejorar; no inventa refactors.
- **QA**: corre la suite completa (regresión AC2) + el nuevo test (AC1) → PASSED. Evidencia real.

## 4. Orchestrator — decisión
Sin findings, ambos AC verificados con evidencia, QA PASS, gates de seguridad no aplicaban.
```
status: APPROVED · gates {qa: PASS, red_team: N/A, appsec: N/A}
change_summary: "1 archivo, 1 línea de fix + 1 test."
```
Lección: el loop inteligente **no** convoca agentes que no aportan garantía a esta clase de tarea.
