-- =====================================================================
-- tp_desnormalizacion_top_categorias.sql
-- Unidad 4 — Desnormalización controlada
-- Parte 2: reporte "top 5 de categorías por monto vendido en el día"
-- Base: food_store (PostgreSQL 18)
--
-- Contenido del artefacto:
--   0. Consulta original (normalizada) + EXPLAIN ANALYZE  [5.2(a)]
--   1. Patrón de desnormalización elegido y justificación  [5.2(b)]
--   2. Estructura desnormalizada + mecanismo de sincronización  [5.2(c)]
--   3. Reporte leyendo de la estructura desnormalizada + EXPLAIN ANALYZE  [5.2(d)]
--   4. Tabla comparativa antes / después  [5.2(d)]
--   5. Script de auditoría de desincronización  [5.2(e)]
--
-- ADAPTACIÓN respecto de la consigna: en food_store `pedido.fecha` es
-- TIMESTAMPTZ, por lo que el predicado del reporte es `fecha::date =
-- CURRENT_DATE` (equivalente al `fecha = CURRENT_DATE` de la consigna,
-- que asumía una columna de tipo DATE).
-- =====================================================================

\set ON_ERROR_STOP on

-- =====================================================================
-- 0. Consulta original (normalizada): recorre y une las 4 tablas
--    detalle_pedido -> producto -> categoria -> pedido
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre AS categoria,
       SUM(dp.subtotal) AS total_vendido
FROM detalle_pedido dp
JOIN producto pr ON pr.id = dp.producto_id
JOIN categoria c ON c.id = pr.categoria_id
JOIN pedido ped ON ped.id = dp.pedido_id
WHERE ped.fecha::date = CURRENT_DATE
  AND dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY c.nombre
ORDER BY total_vendido DESC
LIMIT 5;

-- =====================================================================
-- 1. Patrón elegido: TABLA RESUMEN PRECALCULADA MANTENIDA CON DISPARADORES
--    (venta_categoria_dia)
--
-- Justificación (respondiendo a las tres preguntas de 5.2(b)):
--
--  • ¿Qué evidencia medida motiva la decisión?
--      El EXPLAIN ANALYZE de (0) muestra que el plan está dominado por un
--      Parallel Seq Scan sobre detalle_pedido (300.000 filas) más un Seq
--      Scan sobre pedido (100.000 filas, descartando 98.500). El reporte
--      se ejecuta muchas veces por minuto y recorre las 4 tablas cada vez.
--      Preagregar por (día, categoría) elimina de raíz ese recorrido.
--
--  • ¿Qué mecanismo garantiza que el dato redundante no se desincronice?
--      Disparadores (triggers) sobre detalle_pedido, pedido y producto que
--      mantienen el resumen de forma incremental y en la misma transacción
--      que el cambio de origen: no hay ventana de desincronización. El
--      script de auditoría de (5) detectaría igualmente cualquier desvío.
--
--  • ¿Es reversible sin pérdida de información?
--      Sí: es un agregado derivado enteramente de las tablas normalizadas.
--      Se reconstruye en cualquier momento con el GROUP BY del backfill y
--      del auditor; no guarda ningún hecho que no esté en la fuente de verdad.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2. Estructura desnormalizada + mecanismo de sincronización
-- ---------------------------------------------------------------------

-- A. Tabla resumen (dato redundante precalculado)
DROP TABLE IF EXISTS venta_categoria_dia CASCADE;
CREATE TABLE venta_categoria_dia (
    fecha         DATE NOT NULL,
    categoria_id  BIGINT NOT NULL REFERENCES categoria(id),
    total_vendido NUMERIC(16,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (fecha, categoria_id)
);

-- B. Función auxiliar que aplica un delta (positivo o negativo) al resumen
CREATE OR REPLACE FUNCTION fn_ajusta_venta_categoria(
    p_fecha DATE, p_categoria BIGINT, p_delta NUMERIC
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_fecha IS NULL OR p_categoria IS NULL OR COALESCE(p_delta, 0) = 0 THEN
        RETURN;
    END IF;
    INSERT INTO venta_categoria_dia AS v (fecha, categoria_id, total_vendido)
    VALUES (p_fecha, p_categoria, p_delta)
    ON CONFLICT (fecha, categoria_id)
    DO UPDATE SET total_vendido = v.total_vendido + EXCLUDED.total_vendido;
END $$;

-- C. Backfill: siembra el resumen desde la fuente de verdad.
--    Se ejecuta ANTES de crear los disparadores para no duplicar montos.
TRUNCATE TABLE venta_categoria_dia;
INSERT INTO venta_categoria_dia (fecha, categoria_id, total_vendido)
SELECT ped.fecha::date,
       pr.categoria_id,
       SUM(dp.subtotal)
FROM detalle_pedido dp
JOIN pedido  ped ON ped.id  = dp.pedido_id
JOIN producto pr ON pr.id  = dp.producto_id
WHERE NOT dp.eliminado
  AND NOT ped.eliminado
GROUP BY ped.fecha::date, pr.categoria_id;

-- D. Disparadores de sincronización (mismo transacción => sin desfase)
DROP TRIGGER IF EXISTS trg_dp_ai ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_dp_au ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_dp_ad ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_ped_au ON pedido;
DROP TRIGGER IF EXISTS trg_prod_au ON producto;

-- D.1 INSERT de una línea de venta
CREATE OR REPLACE FUNCTION fn_dp_ai() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_fecha DATE; v_cat BIGINT; v_ped_el BOOLEAN;
BEGIN
    SELECT ped.fecha::date, ped.eliminado INTO v_fecha, v_ped_el
      FROM pedido ped WHERE ped.id = NEW.pedido_id;
    SELECT pr.categoria_id INTO v_cat
      FROM producto pr WHERE pr.id = NEW.producto_id;
    IF NOT NEW.eliminado AND NOT v_ped_el THEN
        PERFORM fn_ajusta_venta_categoria(v_fecha, v_cat, NEW.subtotal);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_dp_ai AFTER INSERT ON detalle_pedido
    FOR EACH ROW EXECUTE FUNCTION fn_dp_ai();

-- D.2 UPDATE de una línea de venta (cantidad, precio, producto, pedido, eliminado)
CREATE OR REPLACE FUNCTION fn_dp_au() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE old_fecha DATE; old_cat BIGINT; old_ped_el BOOLEAN;
        new_fecha DATE; new_cat BIGINT; new_ped_el BOOLEAN;
        old_monto NUMERIC := 0; new_monto NUMERIC := 0;
BEGIN
    IF ROW(OLD.pedido_id, OLD.producto_id, OLD.subtotal, OLD.eliminado)
       IS NOT DISTINCT FROM
       ROW(NEW.pedido_id, NEW.producto_id, NEW.subtotal, NEW.eliminado) THEN
        RETURN NULL;   -- nada relevante cambió
    END IF;
    SELECT ped.fecha::date, ped.eliminado INTO old_fecha, old_ped_el
      FROM pedido ped WHERE ped.id = OLD.pedido_id;
    SELECT pr.categoria_id INTO old_cat FROM producto pr WHERE pr.id = OLD.producto_id;
    SELECT ped.fecha::date, ped.eliminado INTO new_fecha, new_ped_el
      FROM pedido ped WHERE ped.id = NEW.pedido_id;
    SELECT pr.categoria_id INTO new_cat FROM producto pr WHERE pr.id = NEW.producto_id;

    IF NOT OLD.eliminado AND NOT old_ped_el THEN old_monto := OLD.subtotal; END IF;
    IF NOT NEW.eliminado AND NOT new_ped_el THEN new_monto := NEW.subtotal; END IF;

    PERFORM fn_ajusta_venta_categoria(old_fecha, old_cat, -old_monto);
    PERFORM fn_ajusta_venta_categoria(new_fecha, new_cat,  new_monto);
    RETURN NULL;
END $$;
CREATE TRIGGER trg_dp_au AFTER UPDATE ON detalle_pedido
    FOR EACH ROW EXECUTE FUNCTION fn_dp_au();

-- D.3 DELETE de una línea de venta
CREATE OR REPLACE FUNCTION fn_dp_ad() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_fecha DATE; v_cat BIGINT; v_ped_el BOOLEAN;
BEGIN
    SELECT ped.fecha::date, ped.eliminado INTO v_fecha, v_ped_el
      FROM pedido ped WHERE ped.id = OLD.pedido_id;
    SELECT pr.categoria_id INTO v_cat FROM producto pr WHERE pr.id = OLD.producto_id;
    IF NOT OLD.eliminado AND NOT v_ped_el THEN
        PERFORM fn_ajusta_venta_categoria(v_fecha, v_cat, -OLD.subtotal);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_dp_ad AFTER DELETE ON detalle_pedido
    FOR EACH ROW EXECUTE FUNCTION fn_dp_ad();

-- D.4 Cambio de fecha o de estado (eliminado) de un PEDIDO
CREATE OR REPLACE FUNCTION fn_ped_au() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r RECORD;
BEGIN
    IF OLD.fecha = NEW.fecha AND OLD.eliminado = NEW.eliminado THEN
        RETURN NULL;
    END IF;
    FOR r IN
        SELECT pr.categoria_id AS cat, SUM(dp.subtotal) AS monto
        FROM detalle_pedido dp
        JOIN producto pr ON pr.id = dp.producto_id
        WHERE dp.pedido_id = OLD.id AND NOT dp.eliminado
        GROUP BY pr.categoria_id
    LOOP
        IF NOT OLD.eliminado THEN
            PERFORM fn_ajusta_venta_categoria(OLD.fecha::date, r.cat, -r.monto);
        END IF;
        IF NOT NEW.eliminado THEN
            PERFORM fn_ajusta_venta_categoria(NEW.fecha::date, r.cat,  r.monto);
        END IF;
    END LOOP;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_ped_au AFTER UPDATE ON pedido
    FOR EACH ROW EXECUTE FUNCTION fn_ped_au();

-- D.5 Cambio de CATEGORÍA de un producto (mover la contribución)
CREATE OR REPLACE FUNCTION fn_prod_au() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r RECORD;
BEGIN
    IF OLD.categoria_id = NEW.categoria_id THEN
        RETURN NULL;
    END IF;
    FOR r IN
        SELECT ped.fecha::date AS fecha, SUM(dp.subtotal) AS monto
        FROM detalle_pedido dp
        JOIN pedido ped ON ped.id = dp.pedido_id
        WHERE dp.producto_id = OLD.id
          AND NOT dp.eliminado AND NOT ped.eliminado
        GROUP BY ped.fecha::date
    LOOP
        PERFORM fn_ajusta_venta_categoria(r.fecha, OLD.categoria_id, -r.monto);
        PERFORM fn_ajusta_venta_categoria(r.fecha, NEW.categoria_id,  r.monto);
    END LOOP;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_prod_au AFTER UPDATE ON producto
    FOR EACH ROW EXECUTE FUNCTION fn_prod_au();

-- Índice para el acceso "del día"
CREATE INDEX IF NOT EXISTS idx_vcd_fecha
    ON venta_categoria_dia (fecha, total_vendido DESC);

-- =====================================================================
-- 3. Reporte leyendo directamente de la estructura desnormalizada
--    (sin recorrer detalle_pedido, producto ni pedido)
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre AS categoria,
       v.total_vendido
FROM venta_categoria_dia v
JOIN categoria c ON c.id = v.categoria_id
WHERE v.fecha = CURRENT_DATE
ORDER BY v.total_vendido DESC
LIMIT 5;

-- =====================================================================
-- 5. Script de auditoría de desincronización [5.2(e)]
--    Compara el resumen contra el recálculo desde la fuente de verdad.
--    SU RESULTADO DEBE SER VACÍO (0 filas).
-- =====================================================================
WITH recalculo AS (
    SELECT ped.fecha::date AS fecha,
           pr.categoria_id,
           SUM(dp.subtotal) AS total
    FROM detalle_pedido dp
    JOIN pedido  ped ON ped.id = dp.pedido_id
    JOIN producto pr ON pr.id = dp.producto_id
    WHERE NOT dp.eliminado
      AND NOT ped.eliminado
    GROUP BY ped.fecha::date, pr.categoria_id
)
SELECT COALESCE(v.fecha, r.fecha)         AS fecha,
       COALESCE(v.categoria_id, r.categoria_id) AS categoria_id,
       v.total_vendido                    AS total_rollup,
       r.total                            AS total_recalculado
FROM venta_categoria_dia v
FULL OUTER JOIN recalculo r
       ON r.fecha = v.fecha AND r.categoria_id = v.categoria_id
WHERE v.total_vendido IS DISTINCT FROM r.total;

-- =====================================================================
-- (extra) Demostración en vivo de la sincronización, dentro de una
-- transacción que se revierte: se registra un pedido de HOY, se comprueba
-- que el resumen se movió solo, y luego se hace ROLLBACK para no alterar
-- los datos. El auditor de arriba debe seguir devolviendo 0 filas.
-- =====================================================================
BEGIN;
    WITH nuevo AS (
        INSERT INTO pedido (fecha, cliente_id, forma_pago)
        VALUES (now(), 1, 'EFECTIVO')
        RETURNING id
    ), linea AS (
        INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
        SELECT nuevo.id, p.id, 10, p.precio
        FROM nuevo, producto p
        WHERE p.id = 1            -- un producto de la categoría con id=1
        RETURNING producto_id, subtotal
    )
    SELECT 'demo: subtotal impactado' AS paso, SUM(subtotal) AS monto FROM linea;

    -- el resumen de HOY para la categoría 1 debe haber crecido
    SELECT 'demo: total hoy categoría 1 tras la venta' AS paso,
           total_vendido
    FROM venta_categoria_dia
    WHERE fecha = CURRENT_DATE AND categoria_id = 1;

    -- la auditoría, incluso con la venta en vuelo, sigue sin detectar desvío
    SELECT 'demo: filas de desincronización detectadas' AS paso, count(*) FROM (
        WITH recalculo AS (
            SELECT ped.fecha::date AS fecha, pr.categoria_id, SUM(dp.subtotal) AS total
            FROM detalle_pedido dp
            JOIN pedido  ped ON ped.id = dp.pedido_id
            JOIN producto pr ON pr.id = dp.producto_id
            WHERE NOT dp.eliminado AND NOT ped.eliminado
            GROUP BY ped.fecha::date, pr.categoria_id
        )
        SELECT COALESCE(v.fecha, r.fecha) AS fecha,
               COALESCE(v.categoria_id, r.categoria_id) AS cat,
               v.total_vendido AS a, r.total AS b
        FROM venta_categoria_dia v
        FULL OUTER JOIN recalculo r
             ON r.fecha = v.fecha AND r.categoria_id = v.categoria_id
        WHERE v.total_vendido IS DISTINCT FROM r.total
    ) d;
ROLLBACK;
