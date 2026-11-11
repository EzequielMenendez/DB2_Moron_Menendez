# Food Store — Base de Datos II (UTN · 2026)
## Segunda Entrega Parcial del Trabajo Práctico Integrador (Unidades 4 a 8)

**Equipo:** Morón / Menéndez
**Organización de ramas del proyecto:**
- `main`: Unidades 4, 5 y 6 (Normalización avanzada FNBC y desnormalización, Administración y seguridad, Mantenimiento y recuperación).
- `NoSQL`: Unidad 7 (Modelado documental en MongoDB y comparación práctica con PostgreSQL).
- `sqlite` *(rama actual e integradora)*: Unidad 8 (Base móvil SQLite offline, sincronización con resolución de conflictos, code review final de los scripts de la cursada e integración completa de las Unidades 4 a 8).

---

## 📋 Mapa de Cumplimiento de la Segunda Entrega (Unidades 4 a 8)

- **Informe Técnico Integrador (Unidades 4 a 8):** [`docs/informe_segunda_entrega.md`](docs/informe_segunda_entrega.md) y [`docs/informe.pdf`](docs/informe.pdf).
- **Bitácora de IA y DUIA consolidadas:** [`BITACORA.md`](BITACORA.md), [`docs/bitacora_ia.md`](docs/bitacora_ia.md) y [`docs/DUIA.md`](docs/DUIA.md).
- **Especificaciones en Kiro (`.kiro/specs/`):**
  - Unidad 4: [`.kiro/specs/fnbc-y-desnormalizacion/`](.kiro/specs/fnbc-y-desnormalizacion/)
  - Unidad 5: [`.kiro/specs/roles-food-store/`](.kiro/specs/roles-food-store/) y [`.kiro/steering/security-policies.md`](.kiro/steering/security-policies.md)
  - Unidad 6: [`.kiro/specs/mantenimiento-u6/`](.kiro/specs/mantenimiento-u6/) y [`SPEC_U6.md`](SPEC_U6.md)
  - Unidad 8: [`.kiro/specs/movil-sqlite-sync/`](.kiro/specs/movil-sqlite-sync/) y [`docs/kiro/`](docs/kiro/)

| Unidad | Scripts y Objetos de Base de Datos | Documentación y Evidencias |
|---|---|---|
| **Unidad 4 · Normalización avanzada y redundancia** | • [`db/preparar_food_store.sql`](db/preparar_food_store.sql)<br>• [`db/tp_fnbc_control_lote.sql`](db/tp_fnbc_control_lote.sql) *(FNBC + transacción reversible + plan de reversión)*<br>• [`db/tp_desnormalizacion_top_categorias.sql`](db/tp_desnormalizacion_top_categorias.sql) *(tabla resumen + 5 triggers + auditoría)* | • [`docs/informe_unidad4_fnbc.md`](docs/informe_unidad4_fnbc.md) |
| **Unidad 5 · Administración y seguridad** | • [`sql/roles.sql`](sql/roles.sql) *(mínimo privilegio)*<br>• [`sql/auditoria_test.sql`](sql/auditoria_test.sql)<br>• [`sql/simulacro_incidente.sql`](sql/simulacro_incidente.sql)<br>• [`sql/usuario_anon.sql`](sql/usuario_anon.sql) *(anonimización)* | • [`docs/informe_auditoria.md`](docs/informe_auditoria.md)<br>• [`docs/informe_incidente.md`](docs/informe_incidente.md)<br>• [`docs/verificacion_roles.txt`](docs/verificacion_roles.txt)<br>• [`docs/verificacion_equivalencia.md`](docs/verificacion_equivalencia.md)<br>• [`docs/log_auditoria_prueba.txt`](docs/log_auditoria_prueba.txt)<br>• [`docs/log_simulacro_anonimizado.txt`](docs/log_simulacro_anonimizado.txt) |
| **Unidad 6 · Mantenimiento** | • [`db/backup_foodstore.ps1`](db/backup_foodstore.ps1)<br>• [`db/restore_test.ps1`](db/restore_test.ps1) *(simulacro contra reloj)*<br>• [`db/maintenance.sql`](db/maintenance.sql)<br>• [`db/health_check.sql`](db/health_check.sql) | • [`SPEC_U6.md`](SPEC_U6.md)<br>• [`docs/informe_u6.md`](docs/informe_u6.md) *(RTO = 3,52 s, RPO = ~24 min)* |
| **Unidad 7 · NoSQL** | • [`sql/consultas_mongodb.js`](sql/consultas_mongodb.js) *(pedidos IDs 1–5 con `NumberDecimal`)*<br>• [`sql/consultas_postgresql.sql`](sql/consultas_postgresql.sql) | • [`docs/informe_nosql.md`](docs/informe_nosql.md) |
| **Unidad 8 · Bases de datos móviles e integración** | • [`movil/schema_sqlite.sql`](movil/schema_sqlite.sql) *(tablas `STRICT`)*<br>• [`movil/cargar_cache.sql`](movil/cargar_cache.sql) *(conversión `t/f` y lápidas)*<br>• [`movil/semaforo.sql`](movil/semaforo.sql) *(rojo > amarillo > verde)*<br>• [`movil/pruebas_sqlite.sql`](movil/pruebas_sqlite.sql)<br>• [`movil/snapshot_postgresql.sql`](movil/snapshot_postgresql.sql) y [`movil/servidor_pruebas.sql`](movil/servidor_pruebas.sql)<br>• [`movil/pruebas_revision_postgresql.sql`](movil/pruebas_revision_postgresql.sql)<br>• [`movil/simulador.py`](movil/simulador.py) y [`movil/foodstore_movil.db`](movil/foodstore_movil.db)<br>• [`movil/tests/`](movil/tests/) *(25 tests automatizados)* | • [`docs/informe_tp8.md`](docs/informe_tp8.md)<br>• [`docs/evidencia_casos.md`](docs/evidencia_casos.md)<br>• [`docs/evidencia_postgresql.md`](docs/evidencia_postgresql.md)<br>• [`docs/evidencia_revision.md`](docs/evidencia_revision.md)<br>• [`docs/evidencia_tdd.md`](docs/evidencia_tdd.md)<br>• [`docs/defensa_tp8.md`](docs/defensa_tp8.md) |

---

## 🚀 Reproducción Rápida por Unidad

### 1. Unidades 4, 5 y 6 (PostgreSQL 18)

```powershell
# Unidad 4: Preparar esquema base, FNBC (con plan de reversión) y desnormalización controlada
psql -U postgres -d food_store -f db/preparar_food_store.sql
psql -U postgres -d food_store -f db/tp_fnbc_control_lote.sql
psql -U postgres -d food_store -f db/tp_desnormalizacion_top_categorias.sql

# Unidad 5: Esquema de roles de mínimo privilegio, auditoría, simulacro de incidente y anonimización
psql -U postgres -d food_store -f sql/roles.sql
psql -U postgres -d food_store -f sql/auditoria_test.sql
psql -U postgres -d food_store -f sql/simulacro_incidente.sql
psql -U postgres -d food_store -f sql/usuario_anon.sql

# Unidad 6: Respaldo programado, chequeo de salud, mantenimiento y simulacro de desastre contra reloj
powershell -ExecutionPolicy Bypass -File db/backup_foodstore.ps1
psql -U postgres -d food_store -f db/health_check.sql
psql -U postgres -d food_store -f db/maintenance.sql
powershell -ExecutionPolicy Bypass -File db/restore_test.ps1
```

### 2. Unidad 7 (MongoDB y comparación con PostgreSQL)

```powershell
# Cargar documentos embebidos (pedidos IDs 1 a 5 con NumberDecimal) y ejecutar consultas documentales
mongosh --file sql/consultas_mongodb.js

# Ejecutar consultas relacionales equivalentes acotadas a los pedidos 1 a 5
psql -U postgres -d food_store -f sql/consultas_postgresql.sql
```

### 3. Unidad 8 (SQLite 3.37+, Simulación de Sincronización y Suite de 25 Pruebas)

La tablet guarda borradores locales sin conexión; un estado `SIMULADO_APROBADO` indica coincidencia con la instantánea del servidor, **sin confirmar ventas ni descontar stock en PostgreSQL**.

```powershell
# Verificar versión de SQLite (3.37+) y ejecutar la suite completa de 25 tests automatizados (C1 a C7)
python -c "import sqlite3; print(sqlite3.sqlite_version)"
python -m unittest discover -s movil/tests -v

# Crear una base SQLite demo desde cero y evaluar el semáforo (caso C5 -> SIMULADO_APROBADO)
python movil/simulador.py --crear-demo movil/demo_nueva.db
python movil/simulador.py --evaluar movil/demo_nueva.db

# Evaluar conflicto de precio (caso C2 -> CONFLICTO)
python movil/simulador.py --crear-demo movil/demo_precio.db
python movil/simulador.py --evaluar movil/demo_precio.db --snapshot movil/snapshots/c2_precio.csv
```

Para ejecutar las pruebas del Code Review asistido por IA sobre una instancia PostgreSQL de pruebas:

```powershell
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -f movil/pruebas_revision_postgresql.sql
```
