-- =====================================================================
-- sql/simulacro_incidente.sql
-- Parte C: Simulacro de incidente de acceso indebido
-- =====================================================================

\set ON_ERROR_STOP off

-- 1. Varios intentos fallidos de inicio de sesión
SELECT fn_autenticar('atacante1@mail.com', 'badpass1');
SELECT fn_autenticar('atacante1@mail.com', 'badpass2');
SELECT fn_autenticar('atacante1@mail.com', 'badpass3');

-- 2. Inicio de sesión exitoso (simulado)
SELECT fn_autenticar('cliente1@mail.com', 'passwordCorrecto');

-- 3. Lectura masiva de la tabla cliente / usuario
SELECT * FROM cliente LIMIT 500;

-- 4. Intento de escalamiento de privilegios (ejecutar operación reservada a admin_datos o dar permisos)
-- Nota: como rol sin privilegios DDL, esto debe FALLAR por el esquema de permisos de la Parte A.
GRANT admin_datos TO rol_app_lectura;
