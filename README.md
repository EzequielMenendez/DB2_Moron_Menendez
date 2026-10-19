# DB2 — Unidad 4: FNBC y Desnormalización Controlada (Food Store)

Trabajo práctico de la Unidad 4 sobre la base **`food_store`** (PostgreSQL 18).

## Entregables

| Artefacto | Contenido |
|-----------|-----------|
| [`db/tp_fnbc_control_lote.sql`](db/tp_fnbc_control_lote.sql) | **Parte 1** — análisis de FNBC de `ControlLoteAlmacen`: dependencias funcionales, claves candidatas, violación de FNBC, descomposición sin pérdida, vista de compatibilidad y migración verificada. |
| [`db/tp_desnormalizacion_top_categorias.sql`](db/tp_desnormalizacion_top_categorias.sql) | **Parte 2** — desnormalización controlada del reporte Top-5 categorías del día: tabla resumen `venta_categoria_dia` + disparadores de sincronización, consulta optimizada y script de auditoría. |
| [`docs/informe_unidad4_fnbc.md`](docs/informe_unidad4_fnbc.md) | **Informe** — DFs, claves candidatas, demostración de violación de FNBC, justificación de unión sin pérdida, comparativa `EXPLAIN ANALYZE` antes/después y justificación del patrón elegido. |

## Scripts de apoyo

- [`db/preparar_food_store.sql`](db/preparar_food_store.sql) — alinea el esquema de `food_store` a la consigna (renombrados, `subtotal` GENERADA, `eliminado`) y la puebla de forma determinista (100.000 pedidos / 300.000 líneas).

## Reproducir

```powershell
psql -U postgres -d food_store -f db\preparar_food_store.sql
psql -U postgres -d food_store -f db\tp_fnbc_control_lote.sql
psql -U postgres -d food_store -f db\tp_desnormalizacion_top_categorias.sql
```

## Resultados clave

- **Parte 1:** `control_lote_almacen` viola FNBC por `{ResponsableControlID} → {DepositoID}`; descomposición en `control_lote_responsable` ⋈ `responsable_deposito` sin pérdida (verificado con `EXCEPT` en ambos sentidos).
- **Parte 2:** reporte Top-5 pasa de **57,1 ms** (`Parallel Seq Scan` sobre `detalle_pedido`) a **0,071 ms** (`Index Scan` sobre `venta_categoria_dia`); auditoría de desincronización = **0 filas**.
