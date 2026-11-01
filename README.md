# DB2 — Food Store (Unidades 4, 5 y 6)

Trabajo práctico integrador sobre la base **`food_store`** (PostgreSQL 18).

---

## Estructura de Entregables

### Unidad 4: FNBC y Desnormalización Controlada
- [`db/tp_fnbc_control_lote.sql`](db/tp_fnbc_control_lote.sql) — Análisis de FNBC de `ControlLoteAlmacen`.
- [`db/tp_desnormalizacion_top_categorias.sql`](db/tp_desnormalizacion_top_categorias.sql) — Reporte top-5 categorías desnormalizado.
- [`docs/informe_unidad4_fnbc.md`](docs/informe_unidad4_fnbc.md) — Informe técnico.

### Unidad 5: Administración y Seguridad
- [`sql/roles.sql`](sql/roles.sql) — Roles, permisos de mínimo privilegio y `ALTER DEFAULT PRIVILEGES`.
- [`docs/kiro_roles_spec/`](docs/kiro_roles_spec/) — Especificación Kiro (`requirements.md` y `design.md`).
- [`sql/auditoria_test.sql`](sql/auditoria_test.sql) & [`docs/informe_auditoria.md`](docs/informe_auditoria.md) — Auditoría nativa (`log_connections`, `log_statement`).
- [`sql/simulacro_incidente.sql`](sql/simulacro_incidente.sql) & [`docs/informe_incidente.md`](docs/informe_incidente.md) — Simulacro de acceso indebido, log anonimizado y contraste crítico.
- [`sql/usuario_anon.sql`](sql/usuario_anon.sql) & [`docs/verificacion_equivalencia.md`](docs/verificacion_equivalencia.md) — Anonimización determinista y verificación de equivalencia (20.000 filas).

### Unidad 6: Mantenimiento, Respaldo y Recuperación
- [`SPEC_U6.md`](SPEC_U6.md) — Especificación y plan de mantenimiento.
- [`db/backup_foodstore.ps1`](db/backup_foodstore.ps1) — Script de respaldo automatizable (`-Fc`, fecha/hora, logs).
- [`db/health_check.sql`](db/health_check.sql) — Consultas de monitoreo (tamaño, conexiones, tuplas muertas, actividad).
- [`db/maintenance.sql`](db/maintenance.sql) — Mantenimiento preventivo con `ANALYZE` justificado.
- [`db/restore_test.ps1`](db/restore_test.ps1) — Automatización del ensayo de restauración.
- [`docs/informe_u6.md`](docs/informe_u6.md) — Informe post-incidente, RPO, RTO (3.52s) y validaciones.

- [`BITACORA.md`](BITACORA.md) — Bitácora obligatoria de uso de IA.

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

# 3) Ejecutar respaldo y simulacro de recuperación (Unidad 6)
powershell -File db\backup_foodstore.ps1
powershell -File db\restore_test.ps1
```
