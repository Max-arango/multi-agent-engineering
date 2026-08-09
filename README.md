# multi-agent-engineering

**Un equipo virtual de ingeniería de software autónomo para Claude Code.** Recibe una tarea
—feature, bug, mejora, refactor, cambio de seguridad o de arquitectura— y ejecuta un ciclo
iterativo real: analizar → planear → implementar → optimizar → QA → seguridad (Red Team) →
AppSec → decisión de producción, con estado persistente, historial de findings y gates que
nadie se salta.

> Autonomous virtual software-engineering team for Claude Code. Content is in Spanish; Claude
> follows the protocol natively in any conversation language.

## La tesis

Un solo agente que "hace todo" mezcla roles que deben estar separados: quien construye no
debe aprobarse a sí mismo, quien pregunta *¿funciona?* no es quien pregunta *¿puedo
romperlo?*, y la decisión de producción no puede tomarla quien tiene el sesgo de haber
escrito el código. Esta skill **externaliza esa separación** en subagentes con contratos
explícitos y un Orchestrator que delega, verifica con evidencia y decide —sin poder aprobar
si quedan blockers.

Se apoya **solo en capacidades nativas verificadas** de Claude Code (skills, subagentes de
`.claude/agents/`, slash commands, estado en archivos). No inventa APIs.

## El equipo

```
                         ┌────────────────────┐
                         │    ORCHESTRATOR     │  (= el agente principal; delega y decide)
                         └─────────┬──────────┘
        ┌──────────────┬──────────┼───────────┬──────────────┐
        ▼              ▼          ▼            ▼              ▼
   ┌─────────┐   ┌─────────┐  ┌───────┐  ┌─────────┐   ┌──────────┐
   │ CREATIVE│   │ PLANNER │  │BUILDER│  │OPTIMIZER│   │  (gates) │
   └─────────┘   └─────────┘  └───────┘  └─────────┘   └────┬─────┘
                                                  ┌─────────┼─────────┐
                                                  ▼         ▼         ▼
                                               ┌────┐  ┌────────┐ ┌────────┐
                                               │ QA │  │RED TEAM│ │ APPSEC │
                                               └────┘  └────────┘ └────────┘
```

Separación de funciones (ninguno duplica al otro):

| Agente | Pregunta que responde |
|---|---|
| **QA** | ¿Funciona correctamente? (funcional, tests, regresión) |
| **Red Team** | ¿Puedo romperlo? (vulnerabilidad explotable, prueba controlada y no destructiva) |
| **AppSec** | ¿Está construido de forma segura? (secure coding, deps, config, SDLC) |
| **Orchestrator** | ¿Está realmente listo para producción? (decisión final, no puede aprobar con blockers) |

Y en el front: **Creative** genera ideas (no ordena implementación → pasan por Planner);
**Planner** convierte objetivos en planes proporcionados (anti-overengineering); **Builder**
construye con mínimo cambio; **Optimizer** mejora solo con justificación.

## Qué incluye

| Ruta | Qué es |
|---|---|
| `SKILL.md` | El protocolo operacional: dispatch, bootstrap, loop, delegación, gates, decisión. |
| `agents/*.md` | Los 8 contratos (ROLE, MISSION, RESPONSIBILITIES, INPUTS, OUTPUTS, TOOLS, CONSTRAINTS, FAILURE CONDITIONS, HANDOFF). |
| `reference/*.md` | Loop engine, selección de pipeline, gates de severidad, esquema de estado, estrategia de test. Se cargan on demand. |
| `templates/*.md` | Task, handoff, finding (historial), ADR, production-decision, report. |
| `config/policy.yml` | Política configurable: iteraciones, severidad, guardrails, escalada. |
| `scripts/install-agents.sh` | Genera los subagentes nativos y el estado del proyecto. |
| `commands/mae.md` | Alias `/mae` → la skill. |
| `examples/*.md` | feature · bug · security-issue (mitigation loop) · refactor · architecture-change. |

## Instalación

**1) La skill** (Claude Code, todos los proyectos) — clona este repo directamente en la
carpeta de skills:
```bash
git clone https://github.com/Max-arango/multi-agent-engineering.git ~/.claude/skills/multi-agent-engineering
# o para un solo proyecto:  git clone … <proyecto>/.claude/skills/multi-agent-engineering
```

**2) Los subagentes nativos + el estado** (ejecutar en la raíz del proyecto donde vas a
trabajar):
```bash
~/.claude/skills/multi-agent-engineering/scripts/install-agents.sh --scope user
# crea ~/.claude/agents/mae-*.md  y  <proyecto>/.claude/multi-agent/…
```

**3) El alias de comando** (opcional):
```bash
cp ~/.claude/skills/multi-agent-engineering/commands/mae.md ~/.claude/commands/mae.md
```

> **Reinicio único:** Claude Code solo detecta subagentes nuevos en caliente si el directorio
> `agents/` ya existía al arrancar la sesión. Si `~/.claude/agents/` no existía, **reinicia la
> sesión una vez** para que los tipos `mae-*` sean invocables. **No es bloqueante:** la skill
> trae un *fallback universal* que lanza los mismos roles como subagentes `general-purpose` con
> el contrato inyectado en el prompt, así que funciona desde el primer momento, con o sin
> reinicio.

## Uso

```
/multi-agent-engineering run "Crea un endpoint de health-check con tests"
/mae run "Añade paginación al endpoint GET /users"      # alias equivalente

/mae status      # tablero del equipo + iteración + findings abiertos
/mae review      # última Production Decision
/mae findings    # historial de findings (OPEN/FIXED/RESOLVED/…)
/mae history     # timeline del run
/mae pause | resume | stop
```

El Orchestrator clasifica la tarea y elige el **pipeline mínimo** que da garantía suficiente
(un bug de UI no convoca a Red Team; una API sí). Todo el trabajo queda en
`.claude/multi-agent/` del proyecto, reconstruible tras un reinicio.

## Estado persistente

```
.claude/multi-agent/
├── state/     current-task · project-state · agent-state · run-log
├── tasks/     TASK-NNN.md
├── findings/  FINDING-NNN.md   (historial append-only, nunca sobrescrito)
├── handoffs/  artefactos de comunicación entre agentes
├── reports/   qa · security · appsec · optimization · orchestration
└── decisions/ ADR-NNN.md
```

## Seguridad y límites

- **Red Team es defensivo:** trabaja solo dentro del entorno autorizado del proyecto; pruebas
  `AUTHORIZED · CONTROLLED · REPRODUCIBLE · NON-DESTRUCTIVE`. No ataca sistemas externos.
- **Gates de severidad:** CRITICAL nunca va a producción; HIGH solo con override documentado
  (ADR + autorización); MEDIUM requiere mitigación o aceptación de riesgo. Configurable.
- **Sin deploy automático** y **sin git destructivo** (`reset --hard`, `clean -fd`, force push)
  sin autorización explícita.
- **Principio de evidencia:** ninguna afirmación sin evidencia real. Nunca "un test pasó" sin
  su salida; nunca "es seguro" por no haber encontrado el fallo.
- **Escalada a humano** ante ambigüedad, operación irreversible, vulnerabilidad crítica,
  credenciales necesarias, bucle estancado o recomendaciones en conflicto.

## Licencia

MIT — ver `LICENSE`.
