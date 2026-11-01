-- Revisiones aisladas U4/U5; no ejecutar sql/roles.sql completo.
\set ON_ERROR_STOP on
BEGIN;
CREATE TEMP TABLE detalle_revision (
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(12,2) NOT NULL,
    subtotal NUMERIC(12,2) GENERATED ALWAYS AS
        (cantidad * precio_unitario) STORED
);
INSERT INTO detalle_revision(cantidad, precio_unitario) VALUES (2, 4500);
SELECT cantidad, precio_unitario, subtotal FROM detalle_revision;
UPDATE detalle_revision SET cantidad = 3;
SELECT cantidad, precio_unitario, subtotal FROM detalle_revision;
DO $$ BEGIN
    BEGIN
        UPDATE detalle_revision SET subtotal = 1;
        RAISE EXCEPTION 'ERROR: se permitio editar subtotal generado';
    EXCEPTION WHEN generated_always THEN
        RAISE NOTICE 'U4 OK: subtotal no admite un valor explicito (SQLSTATE 428C9)';
    END;
END $$;

-- Reproduccion EXACTA del cuerpo fn_autenticar de sql/roles.sql.
-- TEMP tabla y funcion pg_temp: no modifica autenticacion real ni roles.
CREATE TEMP TABLE cliente(email VARCHAR);
INSERT INTO cliente VALUES ('cliente-sintetico@example.invalid');
CREATE FUNCTION pg_temp.fn_autenticar(p_email VARCHAR, p_password_plano TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_hash TEXT;
BEGIN
    SELECT email INTO v_hash FROM cliente WHERE email = p_email;
    IF FOUND THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END $$;
SELECT pg_temp.fn_autenticar('cliente-sintetico@example.invalid', 'prueba-a') AS clave_a,
       pg_temp.fn_autenticar('cliente-sintetico@example.invalid', 'prueba-b') AS clave_b,
       pg_temp.fn_autenticar('inexistente@example.invalid', 'prueba-a') AS inexistente;
ROLLBACK;
