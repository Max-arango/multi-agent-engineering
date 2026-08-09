# Changelog

## 1.0.0 — 2026-08-08

Versión inicial. Equipo virtual de ingeniería de software autónomo para Claude Code,
construido sobre capacidades nativas verificadas (skills, subagentes `.claude/agents/`,
slash commands) — sin APIs inventadas.

- **Protocolo operacional (`SKILL.md`):** dispatch por subcomando
  (`run|status|review|findings|history|pause|resume|stop`), bootstrap de estado,
  loop engine (THINK→DELEGATE→VERIFY→ITERATE→DECIDE), mecanismo de delegación real
  (subagentes nativos `mae-*` con fallback universal `general-purpose` + contrato inyectado),
  gates de separación de funciones, production gate, observabilidad y principios absolutos.
- **8 contratos de agente (`agents/`):** orchestrator, planner, creative-coordinator,
  builder, optimizer, qa, red-team, appsec — cada uno con ROLE, MISSION, RESPONSIBILITIES,
  INPUTS, OUTPUTS, TOOLS, CONSTRAINTS, FAILURE CONDITIONS y HANDOFF FORMAT.
- **Referencias (`reference/`):** loop-engine (PROGRESS_SCORE, anti-bucle, failure recovery),
  pipeline-selection (loop inteligente por clase de tarea), severity-gates (política de
  producción + decisión), state-schema (Task Object, handoff, findings), testing-strategy.
- **Plantillas (`templates/`):** task, handoff, finding (con historial append-only), adr,
  production-decision, report.
- **Estado persistente:** `.claude/multi-agent/` (state, tasks, findings, handoffs, reports,
  decisions) reconstruible tras reinicio.
- **Instalación (`scripts/install-agents.sh`):** genera los subagentes nativos desde los
  contratos y prepara el estado del proyecto. Política configurable (`config/policy.yml`).
- **Alias de comando (`commands/mae.md`):** `/mae …` → forwarding a la skill.
- **Ejemplos (`examples/`):** feature, bug, security-issue (con mitigation loop), refactor,
  architecture-change.
- **Reconciliación de findings segura bajo gates en paralelo:** el Orchestrator asigna los
  `FINDING-NNN` canónicos y deduplica por `signature`; los gates devuelven `local_ref` en vez de
  reservar IDs (evita colisiones cuando QA/Red Team/AppSec corren concurrentes). Documentado en
  `SKILL.md` §8 y `reference/state-schema.md`.
- **Validación:** ejecutado un ciclo de aceptación real de extremo a extremo sobre un endpoint
  health-check (Planner→Builder→Optimizer→QA→AppSec→Red Team→Orchestrator→APPROVED), más un
  escenario de fallo deliberado (fuga CRITICAL vía `?debug`) que ejercita el mitigation loop
  completo (finding→fix→retest→resolved) y la recuperación ante un subagente interrumpido.
