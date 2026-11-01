-- TP8: fixture MINIMA SINTETICA; no es un respaldo de food_store.
-- Ejecutar solamente en una instancia PostgreSQL de pruebas aislada.
-- Los nombres/precio/stock/activo siguen db/preparar_food_store.sql.
-- El esquema original completo no se encuentra versionado en NoSQL.
\set ON_ERROR_STOP on
CREATE SCHEMA tp8_servidor;
CREATE TABLE tp8_servidor.producto (
    id BIGINT PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio NUMERIC(14,2) NOT NULL CHECK (precio >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE tp8_servidor.pedido (
    id BIGINT PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE
);
INSERT INTO tp8_servidor.producto VALUES
    (10, 'Cafe Molido 500g', 4500.00, 10, TRUE),
    (15, 'Azucar 1kg', 1200.00, 5, TRUE);
INSERT INTO tp8_servidor.pedido VALUES (1, '2026-11-01 00:00:00+00', FALSE);

-- Capturar antes de simular; repetir DESPUES (sin preparar otro caso).
SELECT count(*) AS pedidos FROM tp8_servidor.pedido;
SELECT id, precio, stock, activo FROM tp8_servidor.producto ORDER BY id;
