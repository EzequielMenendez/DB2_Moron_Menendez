# Unidad 4 — FNBC y Desnormalización Controlada · Food Store

Trabajo práctico sobre la base `food_store` (PostgreSQL 18.6).
Artefactos SQL: [`db/tp_fnbc_control_lote.sql`](../db/tp_fnbc_control_lote.sql) (Parte 1) y
[`db/tp_desnormalizacion_top_categorias.sql`](../db/tp_desnormalizacion_top_categorias.sql) (Parte 2).

> **Nota de preparación.** La consigna da por existentes las tablas `pedido`,
> `detalle_pedido`, `producto` y `categoria`. La base `food_store` tenía
> `linea_pedido` (renombrada a `detalle_pedido`), `pedido.fecha_hora`
> (renombrada a `pedido.fecha`) y no tenía las columnas `subtotal` ni
> `eliminado`. El script [`db/preparar_food_store.sql`](../db/preparar_food_store.sql)
> alinea el esquema (renombrado + `subtotal` GENERADA + `eliminado`) y la puebla
> de forma determinista (100.000 pedidos / 300.000 líneas, 1.500 pedidos de hoy).
> `pedido.fecha` es `TIMESTAMPTZ`, por eso el reporte usa `fecha::date = CURRENT_DATE`
> (equivalente al `fecha = CURRENT_DATE` de la consigna, que asumía una columna DATE).

---

## Parte 1 — FNBC de `ControlLoteAlmacen`

### (a) Dependencias funcionales

Regla de negocio → notación formal (atributos `LoteID`, `DepositoID`, `ResponsableControlID`):

| # | Regla relevada | Dependencia funcional |
|---|----------------|------------------------|
| 1 | Para un lote y un depósito dados, el responsable queda unívocamente determinado | **FD1:** `{LoteID, DepositoID} → {ResponsableControlID}` |
| 2 | Cada responsable pertenece a un único depósito | **FD2:** `{ResponsableControlID} → {DepositoID}` |

Ambas son no triviales. Se verifican sobre la instancia (0 inconsistencias en cada una).

### (b) Clausuras, claves candidatas y atributos primos

Clausuras de los subconjuntos candidatos:

| Subconjunto | Clausura | ¿Es clave? |
|-------------|----------|------------|
| `{LoteID, DepositoID}` | `{LoteID, DepositoID, ResponsableControlID}` = R | Sí (K1) |
| `{LoteID, ResponsableControlID}` | `{LoteID, ResponsableControlID}` ∪ `{DepositoID}` (por FD2) = R | Sí (K2) |
| `{ResponsableControlID}` | `{ResponsableControlID, DepositoID}` ≠ R | No |
| `{DepositoID}` | `{DepositoID}` ≠ R | No |
| `{LoteID}` | `{LoteID}` ≠ R | No |

**Claves candidatas:** `K1 = {LoteID, DepositoID}` y `K2 = {LoteID, ResponsableControlID}` (ambas minimales).

**Atributos primos:** `LoteID`, `DepositoID` y `ResponsableControlID` aparecen en alguna clave candidata → **los tres son primos; no hay atributos no primos**.

### (c) Verificación formal de FNBC

Definición: R está en FNBC ssi para toda FD no trivial `X → Y`, `X` es superclave.

- **FD1:** el determinante `{LoteID, DepositoID}` **es** clave candidata (K1), luego superclave → **no viola**.
- **FD2:** el determinante `{ResponsableControlID}` **no** es superclave: su clausura es `{ResponsableControlID, DepositoID}`, que no contiene `LoteID`, luego no determina la relación completa → **viola la FNBC**.

Comprobación en BD (si fuera superclave, la cantidad de valores distintos del determinante igualaría la de filas; hay 2 responsables para 3 filas):

```
 responsables_distintos | filas_totales
------------------------+---------------
                      2 |             3
```

**Conclusión:** `control_lote_almacen` **no está en FNBC**. La FD violatoria es
`{ResponsableControlID} → {DepositoID}` y su determinante no es superclave.

### (d) Anomalías habilitadas (sobre la instancia `501|30|801, 502|30|801, 503|31|802`)

- **Inserción:** queremos registrar que el nuevo responsable `803` pertenece al depósito `32` (ingresó pero aún no controló lotes). No se puede: la PK `(lote_id, deposito_id)` exige un `lote_id NOT NULL` y no hay lote que asignarle. El dato maestro `803 → 32` queda imposible de guardar sin inventar un lote ficticio. *(Demostrado en el script: el `INSERT` falla por NOT NULL/FK.)*
- **Borrado:** si se elimina el lote `503`, desaparece la fila `503|31|802` y con ella el único registro de que el responsable `802` pertenece al depósito `31`. Borrar un lote borra información maestra de personal.
- **Actualización:** si `801` se reasigna del depósito `30` al `33`, su depósito está duplicado en dos filas (`501|30|801` y `502|30|801`). Hay que hacer `UPDATE` en ambas; si se actualiza solo una, `801` queda mostrado en dos depósitos a la vez (estado inconsistente).

### (e) Descomposición sin pérdida (algoritmo de FNBC)

Determinante violatorio: `{ResponsableControlID}`.

| Tabla resultante | Atributos | Clave primaria |
|------------------|-----------|----------------|
| `control_lote_responsable` (R1) | `LoteID, ResponsableControlID` | `(LoteID, ResponsableControlID)` |
| `responsable_deposito` (R2) | `ResponsableControlID, DepositoID` | `ResponsableControlID` |

Script completo (PK + FK + vista de compatibilidad) en la sección (e) del
`tp_fnbc_control_lote.sql`. La vista de compatibilidad reconstruye la relación
original con una **reunión natural** sobre el atributo común:

```sql
CREATE VIEW v_control_lote_almacen_compat AS
SELECT r1.lote_id, r2.deposito_id, r1.responsable_control_id
FROM control_lote_responsable r1
NATURAL JOIN responsable_deposito r2;
```

### (f) Justificación de la unión sin pérdida y migración

**Criterio de superclave:** el único atributo común de R1 y R2 es
`ResponsableControlID`, y por la FD2 (`ResponsableControlID → DepositoID`) ese
atributo **es clave de R2**. Criterio de unión sin pérdida: si el atributo común
es superclave de alguna de las relaciones, la reunión natural es sin pérdida.
Como `ResponsableControlID` es clave de R2, **R1 ⋈ R2 = R**, sin tuplas espurias
ni pérdida de información.

**Migración y verificación** (el `EXCEPT` en ambos sentidos devuelve 0 filas):

```
      origen      | count
------------------+-------
 filas originales |     3
 filas via vista  |     3

       chequeo        | count
----------------------+-------
 original MENOS vista |     0
 vista MENOS original |     0

 lote_id | deposito_id | responsable_control_id
---------+--------------+------------------------
     501 |           30 |                    801
     502 |           30 |                    801
     503 |           31 |                    802
```

---

## Parte 2 — Desnormalización controlada del reporte Top-5 categorías del día

### (a) Consulta original y plan medido

La consulta normalizada une las 4 tablas (`detalle_pedido → producto → categoria → pedido`)
y filtra por el día. `EXPLAIN ANALYZE` sobre 300.000 líneas / 100.000 pedidos:

```
Limit (cost=8779.73..8779.74 rows=5) (actual time=53.483..56.919 rows=5.00)
  -> Sort (sum(dp.subtotal) DESC)
    -> Finalize GroupAggregate (Group Key: c.nombre)
      -> Gather Merge
        -> Partial GroupAggregate
          -> Sort (Group Key: c.nombre)
            -> Hash Join (Hash Cond: pr.categoria_id = c.id)
              -> Nested Loop
                -> Hash Join (Hash Cond: dp.pedido_id = ped.id)
                  -> Parallel Seq Scan on detalle_pedido dp   rows=150000 loops=2
                  -> Hash on pedido ped  (Filter: (NOT eliminado) AND ((fecha)::date = CURRENT_DATE))
                     Seq Scan on pedido ped  rows=1500  (Rows Removed by Filter: 98500)
                -> Index Scan on producto pr
              -> Hash on categoria c
 Execution Time: 57.108 ms
```

- **Tiempo de ejecución:** **≈ 57,1 ms**
- **Nodo que domina el costo:** el **`Parallel Seq Scan` sobre `detalle_pedido`** (300.000 filas) junto al **`Seq Scan` sobre `pedido`** (100.000 filas, de las que descarta 98.500 al filtrar el día). El recorrido de las dos tablas de hechos concentra casi todo el costo.

### (b) Patrón elegido y justificación

**Tabla resumen precalculada `venta_categoria_dia(fecha, categoria_id, total_vendido)`, mantenida con disparadores.**

- **¿Qué evidencia motiva la decisión?** El plan de (a) está dominado por el recorrido de `detalle_pedido` (300k filas) y `pedido` (100k filas) cada vez que el panel consulta. Preagregar por `(día, categoría)` elimina ese recorrido: el reporte pasa a leer 8 filas.
- **¿Qué mecanismo evita la desincronización?** Disparadores sobre `detalle_pedido` (INSERT/UPDATE/DELETE), `pedido` (cambio de `fecha`/`eliminado`) y `producto` (cambio de `categoria_id`) que ajustan el resumen de forma incremental **en la misma transacción** que el cambio de origen: no hay ventana de desfase. La auditoría de (e) detectaría cualquier desvío.
- **¿Es reversible sin pérdida?** Sí: es un agregado derivado íntegramente de las tablas normalizadas; se reconstruye con el `GROUP BY` del backfill/auditor y no guarda ningún hecho que no esté en la fuente de verdad.

Se descartó la **vista materializada** porque su `REFRESH` es asíncrono (no sirve para un panel "en tiempo real y con actualización frecuente"); se descartó una sola **columna precalculada en `detalle_pedido`** porque no elimina el `JOIN` de las 4 tablas.

### (c) Estructura y sincronización

Ver `tp_desnormalizacion_top_categorias.sql` secciones 2.A–2.D: tabla resumen,
función `fn_ajusta_venta_categoria` (aplica deltas), backfill inicial y cinco
disparadores que cubren insert/update/delete de líneas, cambios de fecha/estado
del pedido y cambios de categoría del producto.

### (d) Reporte desde la estructura desnormalizada y comparación

```sql
SELECT c.nombre AS categoria, v.total_vendido
FROM venta_categoria_dia v
JOIN categoria c ON c.id = v.categoria_id
WHERE v.fecha = CURRENT_DATE
ORDER BY v.total_vendido DESC
LIMIT 5;
```

```
Limit (cost=0.28..30.03 rows=5) (actual time=0.050..0.056 rows=5.00)
  -> Nested Loop (Join Filter: v.categoria_id = c.id)
    -> Index Scan using idx_vcd_fecha on venta_categoria_dia v  rows=5.00
    -> Materialize
      -> Seq Scan on categoria c  rows=7.00
 Execution Time: 0.071 ms
```

**Resultado del Top-5 del día:**

| Categoría | Total vendido |
|-----------|---------------|
| Congelados | 438.763,64 |
| Snacks | 436.081,54 |
| Carnes | 435.750,73 |
| Limpieza | 431.126,42 |
| Panadería | 429.901,05 |

**Tabla comparativa antes / después:**

| Métrica | Antes (normalizado) | Después (desnormalizado) |
|---------|---------------------|---------------------------|
| Tiempo de ejecución | **57,108 ms** | **0,071 ms** |
| Nodo dominante del plan | `Parallel Seq Scan` sobre `detalle_pedido` + `Seq Scan` sobre `pedido` | `Index Scan` sobre `idx_vcd_fecha` en `venta_categoria_dia` |
| Tablas recorridas | 4 (detalle, producto, categoria, pedido) | 2 (resumen + dimensión categoria de 8 filas) |
| Filas leídas de hechos | 300.000 | 8 (solo las del día) |

≈ **800×** más rápido.

### (e) Auditoría de desincronización

Script en la sección 5 del archivo: `FULL OUTER JOIN` entre el resumen y el
recálculo desde la fuente de verdad, filtrando filas donde
`total_vendido IS DISTINCT FROM total`. **Ejecutado sobre la base migrada devuelve 0 filas:**

```
 filas_desincronizadas
-----------------------
                     0
```

La demostración en vivo del script (venta de hoy dentro de una transacción con
`ROLLBACK`) confirma que el resumen se ajusta solo y la auditoría sigue en 0.

---

## Cómo reproducir

```powershell
# 1) Preparar y poblar food_store (idempotente)
psql -U postgres -d food_store -f db\preparar_food_store.sql

# 2) Parte 1: FNBC de ControlLoteAlmacen
psql -U postgres -d food_store -f db\tp_fnbc_control_lote.sql

# 3) Parte 2: desnormalización del reporte (incluye EXPLAIN ANALYZE y auditoría)
psql -U postgres -d food_store -f db\tp_desnormalizacion_top_categorias.sql
```
