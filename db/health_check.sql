-- =====================================================================
-- db/health_check.sql
-- Parte 3: Controles de salud y monitoreo para Food Store (PostgreSQL 16+)
-- =====================================================================

\echo '=== 1. TAMAÑO DE LA BASE DE DATOS ==='
SELECT pg_size_pretty(pg_database_size('food_store')) AS tamano_db;

-- 2. ACTIVIDAD DE CONEXIONES Y TRANSACCIONES
\echo '=== 2. ACTIVIDAD DE CONEXIONES ==='
SELECT numbackends AS conexiones_activas,
       xact_commit AS commits_exitosos,
       xact_rollback AS rollbacks
FROM pg_stat_database
WHERE datname = 'food_store';

-- 3. ESTADO DE TABLAS Y TUPLAS MUERTAS (necesidad de vacuum)
\echo '=== 3. ESTADO DE TABLAS Y TUPLAS MUERTAS ==='
SELECT relname AS tabla,
       n_live_tup AS tuplas_vivas,
       n_dead_tup AS tuplas_muertas,
       round(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0), 2) AS porcentaje_muertas,
       last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- 4. CONSULTAS ACTIVAS (excluyendo idle)
\echo '=== 4. CONSULTAS ACTIVAS ==='
SELECT pid,
       usename AS usuario,
       state,
       now() - query_start AS duracion,
       query
FROM pg_stat_activity
WHERE datname = 'food_store'
  AND state <> 'idle'
  AND pid <> pg_backend_pid();
