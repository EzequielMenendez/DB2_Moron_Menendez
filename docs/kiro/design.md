# Diseño TP8

PostgreSQL es autoridad; SQLite guarda catálogo cacheado y borradores con identificadores UUID ficticios. MongoDB conserva la proyección documental de Unidad 7 y no interviene en la simulación.

Cuatro tablas STRICT: producto_cache, pedido_borrador, item_borrador y cola_sync. snapshot_servidor es la tabla auxiliar de importación CSV: booleanos t/f, centavos enteros, stock y fecha_copia ISO. Las FK se activan por conexión. Una clave compuesta impide duplicar un producto dentro de un borrador. No se borra físicamente el producto cacheado para no invalidar referencias.

cargar_cache.sql aplica una instantánea completa con UPSERT, conserva lápidas y marca como eliminado lo ausente. semaforo.sql agrupa por solicitud; rojo precede amarillo y verde. Solicitudes sin ítems se rechazan de forma conservadora. Solo se actualizan PENDIENTE. El resultado es una simulación, nunca una venta ni una reserva.

Sincronizar no abre conexión de escritura a PostgreSQL: se consume un CSV exportado de una copia sintética aislada. La simulación no resuelve concurrencia real; una API real debería validar y confirmar en una transacción en PostgreSQL y persistir una clave de idempotencia única.
