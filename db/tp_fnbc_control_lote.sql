-- =====================================================================
-- tp_fnbc_control_lote.sql
-- Unidad 4 — Forma Normal de Boyce-Codd (FNBC)
-- Parte 1: análisis y aplicación de la FNBC sobre ControlLoteAlmacen
-- Base: food_store (PostgreSQL 18)
--
-- Contenido del artefacto:
--   0. Tablas maestras de la extensión mayorista (lote, deposito, usuario)
--   1. Esquema original control_lote_almacen + instancia de ejemplo
--   2. (a) Dependencias funcionales en notación formal
--   3. (b) Clausuras, claves candidatas y atributos primos
--   4. (c) Verificación formal de FNBC e identificación de la FD violatoria
--   5. (d) Anomalías clásicas habilitadas por la violación
--   6. (e) Descomposición sin pérdida + script SQL de las tablas resultantes
--   7. (f) Justificación de la unión sin pérdida, migración y verificación
-- =====================================================================

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 0. Tablas maestras de la extensión mayorista
--    La consigna las da por existentes; se crean aquí si faltan para que
--    el script sea autocontenido y las FK de control_lote_almacen resuelvan.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lote (
    id          BIGINT PRIMARY KEY,
    proveedor   VARCHAR(120),
    fecha_recepcion DATE
);

CREATE TABLE IF NOT EXISTS deposito (
    id      BIGINT PRIMARY KEY,
    nombre  VARCHAR(120) NOT NULL,
    ubicacion VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS usuario (
    id        BIGINT PRIMARY KEY,
    nombre    VARCHAR(120) NOT NULL,
    email     VARCHAR(254)
);

-- Instancia mínima que sostiene los IDs referenciados por la consigna
INSERT INTO lote (id, proveedor) VALUES
    (501, 'Distribuidora Norte'), (502, 'Distribuidora Norte'), (503, 'Mayorista Sur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO deposito (id, nombre) VALUES
    (30, 'Depósito Central'), (31, 'Depósito Sur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO usuario (id, nombre) VALUES
    (801, 'Responsable 801'), (802, 'Responsable 802')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 1. Esquema original (traído de la consigna)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS control_lote_almacen CASCADE;

CREATE TABLE control_lote_almacen (
    lote_id                BIGINT NOT NULL REFERENCES lote(id),
    deposito_id            BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

INSERT INTO control_lote_almacen VALUES
    (501, 30, 801),
    (502, 30, 801),
    (503, 31, 802);

-- =====================================================================
-- (a) Dependencias funcionales en notación formal
--
-- Atributos: LoteID, DepositoID, ResponsableControlID
--
-- Regla de negocio 1: "Para un lote y un depósito interviniente dados,
--   el responsable de control queda unívocamente determinado."
--       FD1:  { LoteID, DepositoID }  ->  { ResponsableControlID }
--
-- Regla de negocio 2: "Cada responsable de control pertenece ... a un
--   único depósito: no controla lotes coordinados desde depósitos distintos."
--       FD2:  { ResponsableControlID }  ->  { DepositoID }
--
-- (en notación de conjuntos de atributos, FD1: {LoteID,DepositoID}->{ResponsableControlID}
--  y FD2: {ResponsableControlID}->{DepositoID}; ambas no triviales)
-- =====================================================================

-- =====================================================================
-- (b) Clausuras, claves candidatas y atributos primos
--
-- FD1: {LoteID, DepositoID} -> {ResponsableControlID}
-- FD2: {ResponsableControlID} -> {DepositoID}
--
-- Clausuras calculadas (las dos siguientes consultas las verifican en BD):
--
--   {LoteID, DepositoID}+          = {LoteID, DepositoID, ResponsableControlID} = R
--   {LoteID, ResponsableControlID}+
--         = {LoteID, ResponsableControlID}  (FD1 no aplica: falta DepositoID)
--         U {DepositoID}   por FD2         = R
--   {ResponsableControlID}+         = {ResponsableControlID, DepositoID}   (≠ R)
--   {DepositoID}+                   = {DepositoID}                          (≠ R)
--   {LoteID}+                       = {LoteID}                              (≠ R)
--
-- Claves candidatas (minimales que determinan R):
--   K1 = { LoteID, DepositoID }
--   K2 = { LoteID, ResponsableControlID }
--
-- Atributos primos (aparecen en alguna clave candidata): LoteID, DepositoID,
--   ResponsableControlID  ->  los tres son primos (no hay atributos no primos).
-- =====================================================================

-- Verificación de que ambas FD se cumplen sobre la instancia cargada:
--
-- FD1 se cumple POR CONSTRUCCIÓN: la PK (lote_id, deposito_id) garantiza un
--   único responsable por cada par (lote, depósito). Se comprueba igualmente:
SELECT 'FD1 violada' AS fd, count(*) AS filas_inconsistentes
FROM (
    SELECT lote_id, deposito_id
    FROM control_lote_almacen
    GROUP BY lote_id, deposito_id
    HAVING count(DISTINCT responsable_control_id) > 1
) x;
-- resultado esperado: 0

-- FD2 se cumple sobre la instancia: cada responsable aparece con un solo depósito
SELECT 'FD2 violada' AS fd, count(*) AS responsables_con_mas_de_un_deposito
FROM (
    SELECT responsable_control_id
    FROM control_lote_almacen
    GROUP BY responsable_control_id
    HAVING count(DISTINCT deposito_id) > 1
) y;
-- resultado esperado: 0

-- =====================================================================
-- (c) Verificación formal de FNBC
--
-- Definición: R está en FNBC ssi para toda FD no trivial X -> Y se cumple
--   que X es superclave de R.
--
--   FD1: {LoteID, DepositoID} -> {ResponsableControlID}
--        El determinante {LoteID, DepositoID} ES una clave candidata (K1),
--        por lo tanto es superclave  ->  FD1 NO viola la FNBC.
--
--   FD2: {ResponsableControlID} -> {DepositoID}
--        El determinante {ResponsableControlID} NO es superclave: su clausura
--        es {ResponsableControlID, DepositoID}, que no contiene LoteID, luego
--        no determina la relación completa.  ->  FD2 VIOLA la FNBC.
--
-- Conclusión: control_lote_almacen NO está en FNBC (y por lo tanto tampoco
-- en 3FN, aunque aquí el criterio aplicado es el de FNBC).
-- =====================================================================

-- Prueba automática de que el determinante de FD2 no es superclave:
SELECT (SELECT count(DISTINCT responsable_control_id) FROM control_lote_almacen)
           AS responsables_distintos,
       (SELECT count(*) FROM control_lote_almacen)
           AS filas_totales,
       'responsable_control_id NO es superclave (hay menos valores distintos que filas)'
           AS conclusion;

-- =====================================================================
-- (d) Anomalías clásicas que la violación de FD2 habilita
--     (escenarios con la instancia cargada: 501|30|801, 502|30|801, 503|31|802)
--
-- Inserción:  Queremos registrar que el responsable 803 pertenece al depósito 32
--   (nuevo ingreso de personal que todavía no controló lotes). No podemos: la
--   clave primaria (lote_id, deposito_id) exige un lote_id NOT NULL, y no existe
--   un lote que asignarle. El dato maestro "803 -> 32" queda huérfano e imposible
--   de guardar sin inventar un lote ficticio.
--
-- Borrado:    Si el lote 503 deja de estar bajo control (se elimina la fila
--   503|31|802), perdemos también el único registro de que el responsable 802
--   pertenece al depósito 31. Borrar un lote borra información maestra de personal.
--
-- Actualización: Si el responsable 801 se reasigna del depósito 30 al 33, su
--   atributo DepositoID está duplicado en dos filas (501|30|801 y 502|30|801).
--   Hay que hacer UPDATE en ambas; si se actualiza solo una, 801 queda mostrado
--   en dos depósitos a la vez (estado inconsistente).
-- =====================================================================
-- (demostración de la anomalía de inserción: intento fallido)
DO $$
BEGIN
    -- No puede insertarse un responsable nuevo sin un lote asociado
    BEGIN
        INSERT INTO control_lote_almacen VALUES (NULL, 32, 803);
    EXCEPTION WHEN not_null_violation OR foreign_key_violation THEN
        RAISE NOTICE 'Anomalía de INSERCIÓN confirmada: no se puede registrar el depósito de un responsable sin asignarle un lote (PK/NOT NULL lo impide).';
    END;
END $$;

-- =====================================================================
-- (e) Descomposición sin pérdida (algoritmo de FNBC)
--
-- Determinante violatorio: {ResponsableControlID}.
-- Paso 1: separar una relación que contenga el determinante violatorio y los
--         atributos que determina:
--             R2(ResponsableControlID, DepositoID)      -- clave: ResponsableControlID
-- Paso 2: el resto de los atributos forman:
--             R1(LoteID, ResponsableControlID)          -- clave: (LoteID, ResponsableControlID)
--
-- Script SQL de las tablas resultantes:
-- =====================================================================
DROP TABLE IF EXISTS control_lote_responsable CASCADE;
DROP TABLE IF EXISTS responsable_deposito CASCADE;

-- R2:ResponsableControlID -> DepositoID (cada responsable pertenece a un depósito)
CREATE TABLE responsable_deposito (
    responsable_control_id BIGINT PRIMARY KEY REFERENCES usuario(id),
    deposito_id            BIGINT NOT NULL REFERENCES deposito(id)
);

-- R1: (LoteID, ResponsableControlID) — cada lote-control por depósito
CREATE TABLE control_lote_responsable (
    lote_id                BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

-- =====================================================================
-- (f) Justificación de la unión sin pérdida + migración + verificación
--
-- Criterio de superclave sobre el atributo común:
--   La descomposición es R1(LoteID, ResponsableControlID) y
--   R2(ResponsableControlID, DepositoID). El único atributo común es
--   ResponsableControlID, y por la FD2 (ResponsableControlID -> DepositoID)
--   ese atributo es CLAVE de R2. Criterio de unión sin pérdida: si el
--   atributo común es superclave de alguna de las relaciones, la reunión
--   natural es sin pérdida. Como ResponsableControlID es clave de R2,
--   R1 ⋈ R2 = R sin tuplas espurias ni pérdida.
-- =====================================================================

-- Migración de la instancia de ejemplo hacia las tablas descompuestas
INSERT INTO control_lote_responsable (lote_id, responsable_control_id)
SELECT lote_id, responsable_control_id
FROM control_lote_almacen;

-- DISTINCT: el responsable 801 controla dos lotes del mismo depósito 30,
-- pero en R2 aparece una sola vez (su PK es responsable_control_id).
INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT DISTINCT responsable_control_id, deposito_id
FROM control_lote_almacen;

-- ---------------------------------------------------------------------
-- Vista de compatibilidad: reconstruye la relación original con una
-- reunión natural sobre el atributo común ResponsableControlID.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_control_lote_almacen_compat;
CREATE VIEW v_control_lote_almacen_compat AS
SELECT r1.lote_id,
       r2.deposito_id,
       r1.responsable_control_id
FROM control_lote_responsable r1
NATURAL JOIN responsable_deposito r2;

-- ---------------------------------------------------------------------
-- Verificación de la equivalencia: la vista debe devolver exactamente
-- las 3 filas originales. Se comprueba en ambos sentidos (EXCEPT vacío).
-- ---------------------------------------------------------------------
SELECT 'filas originales' AS origen, count(*) FROM control_lote_almacen
UNION ALL
SELECT 'filas via vista', count(*) FROM v_control_lote_almacen_compat;

-- Diferencia en ambos sentidos (ambos resultados deben ser 0 filas)
SELECT 'original MENOS vista' AS chequeo, count(*) FROM (
    SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
    EXCEPT
    SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen_compat
) d
UNION ALL
SELECT 'vista MENOS original', count(*) FROM (
    SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen_compat
    EXCEPT
    SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
) d;

-- Contenido final de la vista (debe ser idéntico a la instancia de ejemplo)
SELECT * FROM v_control_lote_almacen_compat ORDER BY lote_id;
