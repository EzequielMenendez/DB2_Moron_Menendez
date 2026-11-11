# Design: Refactorización FNBC y Desnormalización Controlada — Food Store (Unidad 4)

## 1. Descomposición a Forma Normal de Boyce-Codd (FNBC)

### Esquema heredado y diagnóstico
- Relación original: `control_lote_almacen(lote_id, deposito_id, responsable_control_id)` con `PK(lote_id, deposito_id)`.
- Dependencias funcionales:
  - `FD1: {lote_id, deposito_id} -> {responsable_control_id}` (determinante es clave candidata `K1`).
  - `FD2: {responsable_control_id} -> {deposito_id}` (determinante NO es superclave; viola FNBC).
- Nota teórica: como las claves candidatas son `{lote_id, deposito_id}` y `{lote_id, responsable_control_id}`, los tres atributos son primos (cumple 3FN pero viola FNBC).

### Esquema refactorizado (FNBC)
1. **`responsable_deposito` (R2):**
   - Columnas: `responsable_control_id BIGINT PRIMARY KEY REFERENCES usuario(id)`, `deposito_id BIGINT NOT NULL REFERENCES deposito(id)`.
2. **`control_lote_responsable` (R1):**
   - Columnas: `lote_id BIGINT NOT NULL REFERENCES lote(id)`, `responsable_control_id BIGINT NOT NULL REFERENCES usuario(id)`, `PRIMARY KEY (lote_id, responsable_control_id)`.
3. **Vista de compatibilidad (`v_control_lote_almacen_compat`):**
   - `SELECT r1.lote_id, r2.deposito_id, r1.responsable_control_id FROM control_lote_responsable r1 NATURAL JOIN responsable_deposito r2;`
   - Garantiza unión sin pérdida porque el atributo común `responsable_control_id` es superclave (PK) de `R2`.

## 2. Transacción de Migración y Plan de Reversión Obligatorio

- **Migración transaccional:** Se ejecuta dentro de `BEGIN ... COMMIT` en `db/tp_fnbc_control_lote.sql`. Un bloque `DO $$` verifica automáticamente que `(original EXCEPT vista) UNION ALL (vista EXCEPT original)` tenga `count(*) = 0`.
- **Plan de reversión:**
  - *Fase en vuelo:* `ROLLBACK` inmediato ante cualquier error en la transacción.
  - *Fase post-commit:* Reconstrucción íntegra de `control_lote_almacen` a partir de `v_control_lote_almacen_compat` (`R1 ⋈ R2`), verificación de conteos y eliminación de `v_control_lote_almacen_compat`, `control_lote_responsable` y `responsable_deposito`. Probado en el script dentro de un bloque `BEGIN ... ROLLBACK`.

## 3. Desnormalización Controlada (`venta_categoria_dia`)

- **Problema medido (`EXPLAIN ANALYZE`):** La consulta normalizada de Top-5 categorías del día barre 300.000 filas de `detalle_pedido` y 100.000 de `pedido` (`~57,108 ms`).
- **Solución:** Tabla resumen `venta_categoria_dia(fecha, categoria_id, total_vendido)` con índice `idx_vcd_fecha(fecha, total_vendido DESC)`. Reduce el tiempo a `0,071 ms` (~800x más rápido).
- **Salvaguardas:**
  1. Cinco disparadores transaccionales (`trg_dp_ai`, `trg_dp_au`, `trg_dp_ad`, `trg_ped_au`, `trg_prod_au`) que invocan `fn_ajusta_venta_categoria`.
  2. Consulta de auditoría con `FULL OUTER JOIN` e `IS DISTINCT FROM` para detectar cualquier desvío (0 filas desincronizadas).
  3. Demostración en vivo mediante transacción reversible (`BEGIN ... ROLLBACK`).
