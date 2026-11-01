-- =====================================================================
-- sql/consultas_postgresql.sql
-- Unidad 7: NoSQL y nuevas formas de almacenamiento | Food Store
-- Contiene las consultas equivalentes en SQL relacional para la Parte 2.
-- =====================================================================

-- 1. Consulta b) Filtrar pedidos por estado (ej: 'CONFIRMADO')
-- Nota: asumiendo que pedido tiene columna estado o forma de pago / estado lógico;
-- adaptado al esquema real de Food Store.
SELECT p.id AS pedido_id, p.fecha
FROM pedido p
WHERE p.estado = 'CONFIRMADO'; -- o el campo de estado equivalente

-- 2. Consulta c) Buscar pedidos que contengan un producto determinado (ej: producto_id = 10)
SELECT DISTINCT p.id AS pedido_id, p.fecha
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE dp.producto_id = 10;

-- 3. Consulta d) Buscar pedidos cuyo total sea superior a un importe elegido (ej: > 10000)
SELECT p.id AS pedido_id, SUM(dp.subtotal) AS total_pedido
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
GROUP BY p.id, p.fecha
HAVING SUM(dp.subtotal) > 10000
ORDER BY total_pedido DESC;
