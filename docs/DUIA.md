# Declaración de Uso de Inteligencia Artificial (DUIA) — Segunda Entrega Parcial

**Asignatura:** Base de Datos II · UTN · Ciclo Lectivo 2026
**Proyecto:** Food Store (Unidades 4 a 8)
**Equipo:** Morón / Menéndez
**Fecha:** Noviembre 2026

---

## 1. Herramientas de IA Utilizadas y Propósito

Durante el desarrollo de la segunda etapa del Trabajo Práctico Integrador (Unidades 4 a 8) se utilizaron las siguientes herramientas de asistencia por Inteligencia Artificial bajo supervisión y validación del equipo:

1. **Kiro (Flujo de Especificaciones — Specs):**
   - Estructuración de requisitos funcionales y no funcionales (formato de historias de usuario y sintaxis EARS), decisiones de diseño arquitectónico y listas de tareas en `.kiro/specs/` (`fnbc-y-desnormalizacion`, `roles-food-store`, `mantenimiento-u6` y `movil-sqlite-sync`) y `docs/kiro/`.
2. **OpenCode / Asistente de Código IA:**
   - Generación asistida y refactorización de scripts SQL (PostgreSQL 18 y SQLite 3.37+), scripts de MongoDB (`mongosh`), automatización en PowerShell (`backup_foodstore.ps1`, `restore_test.ps1`) y simulador/tests en Python (`movil/simulador.py`, `movil/tests/`).
   - Asistencia en la auditoría de seguridad del esquema de permisos (Unidad 5), interpretación del log del simulacro de acceso indebido (Unidad 5), evaluación comparativa NoSQL vs. Relacional (Unidad 7) y code review final de todos los scripts de la cursada (Unidad 8).

---

## 2. Validación Humana y Criterio Técnico Aplicado

Todas las salidas sugeridas por la IA fueron sometidas a verificación empírica sobre motores reales (PostgreSQL 18, MongoDB y SQLite 3.37+) antes de incorporarse al repositorio:

- **Propuestas aceptadas y validadas con pruebas:**
  - Descomposición a FNBC de `control_lote_almacen` en transacción reversible con plan de reversión y tabla resumen `venta_categoria_dia` mantenida por 5 disparadores (Unidad 4).
  - Separación de roles de grupo (`NOLOGIN`) y roles de login con permisos a nivel de columna y anonimización determinista de 20.000 clientes (Unidad 5).
  - Automatización de respaldos `pg_dump -Fc`, mantenimiento `VACUUM ANALYZE` y simulacro de restauración contra reloj con RTO de `3,52 s` (Unidad 6).
  - Modelado de pedidos con documentos embebidos y `NumberDecimal` en MongoDB contrastado contra PostgreSQL sobre los pedidos IDs 1 a 5 (Unidad 7).
  - Esquema SQLite `STRICT`, conversión explícita de booleanos `t/f` con lápidas (`eliminado = 1`), semáforo con prioridad rojo > amarillo > verde y 25 tests automatizados (Unidad 8).
- **Propuestas descartadas o corregidas por decisión humana:**
  - **Unidad 5:** Se rechazó la recomendación de otorgar `GRANT ALL PRIVILEGES ON DATABASE food_store TO app_web` porque vulneraba el principio de mínimo privilegio.
  - **Unidad 7:** Se refutó con documentación oficial la afirmación de que cruzar múltiples colecciones independientes en MongoDB (`$lookup`) supera al optimizador relacional de PostgreSQL.
  - **Unidad 8 (Code Review):** Se descartó eliminar la columna `subtotal` de `detalle_pedido`, demostrando en PostgreSQL (`SQLSTATE 428C9`) que al ser `GENERATED ALWAYS AS (cantidad * precio_unitario) STORED` no puede desincronizarse manualmente.
  - **Unidad 8 (Importación CSV):** Se corrigió el manejo de booleanos `'t'/'f'` exportados por PostgreSQL usando staging textual antes de poblar las tablas `STRICT` de SQLite.

---

## 3. Declaración de Responsabilidad y Autoría

Los integrantes del equipo declaran haber revisado, ejecutado, probado y comprendido la totalidad de las especificaciones, scripts SQL/NoSQL/PowerShell/Python, pruebas automatizadas e informes técnicos que conforman esta entrega, asumiendo plena responsabilidad académica sobre las decisiones de diseño adoptadas y su defensa oral.
