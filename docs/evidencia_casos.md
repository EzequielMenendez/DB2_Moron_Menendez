# Casos reproducidos TP8

Fecha: 01/11/2026. Comando comun desde la raiz: `python -m unittest discover -s movil/tests -v`.
Resultado final: **25 pruebas, OK** usando Python 3.10 / SQLite 3.37.2. Cada prueba crea una SQLite nueva (memoria o archivo temporal), activa foreign_keys y consume scripts reales.

| Caso | Comando / prueba | Resultado observado y explicacion |
|---|---|---|
| C1 | test_sqlite.TabletTest.test_c1_catalogue_offline | IDs 10 y 15 disponibles. Consulta local sin abrir conexion de red. |
| C2 | test_snapshots_postgresql.SnapshotPostgresqlTest.test_csv_c2_precio_conflicto_y_aceptacion | CSV c2_precio.csv fija 460000 frente a 450000 visto: CONFLICTO. UPDATE del item a 460000 + nuevo UUID produce SIMULADO_APROBADO y conserva la solicitud CONFLICTO previa. |
| C3 | test_snapshots_postgresql.SnapshotPostgresqlTest.test_csv_c3_stock_rechazado | CSV stock1 frente a cantidad2: RECHAZADO. No se reserva ni descuenta stock. |
| C4 | test_snapshots_postgresql.SnapshotPostgresqlTest.test_csv_c4_baja_rechazo_y_lapida | Producto10 eliminado=t: RECHAZADO. Cache conserva fila10 eliminado=1 e item referenciado; catalogo visible devuelve solo15. |
| C5 | test_sqlite.TabletTest.test_c5_green_does_not_mutate_snapshot | SIMULADO_APROBADO y snapshot_servidor identica antes/despues. No representa una venta. |
| C6 | test_sqlite.TabletTest.test_c6_duplicate_uuid_and_reevaluation | INSERT mismo UUID lanza IntegrityError (UNIQUE); cola conserva una fila. Se cambia stock de snapshot a0 y se repite semaforo: estado y motivo finales permanecen iguales. |
| C7 | test_sqlite.TabletTest.test_c7_zero_and_missing_product_atomic_rollback | cantidad0 viola CHECK; producto999 viola FK. Cada operacion revierte tambien su cabecera: 0 nuevas filas. |

Para ejecutar un solo caso: `python -m unittest discover -s movil/tests -p test_snapshots_postgresql.py -v` (C2-C4) o `python -m unittest discover -s movil/tests -p test_sqlite.py -v` (C1-C7 y bordes).

## Comandos concretos de demostracion

```powershell
python movil/simulador.py --crear-demo movil/demo_nueva.db
python movil/simulador.py --evaluar movil/demo_nueva.db --snapshot movil/snapshots/c2_precio.csv
# Resultado: CONFLICTO, Precio actual distinto del precio visto; requiere aceptacion
```

El nombre demo_nueva.db debe estar libre. El generador rechaza sobrescrituras. La DB entregada foodstore_movil.db tiene un borrador PENDIENTE para demostrarlo en vivo; usar una copia para no modificar el artefacto entregado.

Aceptacion de C2 en la copia SQLite, luego ejecutar semaforo.sql:

```sql
BEGIN;
UPDATE item_borrador SET precio_centavos_visto=460000
WHERE id_local='10000000-0000-4000-8000-000000000001' AND producto_id=10;
INSERT INTO cola_sync VALUES ('20000000-0000-4000-8000-000000000002',
 '10000000-0000-4000-8000-000000000001','PENDIENTE',NULL);
COMMIT;
```

C3 y C4: crear otra DB con --crear-demo y evaluar con snapshots/c3_stock.csv o snapshots/c4_baja.csv, respectivamente. C5: evaluar una DB nueva con la instantanea base.

## Integridad y transacciones

pruebas_sqlite.sql contiene un COMMIT completo y un ROLLBACK; sus dos errores intencionales C7 se verifican mediante test_pruebas_sql_script_expected_errors. El runner comprueba que queda exactamente 1 cabecera, 1 item y 1 solicitud, con foreign_key_check vacio. En el shell SQLite, estos errores esperados dan salida de error; no confundirlos con fallos no previstos.

El ejecutable sqlite3.exe del PATH es 3.19.1 y no soporta STRICT. Se verifico con Python 3.10 (SQLite3.37.2) y Python bundled; para los comandos .read/.import se necesita instalar un shell SQLite >=3.37. No se afirma haber ejecutado el shell antiguo con exito.

## Idempotencia real y limites

La PK local evita duplicar solicitudes en esta tablet. En un sistema real, la proteccion debe residir tambien en el servidor: UUID unico persistido junto a su resultado, misma transaccion que valida precio/stock y confirma la venta; un reenvio devuelve el resultado previo. Un resultado verde de esta simulacion no promete stock futuro ni confirma pago.

## PostgreSQL sin modificaciones por la tablet

Las variantes se prepararon en un cluster temporal PostgreSQL18 exclusivo con datos inventados, se exportaron por psql y se restauro el estado base antes de simular. Consultas y comprobacion de stock/precios/pedidos antes/despues: ver evidencia_postgresql.md. La simulacion solo abre archivos SQLite y CSV; no tiene cliente ni credenciales PostgreSQL.

## Ejecucion individual verificada

Los siguientes comandos se ejecutaron con resultado `Ran 1 test ... OK` cada uno. C7 incluye sus dos subcasos de cantidad cero y producto inexistente.

```powershell
# C1
python -m unittest discover -s movil/tests -p test_sqlite.py -k test_c1_catalogue_offline -v
# C2
python -m unittest discover -s movil/tests -p test_snapshots_postgresql.py -k test_csv_c2_precio_conflicto_y_aceptacion -v
# C3
python -m unittest discover -s movil/tests -p test_snapshots_postgresql.py -k test_csv_c3_stock_rechazado -v
# C4
python -m unittest discover -s movil/tests -p test_snapshots_postgresql.py -k test_csv_c4_baja_rechazo_y_lapida -v
# C5
python -m unittest discover -s movil/tests -p test_sqlite.py -k test_c5_green_does_not_mutate_snapshot -v
# C6
python -m unittest discover -s movil/tests -p test_sqlite.py -k test_c6_duplicate_uuid_and_reevaluation -v
# C7
python -m unittest discover -s movil/tests -p test_sqlite.py -k test_c7_zero_and_missing_product_atomic_rollback -v
```

Tambien se ejecutaron los comandos de README de crear/evaluar demo nueva y demo con precio modificado en un directorio temporal: verde dos veces sin reevaluacion y CONFLICTO dos veces sin reevaluacion. La DB entregada se verifico con integrity_check=ok, foreign_key_check sin filas y una solicitud PENDIENTE.
