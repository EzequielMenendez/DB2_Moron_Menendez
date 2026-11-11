# TP8 · Food Store en la feria (Unidad 8: Bases de datos móviles e integración)

Base de Datos II · UTN · Ciclo 2026
Equipo: Morón / Menéndez · Referencia: rama `NoSQL` · Trabajo: rama `sqlite`

## 1. Base de la tablet y selección de datos

La tablet consulta un catálogo local y registra borradores durante una feria sin conexión. Un resultado `SIMULADO_APROBADO` solamente indica que el borrador coincide con la instantánea: no confirma una venta ni reserva unidades. PostgreSQL conserva la autoridad sobre precios, existencias y pedidos definitivos.

| Dato | Viaja | Uso en la tablet |
|---|---|---|
| `producto.id`, `nombre` | Sí | Identificar y mostrar el producto. |
| `precio` | Sí, como `precio_centavos` entero | Guardar el importe visto sin aritmética de coma flotante. |
| `stock` | Sí, como referencia | Advertir disponibilidad; nunca constituye una reserva. |
| `activo`, baja lógica | Sí | Disponibilidad y lápidas; distinguir baja de ausencia. |
| Fecha de copia | Sí | Informar antigüedad de la instantánea. |
| Usuarios, contraseñas, correo y datos de clientes | No | No son necesarios para el catálogo offline. |
| Pedidos confirmados y datos de auditoría | No | Permanecen bajo control del servidor. |

El campo local `usuario` es un alias sintético de operador, sin información personal. Solo se usan productos y pedidos inventados. Las columnas del contrato móvil se adaptan al esquema de referencia: `activo` aporta disponibilidad y la marca de eliminación representa una baja lógica.

`movil/schema_sqlite.sql` activa las claves foráneas y define `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync` como tablas `STRICT`. `CHECK` restringe importes, cantidades, pagos, indicadores y estados; las `FK` evitan ítems huérfanos. La tabla auxiliar `snapshot_servidor` recibe el CSV del servidor, incluyendo booleanos `t` y `f`.

El borrador completo se guarda mediante una transacción que incluye cabecera, ítems y solicitud. Si una operación falla, se revierte la unidad completa. `pruebas_sqlite.sql` muestra `COMMIT`, `ROLLBACK`, catálogo offline y errores intencionales C7; las pruebas automatizadas verifican que esos errores no dejan filas adicionales.

<!-- pagebreak -->

## 2. Instantánea, semáforo y casos

La vista `v_snapshot_movil` produce el contrato `id,nombre,precio_centavos,stock,disponible,eliminado,fecha_copia`. Se exporta desde PostgreSQL con `\copy` y se importa a `snapshot_servidor`. La recarga convierte `t/f` a `1/0` y conserva las lápidas en `producto_cache`; el catálogo filtra los productos dados de baja. La instantánea base fue exportada el 01/11/2026 a las 19:45:35 UTC; la fecha queda en el CSV y en la base entregada. PostgreSQL se probó sobre una fixture mínima sintética aislada (`tp8_servidor`).

El semáforo compara todos los ítems de cada solicitud `PENDIENTE`. Primero rechaza inexistencia, baja, indisponibilidad o stock insuficiente; solo si no hay problemas rojos considera cambios de precio. Coincidencia total produce `SIMULADO_APROBADO`. Las solicitudes resueltas quedan fuera de las siguientes ejecuciones.

Comando de verificación local desde la raíz: `python -m unittest discover -s movil/tests -v`. Los comandos individuales, exportaciones y salidas reales se conservan en `docs/evidencia_casos.md` y `docs/evidencia_postgresql.md`.

| Caso | Preparación y operación | Resultado que se verifica |
|---|---|---|
| C1 | Consultar cache sin conexión PostgreSQL. | Catálogo local disponible. |
| C2 | Crear borrador, subir precio en copia del servidor, exportar y evaluar. Aceptar precio y enviar UUID nuevo. | `CONFLICTO`; después `SIMULADO_APROBADO`. |
| C3 | Pedir más unidades que el stock de la instantánea. | `RECHAZADO`. |
| C4 | Dar de baja el producto después del borrador, exportar y recargar cache. | `RECHAZADO`; desaparece del catálogo y permanece su fila (lápida). |
| C5 | Enviar borrador sin modificaciones del servidor. | `SIMULADO_APROBADO`. |
| C6 | Repetir UUID y ejecutar nuevamente el semáforo. | Error de PK; cantidad de solicitudes y resultado previo conservados. |
| C7 | Insertar cantidad cero y producto inexistente. | Errores `CHECK` y `FK`; conteos sin cambios. |

En C2 el cambio aceptado se aplica al precio visto del ítem, sin sobrescribir el precio del servidor. La solicitud previa conserva su resultado; el reintento usa otro UUID. En C4 la lápida impide confundir un artículo eliminado con uno habilitado y mantiene la referencia del borrador.

C6 demuestra idempotencia de esta simulación local. En un sistema real, la clave idempotente se controla también en el servidor con una restricción única y una transacción que guarda la respuesta junto con la operación definitiva. La PK de una tablet no protege por sí sola contra reenvíos desde otros dispositivos.

La comparación PostgreSQL antes/después fue ejecutada tras la simulación: `pedidos=1`; producto 10, `stock=10` y `precio=4500.00`; producto 15, `stock=5` y `precio=1200.00`. Los valores permanecieron idénticos.

<!-- pagebreak -->

## 3. Integración y mantenimiento

### Mapa de los tres motores

| Motor | Datos y función | Autoridad |
|---|---|---|
| PostgreSQL | Productos, precios, stock, clientes, pedidos y detalles; restricciones y transacciones. | Fuente de verdad operativa. |
| MongoDB, Unidad 7 | `foodstore_nosql.pedidos`: documentos con `_id`, estado, cliente embebido, arreglo `lineas` y total con `NumberDecimal`; cinco pedidos reales (IDs 1–5) en `sql/consultas_mongodb.js`. | Proyección documental para consultas. No reemplaza las validaciones operativas. |
| SQLite, Unidad 8 | Cache del catálogo, borradores, ítems y cola con resultados de simulación. | Autoridad sobre el borrador local; sus precios y stock son referencias. |

Los identificadores permiten relacionar representaciones. El modelo MongoDB del repositorio favorece la lectura de un pedido completo; la simulación SQLite valida borradores offline contra la instantánea sin registrar ventas definitivas ni modificar documentos en MongoDB.

### Extensión del plan de mantenimiento de la Unidad 6 a los tres motores

- **PostgreSQL:** respaldo diario con `pg_dump -Fc` (`db/backup_foodstore.ps1`), retención y copia protegida fuera del equipo. Simulacro semanal de restauración en instancia descartable (`db/restore_test.ps1`); compara conteos, restricciones `CHECK`, una muestra de pedidos y stock, registrando duración (RTO observado: `3,52 s`) y antigüedad real del respaldo (RPO observado: `~24 min`).
- **MongoDB:** si se conserva una proyección no reconstruible, respaldarla con `mongodump` y probar su restauración con `mongorestore`. Si deriva de PostgreSQL, reconstruir la proyección documental y verificar coincidencia de identificadores e importes `NumberDecimal`.
- **SQLite:** el catálogo (`producto_cache`) se reconstruye importando una nueva instantánea. Los borradores (`pedido_borrador`, `item_borrador`) y la cola (`cola_sync`) requieren copia consistente con la API de respaldo de SQLite o con la aplicación cerrada, verificando `PRAGMA integrity_check` y `PRAGMA foreign_key_check` al restaurar.
- **Restauración ante punto anterior del servidor:** detener envíos, conservar los borradores locales y renovar la instantánea completa. Reconciliar contra el servidor restaurado antes de emitir nuevas solicitudes.
- **Gestión operativa de conflictos:** el encargado de feria revisa las solicitudes en estado `CONFLICTO` o `RECHAZADO` al recuperar conexión y antes de cada cierre diario; el cliente debe aceptar el nuevo precio o ajustar el borrador, generando un nuevo UUID al reenviar.

<!-- pagebreak -->

## 4. Code Review final de los scripts de la cursada asistido por IA

Alcance revisado: `db/preparar_food_store.sql`, `db/tp_fnbc_control_lote.sql`, `db/tp_desnormalizacion_top_categorias.sql`, `db/maintenance.sql`, `db/health_check.sql`, `db/backup_foodstore.ps1`, `db/restore_test.ps1`; `sql/roles.sql`, `sql/usuario_anon.sql`, `sql/simulacro_incidente.sql`, `sql/auditoria_test.sql`, `sql/consultas_postgresql.sql`, `sql/consultas_mongodb.js` y todos los scripts móviles en `movil/`.

| Hallazgo de la IA | Unidad / Decisión humana | Fundamento técnico y comprobación |
|---|---|---|
| «Eliminar `subtotal` de `detalle_pedido` porque puede desincronizarse de `cantidad` y `precio_unitario`». | **U4 · DESCARTADO** | Es una columna `GENERATED ALWAYS AS (cantidad * precio_unitario) STORED`: el motor la recalcula automáticamente y bloquea cualquier escritura manual. Comprobado en PostgreSQL 18 (`2 × 4500 = 9000`; `UPDATE cantidad = 3` → `13500`; sobrescribir `subtotal` falla con `SQLSTATE 428C9`). Véase `docs/evidencia_revision.md`. |
| «`fn_autenticar` acepta cualquier contraseña para un correo existente». | **U5 · ACEPTADO** | La función en `sql/roles.sql` se diseñó como stub para generar trazas en el laboratorio de auditoría de la Unidad 5 y no evalúa el hash de la contraseña. Se documenta que en producción debe validar un hash criptográfico (`crypt`/`pgcrypto`). |
| «Tratar `t/f` del CSV como enteros directamente al importar en SQLite». | **U8 · CORREGIDO** | Se conserva el texto `'t'/'f'` en la tabla de staging `snapshot_servidor` y se transforma explícitamente a `1/0` en `movil/cargar_cache.sql`. Verificado con pruebas automatizadas para filas activas y dadas de baja. |
| «El comentario en Unidad 4 afirmaba que no cumplir FNBC implicaba no cumplir 3FN». | **U4 · CORREGIDO** | En `control_lote_almacen` las claves candidatas son `{lote_id, deposito_id}` y `{lote_id, responsable_control_id}`; como sus tres atributos son primos, la relación cumple 3FN aunque viole FNBC. Se corrigió el comentario en `db/tp_fnbc_control_lote.sql`. |
| «Parametrizar credenciales en scripts de laboratorio de U5 y validar todos los códigos nativos en PowerShell». | **U5/U6 · ACEPTADO** | Se documenta la recomendación para entornos productivos usando variables de entorno (`.env.example` / `PGPASSWORD`) sin exponer secretos en repositorios públicos. |

<!-- pagebreak -->

## 5. Trazabilidad, uso de IA y preparación de la defensa

- **Especificaciones en Kiro:** `.kiro/specs/movil-sqlite-sync/` y `docs/kiro/` (`requirements.md`, `design.md`, `tasks.md` y trazabilidad en `simulacion_kiro.md`) relacionan los 4 requisitos EARS con los casos C1–C7.
- **Evidencia de pruebas y TDD:** `docs/evidencia_tdd.md`, `docs/evidencia_casos.md`, `docs/evidencia_postgresql.md` y `docs/evidencia_revision.md` registran las 25 pruebas automatizadas en verde (`python -m unittest discover -s movil/tests -v`).
- **Bitácora de IA y DUIA:** `BITACORA.md`, `docs/bitacora_ia.md` y `docs/DUIA.md` consolidan los prompts, propuestas aceptadas y propuestas descartadas con justificación técnica en las Unidades 4 a 8.
- **Guion de defensa:** `docs/defensa_tp8.md` detalla la estructura de exposición de 10 minutos (mapa de motores, demostración en vivo de conflicto de precio C2 y resolución con nuevo UUID, y justificación de los hallazgos del code review).
