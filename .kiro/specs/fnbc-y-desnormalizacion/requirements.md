# Requirements: Refactorización FNBC y Desnormalización Controlada — Food Store (Unidad 4)

## Historias de usuario y criterios de aceptación (EARS)

### RU-U4-01: Validación de dependencias funcionales y descomposición a FNBC
- **Como** arquitecto de datos de Food Store,
- **Quiero** refactorizar la relación heredada `control_lote_almacen(lote_id, deposito_id, responsable_control_id)` validándola contra las dependencias funcionales reales (`{lote_id, deposito_id} -> {responsable_control_id}` y `{responsable_control_id} -> {deposito_id}`),
- **Para que** el esquema alcance la Forma Normal de Boyce-Codd (FNBC) y elimine las anomalías de inserción, actualización y borrado.

**Criterios de aceptación:**
1. WHEN se evalúen las dependencias funcionales sobre `control_lote_almacen` THE SYSTEM SHALL verificar que `{responsable_control_id}` determina `{deposito_id}` sin ser superclave de la relación.
2. WHEN se descomponga la relación THE SYSTEM SHALL crear `responsable_deposito(responsable_control_id PK, deposito_id)` y `control_lote_responsable(lote_id, responsable_control_id, PK(lote_id, responsable_control_id))` con sus respectivas claves foráneas.

### RU-U4-02: Migración de datos sin pérdida en transacción reversible y plan de reversión
- **Como** administrador de base de datos,
- **Quiero** migrar los datos hacia las tablas en FNBC dentro de una transacción explícita y contar con un plan de reversión probado,
- **Para que** no exista pérdida de datos ni tuplas espurias y sea posible restituir el estado original ante cualquier contingencia.

**Criterios de aceptación:**
1. WHEN se ejecute la migración hacia `control_lote_responsable` y `responsable_deposito` THE SYSTEM SHALL correr dentro de un bloque `BEGIN ... COMMIT` y verificar mediante `EXCEPT` en ambos sentidos contra la vista `v_control_lote_almacen_compat` que la diferencia sea exactamente 0 filas.
2. IF la validación de equivalencia detecta diferencias mayores a cero THE SYSTEM SHALL abortar la transacción con `RAISE EXCEPTION`.
3. WHEN se requiera revertir la migración THE SYSTEM SHALL disponer de un procedimiento transaccional probado que reconstruya `control_lote_almacen` desde la reunión natural `R1 ⋈ R2` sin pérdida de información.

### RU-U4-03: Desnormalización controlada con salvaguardas transaccionales
- **Como** responsable de rendimiento de base de datos,
- **Quiero** preagregar las ventas diarias por categoría en `venta_categoria_dia` mantenida por disparadores y auditada mediante consulta de reconciliación,
- **Para que** el reporte Top-5 categorías del día reduzca su costo de lectura sin perder consistencia respecto de las tablas fuente.

**Criterios de aceptación:**
1. WHEN ocurra un `INSERT`, `UPDATE` o `DELETE` en `detalle_pedido`, o cambios de fecha/baja lógica en `pedido` o de categoría en `producto` THE SYSTEM SHALL actualizar incrementalmente `venta_categoria_dia` en la misma transacción.
2. WHEN se ejecute el script de auditoría `FULL OUTER JOIN` entre `venta_categoria_dia` y el recálculo desde las tablas normalizadas THE SYSTEM SHALL devolver 0 filas desincronizadas.
