# Design: Tablet Offline SQLite y Simulación de Sincronización — Food Store (Unidad 8)

## 1. Arquitectura Multi-Motor y Autoridad de Datos
- **PostgreSQL (Servidor central):** Fuente de verdad operativa sobre precios, stock y pedidos confirmados. Exporta el contrato móvil mediante la vista `tp8_servidor.v_snapshot_movil` (`movil/snapshot_postgresql.sql`).
- **MongoDB (Proyección documental U7):** Colección `foodstore_nosql.pedidos` con documentos embebidos para lectura rápida de pedidos cerrados; no interviene en la captura offline de la feria.
- **SQLite (Tablet offline U8):** Guarda el catálogo cacheado y los borradores capturados sin conexión (`movil/schema_sqlite.sql`). Un estado `SIMULADO_APROBADO` valida la coincidencia contra la instantánea pero no confirma venta ni reserva stock.

## 2. Esquema SQLite (`STRICT`) y Reglas de Integridad
- Cuatro tablas `STRICT`: `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync`, más la tabla auxiliar de staging `snapshot_servidor` para importación CSV (`t/f`, precios enteros en centavos `precio_centavos`, stock y `fecha_copia` ISO).
- Claves foráneas activadas por conexión (`PRAGMA foreign_keys = ON`).
- Clave compuesta en `item_borrador` que impide duplicar un mismo producto dentro de un borrador.
- Conservación de lápidas (baja lógica): `movil/cargar_cache.sql` aplica `UPSERT` desde `snapshot_servidor`, convierte `t/f` a `1/0` y marca como eliminados los productos dados de baja o ausentes sin borrar físicamente la fila en `producto_cache`, preservando la integridad referencial de los borradores históricos.

## 3. Semáforo de Sincronización (`movil/semaforo.sql`)
- Evalúa todos los ítems agrupados por cada solicitud en estado `PENDIENTE`.
- **Prioridad Roja (`RECHAZADO`):** Producto inexistente, eliminado (`eliminado = 1`), no disponible (`disponible = 0`), stock insuficiente (`cantidad > stock`) o borrador sin ítems.
- **Prioridad Amarilla (`CONFLICTO`):** Sin condiciones rojas, pero `precio_centavos != precio_centavos_visto`. La resolución actualiza `precio_centavos_visto` del ítem y encola una nueva solicitud con un nuevo `solicitud_uuid`, preservando la traza de la solicitud previa en `CONFLICTO`.
- **Prioridad Verde (`SIMULADO_APROBADO`):** Coincidencia total de disponibilidad, stock y precio.
- **Idempotencia:** La PK `solicitud_uuid` en `cola_sync` rechaza reenvíos duplicados y el filtro `WHERE estado = 'PENDIENTE'` evita reevaluar solicitudes ya resueltas.
