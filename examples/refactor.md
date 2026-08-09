# Ejemplo — Refactor: "Unificar la lógica de validación de email duplicada en 3 sitios"

Refactor interno **sin cambio de comportamiento**: el gate clave es "no hay regresión".

## 1. Orchestrator — clasificación
```
tipo: refactor · superficie: backend/lib · riesgo: ninguno
pipeline: [planner, builder, optimizer, qa, orchestrator]   # sin seguridad: no cambia superficie
```

## 2. Planner
```yaml
status: PLAN_READY
what: "Extraer isValidEmail() a lib/validation y reemplazar las 3 copias."
risks: ["que las 3 copias no fueran idénticas (divergencia silenciosa)"]
acceptance_criteria:
  - {id: AC1, text: "Comportamiento idéntico: mismos inputs → mismos outputs que antes", verify: "tests existentes + tabla de casos borde"}
  - {id: AC2, text: "0 duplicación: las 3 copias eliminadas", verify: "grep no encuentra el patrón"}
proportionality: PROPORTIONATE
```
> Planner detecta el riesgo real: **las tres copias podrían no ser iguales**. Ese es el punto
> donde un refactor "obvio" cambia comportamiento sin querer.

## 3. Builder → Optimizer → QA
- **Builder**: primero **compara** las 3 implementaciones (una aceptaba `+` en el local-part,
  las otras no). Reporta la divergencia al Orchestrator antes de unificar (no elige por su
  cuenta cuál gana): **decisión de comportamiento → sube**. Orchestrator fija "la más estricta"
  y lo registra. Builder extrae, reemplaza, añade tests de los casos divergentes.
- **Optimizer**: `NO_CHANGES_JUSTIFIED` (el refactor ya es la mejora; no añade abstracción extra).
- **QA**: corre toda la suite (regresión = corazón de un refactor) + `grep -rn` para AC2 →
  PASSED. Evidencia: `grep` sin resultados + `N passed`.

## 4. Orchestrator — decisión
```
status: APPROVED · change_summary: "3 duplicados → 1 función + tests de borde. Sin cambio de API."
```
Lección: en un refactor, un **cambio de comportamiento descubierto a mitad** no lo decide
Builder; se escala como decisión y se documenta.
