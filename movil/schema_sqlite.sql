PRAGMA foreign_keys = ON;
-- SQLite >=3.37. Cada conexion debe activar foreign_keys, no solo al crear.
-- Datos sinteticos: usuario es un alias local, nunca una cuenta personal.
BEGIN;
CREATE TABLE producto_cache (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0,1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0,1)),
    fecha_copia TEXT NOT NULL
) STRICT;
CREATE TABLE pedido_borrador (
    id_local TEXT PRIMARY KEY NOT NULL CHECK (length(id_local)=36),
    usuario TEXT NOT NULL,
    forma_pago TEXT NOT NULL CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    fecha TEXT NOT NULL
) STRICT;
CREATE TABLE item_borrador (
    id_local TEXT NOT NULL REFERENCES pedido_borrador(id_local),
    producto_id INTEGER NOT NULL REFERENCES producto_cache(id),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id)
) STRICT;
CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY NOT NULL CHECK (length(solicitud_uuid)=36),
    id_local TEXT NOT NULL REFERENCES pedido_borrador(id_local),
    estado TEXT NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO')),
    motivo TEXT
) STRICT;
-- CSV de psql: booleanos t/f, precios convertidos a centavos en PostgreSQL.
CREATE TABLE snapshot_servidor (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    disponible TEXT NOT NULL CHECK (disponible IN ('t','f')),
    eliminado TEXT NOT NULL CHECK (eliminado IN ('t','f')),
    fecha_copia TEXT NOT NULL
) STRICT;
CREATE INDEX idx_cola_sync_pendiente ON cola_sync(id_local) WHERE estado='PENDIENTE';
COMMIT;
