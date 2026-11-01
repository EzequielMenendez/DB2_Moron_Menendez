PRAGMA foreign_keys = ON;
-- Simula validacion contra una instantanea. NO vende, reserva ni modifica servidor.
BEGIN;
WITH evaluacion AS (
    SELECT c.solicitud_uuid,
           COUNT(i.producto_id) AS cantidad_items,
           SUM(CASE WHEN i.producto_id IS NOT NULL AND
                    (s.id IS NULL OR s.disponible<>'t' OR s.eliminado='t' OR i.cantidad>s.stock)
                    THEN 1 ELSE 0 END) AS rojos,
           SUM(CASE WHEN i.precio_centavos_visto<>s.precio_centavos THEN 1 ELSE 0 END) AS amarillos
    FROM cola_sync c
    LEFT JOIN item_borrador i ON i.id_local=c.id_local
    LEFT JOIN snapshot_servidor s ON s.id=i.producto_id
    WHERE c.estado='PENDIENTE'
    GROUP BY c.solicitud_uuid
), resultados AS (
    SELECT solicitud_uuid,
           CASE WHEN cantidad_items=0 OR rojos>0 THEN 'RECHAZADO'
                WHEN amarillos>0 THEN 'CONFLICTO'
                ELSE 'SIMULADO_APROBADO' END AS estado,
           CASE WHEN cantidad_items=0 THEN 'Borrador sin items'
                WHEN rojos>0 THEN 'Producto ausente, no disponible, eliminado o stock insuficiente'
                WHEN amarillos>0 THEN 'Precio actual distinto del precio visto; requiere aceptacion'
                ELSE 'Coincide con instantanea; simulacion sin venta ni reserva' END AS motivo
    FROM evaluacion
)
UPDATE cola_sync SET
    estado=(SELECT r.estado FROM resultados r WHERE r.solicitud_uuid=cola_sync.solicitud_uuid),
    motivo=(SELECT r.motivo FROM resultados r WHERE r.solicitud_uuid=cola_sync.solicitud_uuid)
WHERE estado='PENDIENTE';
COMMIT;
