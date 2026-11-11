# Trazabilidad del Flujo Specs (Kiro) y Generación (OpenCode) · TP8

**Proyecto:** Food Store — Segunda Entrega Parcial (Unidad 8: Bases de datos móviles e integración)
**Equipo:** Morón / Menéndez

Se documenta el flujo completo de especificación estructurada (Specs de Kiro: [requirements.md](requirements.md), [design.md](design.md) y [tasks.md](tasks.md), espejados en `.kiro/specs/movil-sqlite-sync/`) y la generación y validación de artefactos con OpenCode y pruebas automatizadas.

## 1. Prompt de Especificación (Fase de Requisitos y Diseño en Kiro)

> "Actuando como Arquitecto de Bases de Datos, prepará la especificación estructurada (Requirements en formato EARS, Design y Tasks) para la Unidad 8 de Food Store (operación offline en feria con SQLite y sincronización simulada contra PostgreSQL). Redactá cuatro requisitos EARS trazables a los casos de aceptación C1–C7. PostgreSQL conserva la autoridad sobre precios, stock y ventas; SQLite consulta un catálogo cacheado (`producto_cache`) y almacena borradores (`pedido_borrador`, `item_borrador`, `cola_sync`) usando tablas `STRICT`, claves foráneas activadas por conexión, precios enteros en centavos (`precio_centavos`), transacciones atómicas e importación de instantáneas CSV con booleanos `t/f` y conservación de lápidas (baja lógica). El semáforo procesa solo solicitudes `PENDIENTE`: prioriza condiciones de rechazo (`RECHAZADO`) antes que cambios de precio (`CONFLICTO`), y cuando hay coincidencia total asigna `SIMULADO_APROBADO` sin confirmar venta ni descontar stock en el servidor."

## 2. Matriz de Requisitos EARS y Casos de Prueba

| ID | Requisito EARS | Caso de aceptación |
|---|---|---|
| **REQ-01** | WHEN la tablet opere sin conexión THE SYSTEM SHALL consultar el catálogo local y guardar borrador, ítems y solicitud atómicamente. | C1 y C7; `COMMIT` / `ROLLBACK`. |
| **REQ-02** | WHEN una solicitud `PENDIENTE` contenga producto ausente, no disponible, eliminado o con stock insuficiente THE SYSTEM SHALL marcar `RECHAZADO` con prioridad sobre cambios de precio. | C3 y C4; bordes de ausencia, indisponibilidad y prioridad roja sobre amarilla. |
| **REQ-03** | WHEN no haya rechazo y cambie un precio THE SYSTEM SHALL marcar `CONFLICTO`; WHEN se acepte el precio THE SYSTEM SHALL conservar la solicitud anterior y evaluar otra con UUID nuevo. | C2, incluida la resolución por aceptación y reenvío con nuevo UUID. |
| **REQ-04** | WHEN todos los ítems coincidan THE SYSTEM SHALL marcar `SIMULADO_APROBADO` sin confirmar ventas; WHEN se repita un UUID THE SYSTEM SHALL impedir duplicados y no reevaluar estados finales. | C5 y C6. |

## 3. Decisiones de Diseño Validadas por el Equipo

1. **Separación de responsabilidades entre motores:** PostgreSQL es la fuente de verdad transaccional, MongoDB actúa como proyección documental de lectura para pedidos cerrados (Unidad 7), y SQLite opera como almacenamiento local en la tablet para captura de borradores offline.
2. **Esquema `STRICT` y aritmética exacta:** `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync` utilizan tablas `STRICT` con restricciones `CHECK` y `FOREIGN KEY`, almacenando importes en centavos enteros (`precio_centavos`) para evitar errores de punto flotante.
3. **Staging CSV y lápidas (tombstones):** El archivo CSV exportado desde `tp8_servidor.v_snapshot_movil` se carga en `snapshot_servidor` con valores `t/f`; `cargar_cache.sql` los transforma explícitamente a `1/0` mediante `UPSERT` y conserva las filas dadas de baja (`eliminado = 1`) para no romper las claves foráneas de los borradores ya registrados.
4. **Semáforo determinista:** `semaforo.sql` evalúa todos los ítems por solicitud `PENDIENTE` priorizando rechazos (`RECHAZADO`) sobre conflictos de precio (`CONFLICTO`), y solo otorga `SIMULADO_APROBADO` cuando la totalidad de las líneas coincide con la instantánea.
5. **Trazabilidad en resolución de conflictos:** Al aceptar un cambio de precio en C2, se actualiza `precio_centavos_visto` en `item_borrador` y se inserta una nueva solicitud en `cola_sync` con un nuevo UUID, manteniendo inmutable el registro histórico del `CONFLICTO` previo.

## 4. Tareas de Implementación y Evidencia Verificada

| Tarea | Artefacto | Evidencia verificada |
|---|---|---|
| Esquema SQLite e integridad | `movil/schema_sqlite.sql` | Caso C7 y tests de restricciones `CHECK` y `FK`. |
| Recarga de catálogo y lápidas | `movil/cargar_cache.sql` | Casos C1 y C4 (`docs/evidencia_casos.md`). |
| Semáforo de sincronización | `movil/semaforo.sql` | Casos C2–C6 y precedencia roja (`test_red_precedes_yellow`). |
| Transacciones y pruebas SQL | `movil/pruebas_sqlite.sql` | `COMMIT`/`ROLLBACK` y suite `python -m unittest discover -s movil/tests -v` (25/25 OK). |
| Instantáneas PostgreSQL | `movil/snapshot_postgresql.sql` | Verificación de invariancia de stock, precios y pedidos en `docs/evidencia_postgresql.md`. |
| Code review integral (U4–U8) | `movil/pruebas_revision_postgresql.sql` | Decisiones humanas documentadas en `docs/evidencia_revision.md`. |
