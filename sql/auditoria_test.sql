-- =====================================================================
-- sql/auditoria_test.sql
-- Parte B: Secuencia de operaciones de prueba para generar log de auditoría
-- =====================================================================

\set ON_ERROR_STOP off

-- 1. Intento de inicio de sesión fallido (contra fn_autenticar)
SELECT fn_autenticar('inexistente@mail.com', 'clavemala');

-- 2. Lectura (SELECT)
SELECT count(*) FROM producto WHERE activo = TRUE;

-- 3. Inserción (INSERT) - usando admin_datos o postgres
INSERT INTO categoria (nombre, descripcion) VALUES ('Categoría Auditoría', 'Test log');

-- 4. Actualización (UPDATE)
UPDATE categoria SET descripcion = 'Test log actualizado' WHERE nombre = 'Categoría Auditoría';
