# DB2 — Food Store (Unidades 4 y 5)

Trabajo práctico integrador sobre la base **`food_store`** (PostgreSQL 18).

---

## Estructura de Entregables

### Unidad 4: FNBC y Desnormalización Controlada
- [`db/tp_fnbc_control_lote.sql`](db/tp_fnbc_control_lote.sql) — Análisis de FNBC de `ControlLoteAlmacen`: dependencias funcionales, claves candidatas, violación por FD2, descomposición sin pérdida y vista de compatibilidad.
- [`db/tp_desnormalizacion_top_categorias.sql`](db/tp_desnormalizacion_top_categorias.sql) — Reporte top-5 categorías del día desnormalizado (`venta_categoria_dia` + disparadores); EXPLAIN ANALYZE antes (57ms) / después (0.07ms) y auditoría = 0 filas.
- [`docs/informe_unidad4_fnbc.md`](docs/informe_unidad4_fnbc.md) — Informe técnico completo.

### Unidad 5: Administración y Seguridad (Roles, Auditoría, Incidentes y Privacidad)
- [`sql/roles.sql`](sql/roles.sql) — Roles de grupo y login, privilegios de mínimo privilegio, permisos a nivel de columna y `ALTER DEFAULT PRIVILEGES`.
- [`docs/kiro_roles_spec/`](docs/kiro_roles_spec/) — Especificación Kiro (`requirements.md` y `design.md`).
- [`sql/auditoria_test.sql`](sql/auditoria_test.sql) & [`docs/informe_auditoria.md`](docs/informe_auditoria.md) — Activación y prueba de auditoría nativa (`log_connections`, `log_statement`).
- [`sql/simulacro_incidente.sql`](sql/simulacro_incidente.sql) & [`docs/informe_incidente.md`](docs/informe_incidente.md) — Simulacro de acceso indebido, log anonimizado y contraste crítico con IA.
- [`sql/usuario_anon.sql`](sql/usuario_anon.sql) & [`docs/verificacion_equivalencia.md`](docs/verificacion_equivalencia.md) — Anonimización determinista de clientes y verificación de equivalencia agregada (20.000 filas).
- [`BITACORA.md`](BITACORA.md) — Bitácora obligatoria de uso de IA, prompts, validaciones y análisis de imprecisiones.

---

## Cómo Reproducir

```powershell
# 1) Preparar y poblar food_store (Unidad 4)
psql -U postgres -d food_store -f db\preparar_food_store.sql

# 2) Ejecutar scripts de Unidad 5
psql -U postgres -d food_store -f sql\roles.sql
psql -U postgres -d food_store -f sql\auditoria_test.sql
psql -U postgres -d food_store -f sql\simulacro_incidente.sql
psql -U postgres -d food_store -f sql\usuario_anon.sql
```
