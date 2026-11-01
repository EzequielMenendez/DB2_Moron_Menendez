# Evidencia de la revisión con Codex - TP8

Fecha: 2026-11-01. Ejecución real sobre PostgreSQL 18 en una instancia
temporal nueva, escuchando exclusivamente en `127.0.0.1:55438`.
No se usaron credenciales ni datos de bases preexistentes.
No se ejecutaron los scripts históricos de roles ni de restauración.

Comando (desde la raíz; `psql` de PostgreSQL 18):

```powershell
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -f movil/pruebas_revision_postgresql.sql
```

## U4 - Descartado: quitar subtotal por ser un dato duplicado

El probe reproduce la definición `GENERATED ALWAYS AS (cantidad *
precio_unitario) STORED` de `db/preparar_food_store.sql`.

| Operación | Resultado ejecutado |
|---|---|
| INSERT cantidad=2, precio=4500 | subtotal=9000.00 |
| UPDATE cantidad=3 | subtotal=13500.00 |
| UPDATE subtotal=1 | error 428C9, capturado por el bloque de prueba |

No es un subtotal editable que pueda desincronizarse con esos dos campos.
Se descarta eliminarlo: el motor mantiene la fórmula. Esto no prueba
integridad de importes externos a esas columnas.

## U5 - Aceptado: autenticación de demostración ignora la contraseña

Se copió el cuerpo de `fn_autenticar` de `sql/roles.sql` en una función
`pg_temp`, con una tabla TEMP `cliente` y una dirección inventada bajo
`example.invalid`. No se ejecutó el resto del script, que administra roles.

| Entrada | Salida real |
|---|---|
| Email sintético existente, clave `prueba-a` | true |
| Mismo email, clave distinta `prueba-b` | true |
| Email inexistente | false |

Confirma que basta la existencia del email. Aceptado como defecto histórico
pendiente de un cambio de seguridad separado; TP8 no altera autenticación.
La corrección debe verificar un hash real y su contrato antes de habilitarla.

## U4 - Aceptado: inferencia incorrecta sobre 3FN

El script FNBC se ejecutó también en el esquema aislado `tp8_revision`:

```powershell
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -c 'CREATE SCHEMA tp8_revision; SET search_path=tp8_revision' -f db/tp_fnbc_control_lote.sql
```

Resultado: FD1 y FD2 tienen 0 violaciones; 3 filas originales y 3 por vista;
ambas diferencias EXCEPT dan 0. Esto comprueba la instancia y la reunión.
El comentario «NO FNBC (y por lo tanto tampoco en 3FN)» no se desprende de
esos resultados: con las dependencias declaradas las claves candidatas son
{lote, depósito} y {lote, responsable}; los tres atributos son primos.
La relación puede estar en 3FN y violar FNBC. Se acepta la observación
documental y queda pendiente corregir ese comentario histórico fuera del TP8.

## Alcance

Revisión hecha por **Codex**, no por OpenCode en modo Plan. El informe
separa estos resultados de la práctica personal pedida con Kiro/OpenCode.
Las tablas TEMP y la función del primer probe terminan con ROLLBACK.
