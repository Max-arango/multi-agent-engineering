# Reference — Severity Gates & Production Decision

## Escala de severidad
```
CRITICAL · HIGH · MEDIUM · LOW · INFO
```
La asigna el agente que encuentra el problema (QA/Red Team/AppSec) con su `confidence`. El
Orchestrator puede recalibrar con justificación escrita, nunca a la baja para "pasar el gate".

## Política de producción (defaults; configurable en `config/policy.yml`)
```
CRITICAL → NUNCA a producción. Sin excepción automática.
HIGH     → NUNCA a producción salvo OVERRIDE explícito de humano o política documentada.
MEDIUM   → Requiere mitigación, o aceptación de riesgo explícita y documentada (ADR).
LOW      → Aceptable con documentación del riesgo residual.
INFO     → Informativo; no bloquea.
```
Un **override** de un HIGH:
- Lo autoriza el humano (no el Orchestrator por su cuenta) o una política escrita en
  `policy.yml` (`allow_high_override: true` + condiciones).
- Queda registrado en un `ADR-NNN.md` con: qué finding, por qué se acepta, mitigación
  compensatoria, y quién lo autorizó. Sin ADR, no hay override.

## Cómo decide el Orchestrator (algoritmo)
```
blockers = []
para cada finding OPEN:
    if severidad == CRITICAL: blockers += {finding, "CRITICAL nunca produce"}
    if severidad == HIGH and not override_documentado(finding): blockers += {finding, "HIGH sin override"}
    if severidad == MEDIUM and not (mitigado(finding) or riesgo_aceptado_ADR(finding)):
        blockers += {finding, "MEDIUM sin mitigar ni aceptar"}
criterios_ok = todos los acceptance_criteria verificados con evidencia
gates_ok = QA==PASS and (Security==PASS or n/a) and (AppSec==PASS or n/a)

if not criterios_ok or not gates_ok or blockers:
    status = REJECTED   (→ mitigation loop)   ó   HUMAN_REQUIRED si el blocker exige humano
else:
    status = APPROVED
```
Un blocker exige **HUMAN_REQUIRED** (no mero REJECTED) cuando: es CRITICAL, es un HIGH cuyo
fix no es viable sin decisión de negocio, o la mitigación requiere credenciales/infra/acción
externa. Ver SKILL.md §9.

## Production Decision (artefacto obligatorio)
Siempre se emite, aunque sea REJECTED, con `templates/production-decision.md`:
```yaml
task_id: TASK-NNN
iteration: K
status: APPROVED | REJECTED | HUMAN_REQUIRED
acceptance_criteria: [{id, met: true/false, evidence}]
gates: { qa: PASS|FAIL|N/A, red_team: ..., appsec: ... }
blockers:
  - { id: FINDING-NNN, type: SECURITY|FUNCTIONAL|APPSEC, severity: ..., source: ... }
overrides: [{finding, adr, authorized_by}]     # si los hubo
required_action: <qué falta / qué se pide al humano>
evidence_summary: <resumen verificable: comandos, resultados, diffs>
```
Recuerda: **la decisión no es un deploy.** Aprobar significa "cumple el gate"; el despliegue
real requiere autorización aparte (§7 de principios absolutos).
