# Tasks: Refactorización FNBC y Desnormalización Controlada — Food Store (Unidad 4)

- [x] Preparar esquema base y carga determinista (`db/preparar_food_store.sql`: 100.000 pedidos y 300.000 líneas).
- [x] Relevar y comprobar dependencias funcionales `FD1` y `FD2` sobre `control_lote_almacen`.
- [x] Demostrar anomalías de inserción, borrado y actualización sobre el esquema heredado.
- [x] Ejecutar descomposición a FNBC (`responsable_deposito` y `control_lote_responsable`) y migración sin pérdida dentro de transacción explícita (`BEGIN ... COMMIT`).
- [x] Verificar equivalencia sin pérdida con `v_control_lote_almacen_compat` y `EXCEPT` en ambos sentidos (0 diferencias).
- [x] Implementar y ensayar el plan de reversión obligatorio en transacción reversible (`BEGIN ... ROLLBACK`).
- [x] Medir plan de ejecución normalizado del reporte Top-5 categorías con `EXPLAIN (ANALYZE, BUFFERS)`.
- [x] Implementar tabla resumen `venta_categoria_dia`, backfill inicial y los 5 disparadores transaccionales de sincronización.
- [x] Medir plan de ejecución desnormalizado (`57,108 ms` -> `0,071 ms`) y verificar auditoría de desincronización (`0` filas).
