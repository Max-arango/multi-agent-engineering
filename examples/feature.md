# Ejemplo — Feature: "Añadir paginación al endpoint GET /users"

Muestra el pipeline de una **nueva capacidad de API** (toca superficie de datos → entran
AppSec y Red Team).

## 1. Orchestrator — clasificación
```
tipo: feature · superficie: api+datos · riesgo: entradas-no-confiables (query params)
security_required: true · appsec_required: true · red_team_required: true
pipeline: [planner, builder, optimizer, qa, appsec, red-team, orchestrator]
```
Crea `TASK-001` y `state/project-state.md` (stack Node/Express, `npm test`, rama `main`).

## 2. Planner (→ orchestrator)
```yaml
status: PLAN_READY
simple_vs_proposed: >
  SIMPLE: cursor keyset con ?limit&cursor. PROPOSED: offset/limit clásico.
  Recomiendo keyset: O(1) en páginas profundas y sin doble conteo. No es overengineering:
  el índice ya existe sobre created_at.
acceptance_criteria:
  - {id: AC1, text: "GET /users?limit=20 devuelve 20 y un next_cursor", verify: "curl + jq"}
  - {id: AC2, text: "limit>100 se capa a 100 (no DoS por page size)", verify: "test unit"}
  - {id: AC3, text: "cursor inválido → 400, no 500", verify: "test unit"}
security: "AC2 y AC3 son también requisitos de seguridad (abuse de page size / input no confiable)"
```

## 3. Builder → Optimizer → gates
- **Builder**: implementa keyset, añade 3 tests (AC1–AC3). `npm test` → evidencia real `18 passed`.
- **Optimizer**: nota que el `limit` se parsea dos veces; unifica en un validador. Justifica:
  quita duplicación, mismo comportamiento; tests siguen verdes.
- **QA**: corre suite + regresión → PASS_WITH_WARNINGS (falta test de `limit=0`). Abre
  `FINDING-001` (LOW, funcional).
- **AppSec**: `?limit` sin cota superior sería abuse; confirma que AC2 lo mitiga → PASS.
- **Red Team**: prueba `?cursor=' OR 1=1`, `?limit=99999`, cursor manipulado. El keyset usa
  parámetros parametrizados → sin inyección. `limit=99999` se capa → sin DoS. PASS, con
  `coverage_note` de lo no probado (carga concurrente).

## 4. Orchestrator — decisión
`FINDING-001` es LOW → aceptable con documentación, pero es barato: asigna FIX (Builder añade
test `limit=0` → 400). RETEST QA → RESOLVED. TERMINATION_OK.
```
status: APPROVED · gates {qa: PASS, appsec: PASS, red_team: PASS} · blockers: []
```
Recordatorio en la decisión: APPROVED ≠ desplegado.
