PRAGMA foreign_keys = ON;
-- Ejecutar sobre una base NUEVA con schema_sqlite.sql + instantanea + cargar_cache.sql.
-- Este archivo incluye DOS ERRORES ESPERADOS C7; sqlite3 debe continuar hasta ROLLBACK.
-- No usar .bail on en este archivo interactivo. El runner Python comprueba ambos errores.

-- Borrador completo atomico, alias ficticio.
BEGIN;
INSERT INTO pedido_borrador VALUES ('10000000-0000-4000-8000-000000000010','DEMO-02','TARJETA','2026-11-01T12:10:00Z');
INSERT INTO item_borrador VALUES ('10000000-0000-4000-8000-000000000010',10,2,450000);
INSERT INTO cola_sync VALUES ('20000000-0000-4000-8000-000000000010','10000000-0000-4000-8000-000000000010','PENDIENTE',NULL);
COMMIT;
SELECT 'COMMIT: 1 borrador, 1 item, 1 solicitud',count(*) FROM cola_sync;

-- Operacion deshecha: no queda cabecera ni item.
BEGIN;
INSERT INTO pedido_borrador VALUES ('10000000-0000-4000-8000-000000000011','DEMO-03','TRANSFERENCIA','2026-11-01T12:11:00Z');
INSERT INTO item_borrador VALUES ('10000000-0000-4000-8000-000000000011',15,1,120000);
ROLLBACK;
SELECT 'ROLLBACK: debe ser 0',count(*) FROM pedido_borrador WHERE id_local='10000000-0000-4000-8000-000000000011';

-- C1: sin servidor ni conexion de red.
SELECT id,nombre,precio_centavos,stock_visto,fecha_copia FROM producto_cache
WHERE disponible=1 AND eliminado=0 ORDER BY id;

-- C7a: error CHECK esperado; luego ROLLBACK deshace tambien cabecera.
BEGIN;
INSERT INTO pedido_borrador VALUES ('10000000-0000-4000-8000-000000000012','DEMO-04','EFECTIVO','2026-11-01T12:12:00Z');
INSERT INTO item_borrador VALUES ('10000000-0000-4000-8000-000000000012',10,0,450000);
ROLLBACK;
-- C7b: error FOREIGN KEY esperado, no se deja una cabecera huerfana.
BEGIN;
INSERT INTO pedido_borrador VALUES ('10000000-0000-4000-8000-000000000013','DEMO-05','EFECTIVO','2026-11-01T12:13:00Z');
INSERT INTO item_borrador VALUES ('10000000-0000-4000-8000-000000000013',999,1,450000);
ROLLBACK;
SELECT 'C7: debe ser 0',count(*) FROM pedido_borrador WHERE id_local IN
('10000000-0000-4000-8000-000000000012','10000000-0000-4000-8000-000000000013');
PRAGMA foreign_key_check;
