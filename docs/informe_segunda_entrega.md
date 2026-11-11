# Informe Técnico Integrador — Segunda Entrega Parcial (Unidades 4 a 8)
## Proyecto «Food Store» · Base de Datos II (UTN · 2026)

**Equipo:** Morón / Menéndez
**Motor principal:** PostgreSQL 18.x · **Motor documental:** MongoDB (`mongosh`) · **Motor móvil:** SQLite 3.37+ (`STRICT`)
**Organización de ramas:** `main` (Unidades 4 a 6), `NoSQL` (Unidad 7) y `sqlite` (Integración completa Unidades 4 a 8).

---

## 1. Elementos Implementados por Unidad (Unidades 4 a 8)

| Unidad | Objetivo Acreditado | Artefactos Implementados (Scripts, Specs y Documentación) |
|---|---|---|
| **Unidad 4 · Normalización avanzada y redundancia** | • Refactorización de `control_lote_almacen` hasta **FNBC** validada contra dependencias funcionales reales.<br>• Migración sin pérdida en transacción reversible con **plan de reversión obligatorio**.<br>• Desnormalización controlada del reporte Top-5 categorías del día con salvaguardas. | • **Specs Kiro:** `.kiro/specs/fnbc-y-desnormalizacion/` (`requirements.md`, `design.md`, `tasks.md`).<br>• **Scripts SQL:** `db/preparar_food_store.sql`, `db/tp_fnbc_control_lote.sql` y `db/tp_desnormalizacion_top_categorias.sql`.<br>• **Informe:** `docs/informe_unidad4_fnbc.md`. |
| **Unidad 5 · Administración y seguridad** | • Esquema de usuarios, roles de grupo (`NOLOGIN`) y roles de login bajo el **principio de mínimo privilegio**.<br>• Auditoría nativa activada y probada con **simulacro de acceso indebido** y propuesta de contención.<br>• Auditoría de seguridad asistida por IA con decisión humana documentada y anonimización de datos personales. | • **Specs Kiro:** `.kiro/specs/roles-food-store/` y `docs/kiro_roles_spec/`.<br>• **Políticas:** `.kiro/steering/security-policies.md`.<br>• **Scripts SQL:** `sql/roles.sql`, `sql/auditoria_test.sql`, `sql/simulacro_incidente.sql`, `sql/usuario_anon.sql`.<br>• **Informes y evidencias:** `docs/informe_auditoria.md`, `docs/informe_incidente.md`, `docs/verificacion_roles.txt`, `docs/verificacion_equivalencia.md`, `docs/log_auditoria_prueba.txt`, `docs/log_simulacro_anonimizado.txt`. |
| **Unidad 6 · Mantenimiento** | • Plan de mantenimiento completo (respaldo custom programado, estadísticas, limpieza `VACUUM ANALYZE`, chequeo de salud y verificación de integridad) automatizado con OpenCode.<br>• **Simulacro de desastre contra reloj** con medición de RTO/RPO e **informe post-incidente**. | • **Specs:** `SPEC_U6.md` y `.kiro/specs/mantenimiento-u6/`.<br>• **Scripts PowerShell y SQL:** `db/backup_foodstore.ps1`, `db/restore_test.ps1`, `db/maintenance.sql`, `db/health_check.sql`.<br>• **Informe post-incidente:** `docs/informe_u6.md`. |
| **Unidad 7 · NoSQL** | • Modelado del subconjunto de pedidos y detalles en **MongoDB** con documentos embebidos y montos `NumberDecimal`, verificado sobre datos reales (pedidos IDs 1 a 5).<br>• Comparación práctica y justificación técnica entre la solución documental y la relacional. | • **Scripts MongoDB y SQL:** `sql/consultas_mongodb.js` y `sql/consultas_postgresql.sql`.<br>• **Informe técnico comparativo:** `docs/informe_nosql.md`. |
| **Unidad 8 · Bases de datos móviles e integración** | • Base **SQLite (`STRICT`)** del dominio para tablet offline en feria y sincronización especificados en Kiro y generados con OpenCode.<br>• Sincronización simulada contra el servidor con casos de conflicto **C1 a C7** probados y resueltos.<br>• **Code review final asistido por IA** de todos los scripts de la cursada con decisión humana documentada.<br>• Capa de datos completa (relacional, documental y móvil) integrada en el plan de mantenimiento. | • **Specs Kiro:** `.kiro/specs/movil-sqlite-sync/` y `docs/kiro/` (`requirements.md`, `design.md`, `tasks.md`, `simulacion_kiro.md`).<br>• **Scripts SQLite, PG y Python:** `movil/schema_sqlite.sql`, `movil/cargar_cache.sql`, `movil/semaforo.sql`, `movil/pruebas_sqlite.sql`, `movil/snapshot_postgresql.sql`, `movil/servidor_pruebas.sql`, `movil/pruebas_revision_postgresql.sql`, `movil/simulador.py`, `movil/foodstore_movil.db`.<br>• **Tests automatizados (25 pruebas):** `movil/tests/test_sqlite.py`, `test_snapshots_postgresql.py`, `test_simulador.py`.<br>• **Informes y evidencias:** `docs/informe_tp8.md`, `docs/evidencia_casos.md`, `docs/evidencia_postgresql.md`, `docs/evidencia_revision.md`, `docs/evidencia_tdd.md`, `docs/defensa_tp8.md`. |

---

## 2. Metodología de Pruebas Aplicada

1. **Transacciones reversibles y verificación sin pérdida (Unidad 4):**
   - En `db/tp_fnbc_control_lote.sql`, la descomposición hacia `control_lote_responsable` (R1) y `responsable_deposito` (R2) se ejecuta dentro de `BEGIN ... COMMIT` con un bloque `DO $$` que evalúa `EXCEPT` en ambos sentidos contra la vista `v_control_lote_almacen_compat`; si existiera cualquier diferencia (`v_diff > 0`), lanza `RAISE EXCEPTION` y revierte la transacción. Al final del script se prueba el **plan de reversión obligatorio** dentro de un bloque `BEGIN ... ROLLBACK` que reconstruye la tabla original sin pérdida.
   - En `db/tp_desnormalizacion_top_categorias.sql`, la actualización automática de `venta_categoria_dia` ante nuevas ventas se comprueba en vivo dentro de `BEGIN ... ROLLBACK`, verificando con la consulta auditora `FULL OUTER JOIN` que existan `0` filas desincronizadas.
2. **Simulacro de acceso indebido y validación de roles/anonimización (Unidad 5):**
   - Se probaron permisos efectivos conectando con los distintos roles (`docs/verificacion_roles.txt`), confirmando que `rol_soporte` solo accede a las columnas autorizadas y que `app_web` no puede ejecutar `DELETE` ni `DDL`.
   - En `sql/simulacro_incidente.sql` se ejecutó una secuencia controlada de intentos fallidos de autenticación en `fn_autenticar`, lectura masiva (`SELECT * FROM cliente LIMIT 500`) e intento de escalamiento (`GRANT admin_datos TO rol_app_lectura`), capturando y anonimizando la traza en `docs/log_simulacro_anonimizado.txt`.
   - En `sql/usuario_anon.sql` se verificó que las consultas agregadas sobre `cliente_anon` devuelven exactamente los mismos conteos (20.000 clientes) que sobre `cliente`.
3. **Copias de prueba y simulacro de desastre contra reloj (Unidad 6):**
   - `db/restore_test.ps1` crea desde cero una base aislada `foodstore_restore_test`, restaura el último archivo `.dump` comprimido (`pg_dump -Fc`) midiendo el tiempo con `System.Diagnostics.Stopwatch`, y ejecuta consultas de validación sobre conteos de las 5 tablas operativas y restricciones `CHECK` (`precio >= 0`, `stock >= 0`, `cantidad > 0`).
4. **Verificación cruzada sobre datos reales en PostgreSQL y MongoDB (Unidad 7):**
   - Se extrajeron los pedidos reales con IDs `1` al `5` de `food_store` y se insertaron en `foodstore_nosql.pedidos` (`sql/consultas_mongodb.js`). Se ejecutaron consultas equivalentes en ambos motores (`sql/consultas_postgresql.sql` acotado a `WHERE p.id BETWEEN 1 AND 5`) contrastando cantidades e identificadores exactos.
5. **Casos de conflicto de sincronización móvil y suite TDD (Unidad 8):**
   - Se implementó una suite automatizada de **25 pruebas** (`python -m unittest discover -s movil/tests -v`) que crea bases SQLite temporales, exporta/importa snapshots reales desde PostgreSQL (`movil/servidor_snapshot.csv` y `movil/snapshots/c2_precio.csv`, `c3_stock.csv`, `c4_baja.csv`) y verifica los 7 casos de aceptación (`C1` a `C7`), transacciones `COMMIT`/`ROLLBACK` e invariancia del servidor PostgreSQL antes y después de la simulación.

---

## 3. Resultados Obtenidos

### 3.1. Rendimiento y Consistencia en Unidad 4
- **FNBC (`control_lote_almacen`):** 3 filas originales = 3 filas recuperadas por reunión natural `v_control_lote_almacen_compat`; `original EXCEPT vista = 0` y `vista EXCEPT original = 0`.
- **Desnormalización (`venta_categoria_dia` sobre 100.000 pedidos y 300.000 líneas):**
  - Tiempo antes (consulta normalizada con `Parallel Seq Scan` sobre 4 tablas): **`57,108 ms`**.
  - Tiempo después (consulta sobre tabla resumen indexada `idx_vcd_fecha`): **`0,071 ms`** (**mejora de ~800×**).
  - Filas desincronizadas detectadas por la auditoría `FULL OUTER JOIN`: **`0`**.

### 3.2. Seguridad y Simulacro de Acceso Indebido en Unidad 5
- **Reconstrucción del incidente desde el log (`docs/informe_incidente.md`):**
  1. Tres intentos consecutivos contra `fn_autenticar('atacante_anon@mail.com', '***')` en 4 segundos (enumeración/fuerza bruta).
  2. Acceso posterior y extracción de 500 registros de `cliente`.
  3. Intento de escalamiento de privilegios `GRANT admin_datos TO rol_app_lectura` bloqueado por PostgreSQL con `ERROR: permission denied for role "admin_datos"`.
- **Propuesta de contención definida por el equipo:** rotación inmediata de credenciales afectadas, bloqueo perimetral de la IP de origen de la sesión e invalidación de tokens/sesiones activas.

### 3.3. Simulacro de Desastre e Informe Post-Incidente en Unidad 6
- **Archivo restaurado:** `food_store_20261101_125256.dump` (formato custom `-Fc`).
- **RTO (Recovery Time Objective) alcanzado:** **`3,52 segundos`** (incluyendo creación de `foodstore_restore_test`, `pg_restore` y validaciones).
- **RPO (Recovery Point Objective) observado:** **`~24 minutos`** respecto de la última copia programada.
- **Integridad verificada post-restauración:** `categoria` = 9 filas, `cliente` = 20.000 filas, `producto` = 10.000 filas, `pedido` = 100.000 filas, `detalle_pedido` = 300.000 filas; **0 violaciones** de restricciones `CHECK`.
- **Hallazgo post-incidente corregido:** se ajustó `db/restore_test.ps1` para gestionar de forma idempotente la eliminación previa de la base de prueba cuando aún no existía.

### 3.4. Equivalencia Relacional vs. Documental en Unidad 7
| Consulta ejecutada sobre los pedidos migrados (IDs 1 a 5) | Resultado PostgreSQL | Resultado MongoDB | Coincidencia de IDs |
|---|---|---|---|
| Todos los pedidos migrados (`a`) | 5 (`IDs: 1, 2, 3, 4, 5`) | 5 (`_id: 1, 2, 3, 4, 5`) | **Exacta (Sí)** |
| Filtrado por estado `CONFIRMADO` (`b`) | 3 (`IDs: 1, 2, 4`) | 3 (`_id: 1, 2, 4`) | **Exacta (Sí)** |
| Pedidos que contienen `producto_id = 80` en sus líneas (`c`) | 1 (`ID: 1`) | 1 (`_id: 1`) | **Exacta (Sí)** |
| Pedidos con `total_pedido > 2000` usando `NumberDecimal` (`d`) | 4 (`IDs: 1, 2, 3, 5`) | 4 (`_id: 1, 2, 3, 5`) | **Exacta (Sí)** |

### 3.5. Casos de Sincronización Móvil (C1–C7) en Unidad 8
- **Suite completa:** `25 tests exécutados en 1,18 s — OK` (`docs/evidencia_casos.md`).
- **C1 (Catálogo offline):** consulta local sin red devuelve productos activos (`IDs 10 y 15`).
- **C2 (Conflicto de precio y resolución):** cambio de precio en servidor (`450000` → `460000` centavos) marca `CONFLICTO`. Al aceptar el cliente el nuevo precio, se actualiza `precio_centavos_visto = 460000` y se encola una nueva solicitud con UUID nuevo que resulta `SIMULADO_APROBADO`, conservando la solicitud previa en `CONFLICTO` como traza histórica.
- **C3 (Stock insuficiente):** solicitar 2 unidades con stock 1 en instantánea produce `RECHAZADO`.
- **C4 (Baja lógica y lápida):** dar de baja el producto 10 en el servidor e importar el CSV produce `RECHAZADO`; el producto desaparece del catálogo visible pero permanece su fila con `eliminado = 1` (lápida) en `producto_cache`, preservando la integridad referencial del borrador.
- **C5 (Aprobación simulada e invariancia del servidor):** coincidencia total produce `SIMULADO_APROBADO` sin mutar PostgreSQL (`pedidos = 1`, stock producto 10 = `10`, stock producto 15 = `5` idénticos antes y después).
- **C6 (Idempotencia):** repetir un `solicitud_uuid` falla por `PRIMARY KEY` y reejecutar el semáforo ignora solicitudes que ya no están en estado `PENDIENTE`.
- **C7 (Atomicidad transaccional):** insertar cantidad `0` (`CHECK`) o producto `999` (`FOREIGN KEY`) revierte toda la transacción (`ROLLBACK`), dejando `0` filas huérfanas.

---

## 4. Decisiones de Diseño Adoptadas

1. **Refactorización a FNBC y Desnormalización con Triggers (Unidad 4):**
   - Se descompuso `control_lote_almacen` usando el determinante violatorio `responsable_control_id`, garantizando reunión natural sin pérdida (`R1 ⋈ R2 = R`) porque el atributo común es clave primaria de `responsable_deposito` (`R2`).
   - Para el reporte Top-5 categorías se eligió una **tabla resumen mantenida por disparadores dentro de la misma transacción** en lugar de una vista materializada, ya que el requerimiento exigía lectura en tiempo real sin ventana de desfase.
2. **Principio de Mínimo Privilegio y Separación de Roles (Unidad 5):**
   - Se separaron roles de grupo (`NOLOGIN`: `rol_app_lectura`, `rol_app_escritura`, `rol_soporte`, `rol_reportes`) de los roles de inicio de sesión (`app_web`, `admin_datos`). `rol_soporte` solo posee `SELECT (id, nombre, email)` sobre `cliente`, y `app_web` carece de permisos `DELETE` o `DDL`.
3. **Arquitectura Políglota: PostgreSQL + MongoDB + SQLite (Unidades 7 y 8):**
   - **PostgreSQL** se mantiene como **única fuente de verdad transaccional (ACID)** para catálogo maestro, control de stock, precios y confirmación definitiva de pedidos.
   - **MongoDB** se adopta como **proyección documental de lectura** para pedidos históricos cerrados (embebiendo datos del cliente y el arreglo `lineas` con `NumberDecimal`), eliminando el costo de múltiples `JOIN` al consultar comprobantes completos.
   - **SQLite (`STRICT`)** se utiliza en la tablet offline para cachear el catálogo y capturar borradores atómicos en ferias sin conectividad. Los importes viajan como enteros en centavos (`precio_centavos`) para evitar errores de punto flotante, las bajas viajan como lápidas (`eliminado = 1`) para no romper claves foráneas locales, y el semáforo aplica prioridad estricta **Rojo (`RECHAZADO`) > Amarillo (`CONFLICTO`) > Verde (`SIMULADO_APROBADO`)**.

---

## 5. Uso de Herramientas de IA, Decisiones Humanas y Code Review Final

El detalle completo se encuentra en [`BITACORA.md`](../BITACORA.md), [`docs/bitacora_ia.md`](bitacora_ia.md), [`docs/DUIA.md`](DUIA.md) y [`docs/evidencia_revision.md`](evidencia_revision.md). A continuación se sintetizan las intervenciones críticas donde el equipo aceptó, corrigió o descartó propuestas de la IA:

| Unidad / Instancia | Herramienta y Prompt / Spec | Propuesta de la IA | Decisión Humana (`ACEPTADO` / `DESCARTADO` / `CORREGIDO`) y Justificación |
|---|---|---|---|
| **U5 · Auditoría de Permisos** | OpenCode (revisión de `sql/roles.sql` y `.kiro/specs/roles-food-store/`) | Sugirió simplificar permisos otorgando `GRANT ALL PRIVILEGES ON DATABASE food_store TO app_web;`. | **DESCARTADO:** Violaba el principio de mínimo privilegio al darle permisos administrativos y de borrado a la aplicación web. Se mantuvieron grants granulares (`SELECT`, `INSERT`, `UPDATE`). |
| **U7 · Evaluación NoSQL vs. SQL** | OpenCode (comparación MongoDB vs. PostgreSQL en `docs/informe_nosql.md`) | Afirmó que cruzar múltiples colecciones independientes en MongoDB era más eficiente que hacer `JOIN` en PostgreSQL. | **DESCARTADO / REFUTADO:** Se contrastó con la documentación oficial de MongoDB demostrando que `$lookup` es costoso y que MongoDB solo aventaja cuando se lee el agregado embebido completo. |
| **U8 · Code Review Final (sobre U4)** | Asistente IA (revisión de `db/preparar_food_store.sql`) | Sugirió eliminar la columna `subtotal` de `detalle_pedido` alegando que podía desincronizarse de `cantidad * precio_unitario`. | **DESCARTADO:** Se probó en PostgreSQL 18 (`movil/pruebas_revision_postgresql.sql`) que `subtotal` está declarada como `GENERATED ALWAYS AS (cantidad * precio_unitario) STORED`; el motor la recalcula siempre y rechaza escrituras directas con `SQLSTATE 428C9`. |
| **U8 · Code Review Final (sobre U4)** | Asistente IA (revisión de `db/tp_fnbc_control_lote.sql`) | Detectó que un comentario decía que al no cumplir FNBC tampoco cumplía 3FN. | **ACEPTADO Y CORREGIDO:** Como las claves candidatas son `{lote_id, deposito_id}` y `{lote_id, responsable_control_id}`, los 3 atributos son primos; por definición cumple 3FN aunque viole FNBC. Se corrigió en el script. |
| **U8 · Code Review Final (sobre U5)** | Asistente IA (revisión de `sql/roles.sql`) | Advirtió que `fn_autenticar` valida la existencia del email pero no compara el hash de la contraseña. | **ACEPTADO:** Se verificó mediante prueba aislada en `pg_temp` y se documentó explícitamente que `fn_autenticar` es un stub de laboratorio para generar trazas de auditoría en la Unidad 5, debiendo reemplazarse por `pgcrypto` en producción. |
| **U8 · Importación CSV PostgreSQL → SQLite** | Kiro Specs + OpenCode (`movil/cargar_cache.sql`) | En la versión inicial intentó importar los booleanos `t/f` de PostgreSQL directamente sobre columnas enteras `STRICT` de SQLite. | **CORREGIDO:** Se diseñó la tabla de staging `snapshot_servidor` aceptando `'t'/'f'` como texto y convirtiéndolos explícitamente a `1/0` durante el `UPSERT` hacia `producto_cache`. |
