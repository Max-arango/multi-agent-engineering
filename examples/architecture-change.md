# Ejemplo — Cambio de arquitectura: "Introducir una capa de caché para el catálogo"

Cambio con impacto arquitectónico → genera **ADR**, y AppSec/Red Team entran por la nueva
superficie (invalidez de caché, envenenamiento, fuga entre usuarios).

## 1. Orchestrator — clasificación
```
tipo: arquitectura · superficie: backend+datos+infra · riesgo: trust-boundary (caché compartida)
pipeline: [planner, (ADR), builder, optimizer, qa, appsec, red-team, orchestrator]
```

## 2. Planner — proporcionalidad primero
```yaml
status: OVERENGINEERING_FLAGGED  →  luego PLAN_READY
simple_vs_proposed: >
  PROPUESTA original: Redis distribuido + invalidación por eventos + warm-up.
  SIMPLE: caché en memoria con TTL corto por instancia. El catálogo cambia ~1/día y hay 2
  instancias. Redis es OVERENGINEERED para el tráfico actual: recomiendo in-memory + TTL y
  revisitar si el tráfico crece 10x.
acceptance_criteria:
  - {id: AC1, text: "Segunda lectura del mismo producto no toca la BD dentro del TTL", verify: "test con espía de la BD"}
  - {id: AC2, text: "TTL expira → se re-lee de la BD", verify: "test con reloj simulado"}
  - {id: AC3, text: "La caché NUNCA mezcla datos entre usuarios (catálogo es público, pero probar aislamiento)", verify: "test + Red Team"}
```
Orchestrator acepta la simplificación y crea `ADR-001` (decisión: in-memory TTL vs Redis, con
consecuencias y condición de revisita).

## 3. Builder → Optimizer → gates
- **Builder**: implementa caché in-memory con TTL, invalidación en escrituras del catálogo,
  tests AC1–AC3. Evidencia real de tests.
- **Optimizer**: mide — sin caché p95=140ms, con caché p95=8ms en lecturas repetidas
  (**benchmark real adjunto**, no inventado). Justifica el cambio con datos.
- **AppSec**: revisa que la clave de caché no incluya datos de sesión (catálogo es público) y
  que no se cachee tras auth por error → PASS con recomendación de header `Cache-Control`.
- **Red Team**: intenta cache poisoning vía cabeceras y key confusion → sin vector explotable
  con la clave usada. PASS + `coverage_note`.
- **QA**: regresión + AC1–AC3 → PASSED.

## 4. Orchestrator — decisión
```
status: APPROVED
decisions: [ADR-001]
change_summary: "Caché in-memory TTL en el servicio de catálogo; +benchmark; +3 tests."
```
Lección: un cambio de arquitectura pasa por **ADR** y por gates de seguridad **aunque el dato
sea público**, porque la nueva superficie (caché) puede filtrar o envenenar.
