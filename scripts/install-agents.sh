#!/usr/bin/env bash
# install-agents.sh — genera los subagentes nativos de Claude Code a partir de los
# contratos canónicos de la skill (agents/*.md), añadiéndoles el frontmatter que Claude
# Code espera, y prepara el directorio de estado en el proyecto objetivo.
#
# Uso:
#   scripts/install-agents.sh [--scope user|project] [--project-dir <ruta>]
#     --scope user     -> instala en ~/.claude/agents         (por defecto)
#     --scope project  -> instala en <project-dir>/.claude/agents
#     --project-dir     ruta del proyecto donde crear el estado (por defecto: cwd)
#
# Nota: si el directorio de agentes NO existía al arrancar la sesión de Claude Code,
# hay que reiniciar la sesión UNA vez para que los tipos `mae-*` sean invocables.
# Mientras tanto, la skill funciona con el fallback (general-purpose + contrato inyectado).
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="user"
PROJECT_DIR="$(pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --project-dir) PROJECT_DIR="$(cd "${2:-.}" && pwd)"; shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
done

if [ "$SCOPE" = "user" ]; then
  AGENTS_DIR="$HOME/.claude/agents"
elif [ "$SCOPE" = "project" ]; then
  AGENTS_DIR="$PROJECT_DIR/.claude/agents"
else
  echo "--scope debe ser 'user' o 'project'" >&2; exit 2
fi

mkdir -p "$AGENTS_DIR"

# role|nombre-subagente|tools|descripción (cuándo delegar en él)
ROWS='
planner|mae-planner|Read, Grep, Glob, Bash|Convierte objetivos e ideas en planes implementables y proporcionados; evalúa valor/complejidad/riesgo y marca overengineering. Delegar cuando haya que planear antes de construir.
creative-coordinator|mae-creative|Read, Grep, Glob, Bash|Genera oportunidades de mejora (UX/DX/arquitectura/seguridad) como propuestas para Planner. No implementa. Delegar solo en generación de valor/UX.
builder|mae-builder|Read, Grep, Glob, Edit, Write, Bash|Implementa planes aprobados con tests, respetando patrones del repo y mínimo cambio. Delegar para escribir/modificar código.
optimizer|mae-optimizer|Read, Grep, Glob, Edit, Bash|Mejora rendimiento/legibilidad/mantenibilidad del código de Builder, solo con justificación y sin abstracciones innecesarias. Delegar tras Builder.
qa|mae-qa|Read, Grep, Glob, Bash|Quality gate: intenta demostrar que el trabajo está mal o incompleto (funcional/tests/regresión). Ejecuta tests reales. Delegar para verificar correctitud.
red-team|mae-red-team|Read, Grep, Glob, Bash|Red team defensivo: busca vulnerabilidades explotables dentro del entorno autorizado, con pruebas controladas y no destructivas. Delegar para "¿puedo romperlo?".
appsec|mae-appsec|Read, Grep, Glob, Bash|AppSec/SDLC: evalúa si el cambio está construido de forma segura (secure coding, deps, config, threat model). Delegar para "¿está bien construido?".
'

created=0
echo "$ROWS" | while IFS='|' read -r role name tools desc; do
  [ -z "${role:-}" ] && continue
  src="$SKILL_DIR/agents/$role.md"
  if [ ! -f "$src" ]; then echo "AVISO: falta $src, se omite" >&2; continue; fi
  dst="$AGENTS_DIR/$name.md"
  {
    echo "---"
    echo "name: $name"
    echo "description: $desc"
    echo "tools: $tools"
    echo "# model omitido = inherit (usa el modelo de la sesión)"
    echo "---"
    echo
    echo "> Subagente generado por multi-agent-engineering desde agents/$role.md."
    echo "> Devuelve SIEMPRE tu bloque de handoff YAML como mensaje final; es tu valor de retorno."
    echo
    cat "$src"
  } > "$dst"
  echo "  ✔ $dst"
  created=$((created+1))
done

# Estado del proyecto objetivo
STATE_ROOT="$PROJECT_DIR/.claude/multi-agent"
mkdir -p \
  "$STATE_ROOT/state" \
  "$STATE_ROOT/tasks" \
  "$STATE_ROOT/findings" \
  "$STATE_ROOT/handoffs" \
  "$STATE_ROOT/reports/qa" \
  "$STATE_ROOT/reports/security" \
  "$STATE_ROOT/reports/appsec" \
  "$STATE_ROOT/reports/optimization" \
  "$STATE_ROOT/reports/orchestration" \
  "$STATE_ROOT/decisions" \
  "$STATE_ROOT/config"

[ -f "$STATE_ROOT/config/policy.yml" ] || cp "$SKILL_DIR/config/policy.yml" "$STATE_ROOT/config/policy.yml"

echo
echo "Subagentes en:  $AGENTS_DIR   (mae-planner, mae-creative, mae-builder, mae-optimizer, mae-qa, mae-red-team, mae-appsec)"
echo "Estado en:      $STATE_ROOT"
echo
echo "Si '$AGENTS_DIR' no existía al iniciar la sesión, reinicia Claude Code UNA vez para"
echo "que los tipos mae-* sean invocables. Hasta entonces, la skill usa el fallback automático."
