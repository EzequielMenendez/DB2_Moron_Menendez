-- =====================================================================
-- sql/usuario_anon.sql
-- Parte D: Anonimización de datos de clientes/usuarios y verificación de equivalencia
-- =====================================================================

\set ON_ERROR_STOP on

DROP TABLE IF EXISTS cliente_anon CASCADE;

-- 1. Construcción de la tabla anonimizada con datos sintéticos deterministas
CREATE TABLE cliente_anon AS
SELECT 
    id AS id,
    'Cliente_' || md5(id::text) AS nombre_anon,
    'Apellido_' || md5(id::text) AS apellido_anon,
    'user_' || id || '@anon.local' AS email_anon,
    id AS fecha_alta -- o columna de fecha equivalente si existe en cliente
FROM cliente;

-- Consultas de agregación para equivalencia
SELECT count(*) AS total_real FROM cliente;
SELECT count(*) AS total_anon FROM cliente_anon;
