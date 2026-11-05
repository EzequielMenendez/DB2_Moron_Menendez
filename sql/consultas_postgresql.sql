-- =====================================================================
-- sql/consultas_postgresql.sql
-- Unidad 7: NoSQL y nuevas formas de almacenamiento | Food Store
-- 
-- NOTA: Las consultas están estrictamente acotadas al conjunto de los 5 pedidos
-- migrados (IDs 1 al 5) para permitir una comparación numérica y de IDs 
-- exacta contra MongoDB.
-- =====================================================================

-- 1. Consulta b) Equivalente en PostgreSQL: Filtrar pedidos por estado ('CONFIRMADO')
-- acotado a los pedidos migrados (1 a 5).
SELECT p.id AS pedido_id, p.fecha
FROM pedido p
WHERE p.id BETWEEN 1 AND 5
  AND p.forma_pago = 'EFECTIVO'; -- o estado si la tabla lo incluye, acotado al subconjunto migrado

-- 2. Consulta c) Equivalente en PostgreSQL: Buscar pedidos que contengan un producto determinado (ej: producto_id = 80)
-- acotado al subconjunto migrado (1 a 5).
SELECT DISTINCT p.id AS pedido_id, p.fecha
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE p.id BETWEEN 1 AND 5
  AND dp.producto_id = 80;

-- 3. Consulta de verificación de totales (para los datos migrados)
SELECT p.id AS pedido_id, SUM(dp.subtotal) AS total_pedido
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE p.id BETWEEN 1 AND 5
GROUP BY p.id, p.fecha
ORDER BY p.id;
