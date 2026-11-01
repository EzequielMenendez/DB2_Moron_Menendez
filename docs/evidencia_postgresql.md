# PostgreSQL de pruebas y procedencia del CSV

El 2026-11-01 se inicializó un clúster PostgreSQL 18 nuevo en
`%TEMP%/codex-tp8-pg-20261101/data`, puerto 55438, solo localhost.
La base de ese clúster se llamó `food_store`. No se accedió a los servicios
ni a las bases ya existentes en el equipo.

La rama NoSQL no contiene el esquema original completo ni un respaldo.
`movil/servidor_pruebas.sql` crea una **fixture mínima sintética**, derivada de
los nombres `producto.id/nombre/precio/stock/activo` usados en
`db/preparar_food_store.sql`. No equivale a haber restaurado la base real.
`activo=FALSE` es la baja lógica en esta adaptación; la vista exporta esa
condición como `eliminado=TRUE` y retiene la fila como lápida.

## Creación y exportación ejecutadas

```powershell
createdb -h 127.0.0.1 -p 55438 -U postgres food_store
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -f movil/servidor_pruebas.sql -f movil/snapshot_postgresql.sql
```

En psql conectado a esa base aislada, desde la raíz del repositorio:

```sql
\copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/servidor_snapshot.csv' CSV HEADER
UPDATE tp8_servidor.producto SET precio=4600 WHERE id=10;
\copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/snapshots/c2_precio.csv' CSV HEADER
UPDATE tp8_servidor.producto SET precio=4500, stock=1 WHERE id=10;
\copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/snapshots/c3_stock.csv' CSV HEADER
UPDATE tp8_servidor.producto SET stock=10, activo=FALSE WHERE id=10;
\copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/snapshots/c4_baja.csv' CSV HEADER
UPDATE tp8_servidor.producto SET activo=TRUE WHERE id=10;
```

Cada exportación dio `COPY 2`. La cabecera es
`id,nombre,precio_centavos,stock,disponible,eliminado,fecha_copia`;
los booleanos reales de psql son `t/f`, no `0/1`.
Fecha base: `2026-11-01T19:45:35Z`, generada por la vista.

Las modificaciones anteriores preparan los casos en el servidor sintético;
no son operaciones de la tablet ni ventas. El estado del servidor luego
de preparar los casos y antes de simular es:

| Tabla / campo | Valor |
|---|---|
| Cantidad de pedidos | 1 |
| Producto 10 | precio 4500.00; stock 10; activo true |
| Producto 15 | precio 1200.00; stock 5; activo true |

Consulta a repetir inmediatamente después del simulador, sin preparar otro caso:

```sql
SELECT count(*) AS pedidos FROM tp8_servidor.pedido;
SELECT id,precio,stock,activo FROM tp8_servidor.producto ORDER BY id;
```

Después de que el simulador generó la demo y probó C2, C3 y C4 con los CSV
exportados, se repitieron las dos consultas en el mismo servidor. Resultado
real: **pedidos=1; producto 10 precio=4500.00, stock=10, activo=t;
producto 15 precio=1200.00, stock=5, activo=t**. Coincide exactamente con
el estado anterior a la simulación. No cambió precio, stock ni cantidad de
pedidos. `SIMULADO_APROBADO` no crea una venta ni reserva unidades.

Se detuvo únicamente ese clúster temporal con `pg_ctl -D
%TEMP%/codex-tp8-pg-20261101/data -m fast -w stop`; salida real
`server stopped`. No queda un servidor adicional ejecutándose.
