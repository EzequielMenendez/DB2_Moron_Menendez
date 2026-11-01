PRAGMA foreign_keys = ON;
-- Aplicar SOLO instantanea COMPLETA. No usar INSERT OR REPLACE: borraria FK.
BEGIN;
INSERT INTO producto_cache(id,nombre,precio_centavos,stock_visto,disponible,eliminado,fecha_copia)
SELECT id,nombre,precio_centavos,stock,
       CASE disponible WHEN 't' THEN 1 ELSE 0 END,
       CASE eliminado WHEN 't' THEN 1 ELSE 0 END,fecha_copia
FROM snapshot_servidor WHERE 1
ON CONFLICT(id) DO UPDATE SET
    nombre=excluded.nombre,precio_centavos=excluded.precio_centavos,
    stock_visto=excluded.stock_visto,disponible=excluded.disponible,
    eliminado=excluded.eliminado,fecha_copia=excluded.fecha_copia;
-- Ausencia de la instantanea: ocultar conservando fila y referencias locales.
UPDATE producto_cache SET disponible=0, eliminado=1
WHERE NOT EXISTS (SELECT 1 FROM snapshot_servidor s WHERE s.id=producto_cache.id);
COMMIT;
