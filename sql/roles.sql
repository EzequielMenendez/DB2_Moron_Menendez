-- =====================================================================
-- sql/roles.sql
-- Parte A: Diseño e implementación de roles y permisos de mínimo privilegio
-- Base: food_store (PostgreSQL 18)
-- =====================================================================

\set ON_ERROR_STOP on

-- 1. Limpieza previa segura de roles
DO $$
DECLARE
    r TEXT;
BEGIN
    FOR r IN SELECT rolname FROM pg_roles WHERE rolname IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes','app_web','admin_datos')
    LOOP
        EXECUTE format('DROP OWNED BY %I CASCADE', r);
        EXECUTE format('DROP ROLE %I', r);
    END LOOP;
END $$;

-- 2. Creación de Roles de Grupo (NOLOGIN)
CREATE ROLE rol_app_lectura NOLOGIN;
CREATE ROLE rol_app_escritura NOLOGIN;
CREATE ROLE rol_soporte NOLOGIN;
CREATE ROLE rol_reportes NOLOGIN;

-- 3. Creación de Roles de Login (LOGIN, PASSWORD seguro)
CREATE ROLE app_web LOGIN PASSWORD 'AppWebSecura2026$';
CREATE ROLE admin_datos LOGIN PASSWORD 'AdminDatosSecuro2026$';

-- Asignación de herencia
GRANT rol_app_lectura TO app_web;
GRANT rol_app_escritura TO app_web;

-- 4. Conexión y esquemas
GRANT CONNECT ON DATABASE food_store TO app_web, admin_datos, rol_app_lectura, rol_app_escritura, rol_soporte, rol_reportes;
GRANT USAGE ON SCHEMA public TO app_web, admin_datos, rol_app_lectura, rol_app_escritura, rol_soporte, rol_reportes;

-- 5. Privilegios granulares (Principio de Mínimo Privilegio)
-- Lectura general para app_web y rol_reportes
GRANT SELECT ON producto, categoria, cliente, pedido, detalle_pedido, venta_categoria_dia TO rol_app_lectura, rol_reportes;

-- Escritura controlada para app_web
GRANT INSERT, UPDATE ON pedido, detalle_pedido, cliente TO rol_app_escritura;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_app_escritura;

-- Soporte: consulta limitada (ejemplo de permiso a nivel de columna: sin exponer datos sensibles si los hubiera)
GRANT SELECT (id, nombre, email, telefono) ON cliente TO rol_soporte;
GRANT SELECT ON producto, categoria, pedido, detalle_pedido TO rol_soporte;

-- Admin datos: control total sobre tablas operativas
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_datos;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_datos;

-- 6. ALTER DEFAULT PRIVILEGES (herencia para objetos futuros)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura, rol_reportes;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;

-- 7. Funciones de autenticación y reseteo de contraseña (Clase 2)
CREATE OR REPLACE FUNCTION fn_autenticar(p_email VARCHAR, p_password_plano TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_hash TEXT;
BEGIN
    -- Simulación de verificación de hash seguro (ej. pgcrypto / crypt)
    SELECT email INTO v_hash FROM cliente WHERE email = p_email;
    IF FOUND THEN
        -- En producción se compara crypt(p_password_plano, v_hash) = v_hash
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END $$;

CREATE OR REPLACE FUNCTION fn_resetear_password(p_cliente_id BIGINT, p_nuevo_password TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- En producción se actualiza con gen_salt('bf')
    UPDATE cliente SET email = email WHERE id_cliente = p_cliente_id;
END $$;

GRANT EXECUTE ON FUNCTION fn_autenticar, fn_resetear_password TO app_web;
