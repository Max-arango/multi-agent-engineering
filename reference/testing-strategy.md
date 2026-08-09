# Reference — Testing Strategy (§24)

Cómo QA (y Builder al auto-verificar) deciden **qué** ejecutar. El principio rector: los tests
validan **comportamiento real**; no se fabrican tests para pintar el pipeline en verde.

## Descubrimiento antes que invención
1. **Lee los comandos reales** del proyecto — no los adivines. Fuentes por orden:
   `package.json` (`scripts`), `Makefile`, `pyproject.toml`/`tox.ini`, `Cargo.toml`,
   `pytest.ini`, CI (`.github/workflows/*`, `.gitlab-ci.yml`). Regístralos en `project-state.md`.
2. Si no hay comando de test, dilo explícitamente; no simules uno.

## Prioridad de ejecución
```
tests existentes  →  unit  →  integration  →  e2e  →  lint / type-check / build  →  regression  →  security tests
```
- **Tests existentes primero**: son la red de seguridad contra regresiones. Córrelos antes y
  después del cambio para comparar.
- **Regresión**: ¿algo que pasaba antes falla ahora? Compara con el estado previo (o con
  `git stash`/rama base si hace falta y es no destructivo).
- **Security tests** (los ejercita Red Team/AppSec, no QA): pruebas controladas y no
  destructivas dentro del entorno del proyecto.

## Crear tests solo cuando aporta cobertura real
Añade un test si el cambio introduce comportamiento no cubierto y el test **puede fallar** si
el comportamiento se rompe. Un test que no puede fallar es teatro. Antes de correr cualquier
suite, **escribe qué salida esperas**; si no puedes predecirla, no entiendes el sistema aún.

## Evidencia
Toda afirmación de test lleva la **salida real** (recortada) del comando: `N passed, M failed`,
el nombre del test que falló, el trace. "Los tests pasan" sin salida no es evidencia. Si un
test no se ejecutó, no se reporta como PASS.

## Cuando el entorno no arranca
Reporta `ENVIRONMENT_BLOCKED` con la salida del fallo y trátalo como blocker de verificación
(no como PASS). Puede requerir escalada si depende de credenciales/infra.
