-- =====================================================================
-- preparar_food_store.sql
-- Unidad 4 (FNBC y desnormalización) — Food Store
--
-- Objetivo: dejar la base `food_store` alineada con la consigna del TP
-- y poblada de forma determinista para poder medir con EXPLAIN ANALYZE.
--
--   Sección A  ->  alineación del esquema (idempotente, con guardas)
--   Sección B  ->  carga masiva sintética determinista
--
-- Alineación realizada (solo sobre tablas vacías / renombrado de columnas):
--   1. linea_pedido        -> detalle_pedido   (nombre pedido por la consigna)
--   2. pedido.fecha_hora   -> pedido.fecha     (la consigna usa ped.fecha)
--   3. detalle_pedido.subtotal   (columna GENERADA = cantidad*precio_unitario)
--   4. pedido.eliminado    / detalle_pedido.eliminado   (borrado lógico)
--
-- NOTA: el esquema original de food_store usa los nombres `id`, `categoria_id`,
-- `pedido_id`, `producto_id` (iguales a los de la consigna), por lo que no hace
-- falta renombrar esas columnas.
-- =====================================================================

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- SECCIÓN A — Alineación del esquema (idempotente)
-- ---------------------------------------------------------------------

-- A.1  linea_pedido -> detalle_pedido
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name='linea_pedido')
       AND NOT EXISTS (SELECT 1 FROM information_schema.tables
                       WHERE table_schema='public' AND table_name='detalle_pedido') THEN
        ALTER TABLE linea_pedido RENAME TO detalle_pedido;
        ALTER INDEX linea_pedido_pkey RENAME TO detalle_pedido_pkey;
        ALTER INDEX idx_linea_producto RENAME TO idx_detalle_producto;
        ALTER TABLE detalle_pedido
            RENAME CONSTRAINT linea_pedido_pedido_id_fkey TO detalle_pedido_pedido_id_fkey;
        ALTER TABLE detalle_pedido
            RENAME CONSTRAINT linea_pedido_producto_id_fkey TO detalle_pedido_producto_id_fkey;
        ALTER TABLE detalle_pedido
            RENAME CONSTRAINT linea_pedido_cantidad_check TO detalle_pedido_cantidad_check;
        ALTER TABLE detalle_pedido
            RENAME CONSTRAINT linea_pedido_precio_unitario_check TO detalle_pedido_precio_unitario_check;
        ALTER TABLE detalle_pedido
            RENAME CONSTRAINT chk_linea_pedido_cantidad_maxima TO chk_detalle_cantidad_maxima;
    END IF;
END $$;

-- A.2  pedido.fecha_hora -> pedido.fecha
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='pedido' AND column_name='fecha_hora') THEN
        ALTER TABLE pedido RENAME COLUMN fecha_hora TO fecha;
    END IF;
END $$;

-- A.3  detalle_pedido.subtotal  (columna GENERADA almacenada, no puede desincronizarse)
ALTER TABLE detalle_pedido
    ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14,2)
        GENERATED ALWAYS AS (cantidad * precio_unitario) STORED;

-- A.4  eliminado (borrado lógico) en pedido y detalle_pedido
ALTER TABLE pedido
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE detalle_pedido
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

-- A.5  Índice de apoyo para el reporte "del día" (pedido.fecha filtrada)
CREATE INDEX IF NOT EXISTS idx_pedido_fecha ON pedido (fecha)
    WHERE NOT eliminado;

-- ---------------------------------------------------------------------
-- SECCIÓN B — Carga masiva sintética determinista
--     8 categorías / 10.000 productos / 20.000 clientes
--     100.000 pedidos (98.500 históricos + 1.500 de hoy)
--     300.000 líneas de detalle (3 por pedido)
-- ---------------------------------------------------------------------

-- B.0  Limpieza de los objetos de la Parte 2: si la reejecución corre después
--      del script de desnormalización, se quitan los disparadores y el resumen
--      para que la carga masiva no los dispare fila por fila.
DROP TRIGGER IF EXISTS trg_dp_ai  ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_dp_au  ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_dp_ad  ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_ped_au ON pedido;
DROP TRIGGER IF EXISTS trg_prod_au ON producto;
DROP TABLE IF EXISTS venta_categoria_dia CASCADE;

SELECT setseed(0.42);   -- reproducibilidad de los valores aleatorios

-- Limpieza previa (el orden respeta las FK). CASCADE limpia también
-- la tabla resumen que crea el script de la Parte 2 si ya existiera.
TRUNCATE TABLE detalle_pedido, pedido, cliente, producto, categoria
    RESTART IDENTITY CASCADE;

-- B.1  categorías
INSERT INTO categoria (nombre, descripcion) VALUES
    ('Bebidas',        'Gaseosas, jugos y aguas'),
    ('Lácteos',        'Leche, queso y yogur'),
    ('Snacks',         'Aperitivos y galletitas'),
    ('Limpieza',       'Aseo del hogar'),
    ('Congelados',     'Helados y productos congelados'),
    ('Panadería',      'Pan y pastelería'),
    ('Carnes',         'Carnes rojas y blancas'),
    ('Frutas y Verduras', 'Productos frescos');

-- B.2  clientes  (ids de identidad 1..20000)
INSERT INTO cliente (nombre, apellido, email)
SELECT 'Cliente' || g, 'Apellido' || g, 'cliente' || g || '@mail.com'
FROM generate_series(1, 20000) AS g;

-- B.3  productos (ids 1..10000; categoría = 1 + (g % 8))
INSERT INTO producto (nombre, descripcion, precio, stock, activo, categoria_id)
SELECT 'Producto ' || g,
       'Descripción del producto ' || g,
       round((5 + random() * 495)::numeric, 2),
       (random() * 200)::int,
       TRUE,
       1 + (g % 8)
FROM generate_series(1, 10000) AS g;

-- B.4  pedidos históricos (98.500 entre el 2026-01-01 y ayer)
INSERT INTO pedido (fecha, cliente_id, forma_pago, eliminado)
SELECT (TIMESTAMPTZ '2026-01-01 00:00:00-03'
        + (random()
           * EXTRACT(EPOCH FROM (now() - INTERVAL '1 day'
                                      - TIMESTAMPTZ '2026-01-01 00:00:00-03')))
          * INTERVAL '1 second'),
       1 + (g % 20000),
       (ARRAY['EFECTIVO','TARJETA','TRANSFERENCIA'])[1 + floor(random()*3)::int]
           ::forma_pago,
       FALSE
FROM generate_series(1, 98500) AS g;

-- B.5  pedidos de HOY (1.500, con hora entre 00:00 y ahora, para el top-5 del día)
INSERT INTO pedido (fecha, cliente_id, forma_pago, eliminado)
SELECT (current_date::timestamptz
        + random() * (now() - current_date::timestamptz)),
       1 + (g % 20000),
       (ARRAY['EFECTIVO','TARJETA','TRANSFERENCIA'])[1 + floor(random()*3)::int]
           ::forma_pago,
       FALSE
FROM generate_series(1, 1500) AS g;

-- B.6  líneas de detalle: 3 por pedido, producto determinista, precio real del
--      producto (el subtotal lo calcula sola la columna GENERADA).
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, eliminado)
SELECT p.id,
       1 + ((p.id * 31 + s * 17) % 10000),
       1 + ((p.id + s) % 5),
       pr.precio,
       FALSE
FROM pedido AS p
CROSS JOIN generate_series(1, 3) AS s
JOIN producto AS pr
  ON pr.id = 1 + ((p.id * 31 + s * 17) % 10000);

-- ---------------------------------------------------------------------
-- Verificación de la carga
-- ---------------------------------------------------------------------
SELECT 'categoria'  AS tabla, count(*) FROM categoria
UNION ALL SELECT 'cliente',   count(*) FROM cliente
UNION ALL SELECT 'producto',  count(*) FROM producto
UNION ALL SELECT 'pedido',    count(*) FROM pedido
UNION ALL SELECT 'pedido hoy', count(*) FROM pedido WHERE fecha::date = CURRENT_DATE
UNION ALL SELECT 'detalle_pedido', count(*) FROM detalle_pedido
ORDER BY 1;
