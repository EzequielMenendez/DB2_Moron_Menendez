-- =====================================================================
-- db/maintenance.sql
-- Parte 3: Mantenimiento y optimización justificada en Food Store
-- =====================================================================

\echo '=== REVISIÓN PREVIA DE ESTADÍSTICAS Y VACUUM ==='
SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables;

-- Mantenimiento seguro y justificado:
-- Se ejecuta ANALYZE manual sobre tablas críticas con alta tasa de modificaciones
-- (como detalle_pedido y pedido) para actualizar las estadísticas del optimizador
-- de consultas (cost-based optimizer), previniendo planes de ejecución subóptimos.
-- NOTA: No se utiliza VACUUM FULL ya que bloquea exclusivamente las tablas y requiere
-- espacio en disco adicional; el autovacuum nativo maneja eficientemente las tuplas muertas.

\echo '=== EJECUTANDO ANALYZE PREVENTIVO SOBRE TABLAS CLAVE ==='
ANALYZE VERBOSE detalle_pedido;
ANALYZE VERBOSE pedido;
ANALYZE VERBOSE producto;

\echo '=== MANTENIMIENTO FINALIZADO Y ESTADÍSTICAS ACTUALIZADAS ==='
