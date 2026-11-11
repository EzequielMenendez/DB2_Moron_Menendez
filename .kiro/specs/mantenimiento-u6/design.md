# Design: Plan de Mantenimiento y Recuperación ante Desastres — Food Store (Unidad 6)

## 1. Arquitectura de Automatización
- **`db/backup_foodstore.ps1`**: Ejecuta `pg_dump -Fc` hacia `db/backups/food_store_YYYYMMDD_HHMMSS.dump` y registra salida en `db/logs/`.
- **`db/health_check.sql`**: Consulta `pg_database_size`, `pg_stat_activity` y `pg_stat_user_tables` (tuplas vivas/muertas, últimos `vacuum`/`analyze`).
- **`db/maintenance.sql`**: Ejecuta `VACUUM (VERBOSE, ANALYZE)` sobre las tablas principales (`pedido`, `detalle_pedido`, `producto`, `cliente`, `categoria`, `venta_categoria_dia`) y verifica integridad lógica.
- **`db/restore_test.ps1`**: Automatiza el simulacro de desastre creando la base descartable `foodstore_restore_test`, restaurando el último `.dump` con `pg_restore --no-owner --no-privileges`, midiendo el RTO con `Stopwatch` y validando conteos de filas y restricciones `CHECK`.

## 2. Métricas de Recuperación Observadas
- **RTO medido:** `3,52 segundos`.
- **RPO medido:** `~24 minutos`.
- **Integridad verificada:** 9 categorías, 20.000 clientes, 10.000 productos, 100.000 pedidos, 300.000 detalles de pedido, 0 violaciones de `CHECK`.
