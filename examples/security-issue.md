# Ejemplo — Security issue: "IDOR reportado en GET /invoices/:id"

Muestra el pipeline dirigido por seguridad y el **mitigation loop con historial de findings**.

## 1. Orchestrator — clasificación
```
tipo: seguridad · superficie: api+auth · riesgo: authz/trust-boundary
pipeline: [planner, red-team(reproduce), builder(fix), red-team(retest), appsec, qa, orchestrator]
```
En un security issue, Red Team **primero reproduce** (evidencia del problema), luego re-testea.

## 2. Red Team — reproducción (iter 1)
```yaml
status: FAIL
findings:
  - id: FINDING-001
    finding: "IDOR: cualquier usuario autenticado lee facturas de otros por id secuencial"
    severity: HIGH · confidence: CONFIRMED
    affected_component: "routes/invoices.js:GET /invoices/:id"
    reproduction: "Login como user A (id 12); GET /invoices/8100 (de user B) → 200 con datos de B"
    evidence: |
      $ curl -H "Authorization: Bearer <A>" /invoices/8100 -o - -w "%{http_code}"
      200  {"id":8100,"customer_id":77,"total":...}   # 77 != A
    impact: "Fuga de datos financieros entre tenants"
    recommended_fix: "Filtrar por owner: WHERE id=:id AND customer_id=:session_customer"
    verification_method: "Repetir la prueba: debe devolver 404"
```
Red Team marca `PRODUCTION_BLOCKED` y fuerza atención (HIGH). Orchestrator: `status REJECTED`,
crea `findings/FINDING-001.md`.

## 3. Mitigation loop
```
FINDING-001  OPEN → ASSIGNED(builder, FIX-001) → FIXED → RETEST-001(red-team) → RESOLVED
```
- **Builder (FIX-001)**: añade el predicado de ownership (cambio mínimo, 2 líneas) + test que
  simula acceso cruzado y espera 404. `npm test` → `+1 passed`.
- **Red Team (RETEST-001)** — *quien arregló no verifica*: repite el curl → `404`. Evidencia
  real adjunta. Transición del finding a `RESOLVED` (no se sobrescribe el archivo; se **añade**
  la entrada al historial).
- **AppSec**: revisa si el patrón se repite en otros endpoints (espacio negativo): encuentra
  `GET /orders/:id` con el mismo riesgo → `FINDING-002` (HIGH). Se repite el loop. AppSec
  también recomienda un middleware de ownership como requisito de seguridad (ADR sugerido).
- **QA**: regresión completa → PASS (el fix no rompió nada).

## 4. Orchestrator — decisión (iter 2)
Ambos findings HIGH → RESOLVED con evidencia; QA PASS; Red Team PASS; AppSec PASS. No quedan
blockers.
```
status: APPROVED
overrides: []          # no hizo falta override: los HIGH se resolvieron, no se aceptaron
```
Si el fix no hubiera sido viable sin decisión de negocio, la salida habría sido
`HUMAN_REQUIRED` (un HIGH nunca va a producción sin resolución u override documentado).
