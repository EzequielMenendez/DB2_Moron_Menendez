-- TP8: vista sobre la fixture de PRUEBAS. No modifica precio, stock ni pedidos.
-- En este modelo la baja logica es activo=FALSE; no inventar una columna
-- producto.eliminado inexistente en los scripts historicos del repositorio.
\set ON_ERROR_STOP on
CREATE OR REPLACE VIEW tp8_servidor.v_snapshot_movil AS
SELECT id, nombre,
       (precio * 100)::BIGINT AS precio_centavos,
       stock,
       activo AND stock > 0 AS disponible,
       NOT activo AS eliminado,
       to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC',
               'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS fecha_copia
FROM tp8_servidor.producto;

-- La vista incluye las lapidas: NO agregar WHERE activo.
-- Desde raiz del repositorio, en psql:
-- \copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/servidor_snapshot.csv' CSV HEADER
