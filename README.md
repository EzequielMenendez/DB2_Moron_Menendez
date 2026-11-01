# DB2 · Food Store · TP8 · rama sqlite

Equipo: Moron / Menendez · Base de Datos II · UTN · 2026.

TP8 agrega la base de una tablet sin conexión y una **simulación** de sincronización. Se desarrolló desde la rama `NoSQL`, conservando las unidades 4–7. La tablet guarda borradores; **SIMULADO_APROBADO no confirma ventas ni reserva stock**.

## Entrega

- `movil/schema_sqlite.sql`: tablas STRICT, restricciones y claves foráneas.
- `movil/pruebas_sqlite.sql`: COMMIT, ROLLBACK, C1 y errores esperados C7.
- `movil/semaforo.sql`: rojo antes que amarillo; procesa solo PENDIENTE.
- `movil/cargar_cache.sql`: recarga de catálogo con conversión `t/f` y lápidas.
- `movil/servidor_snapshot.csv`, `snapshots/`: exportaciones reales de un PostgreSQL de pruebas con datos inventados.
- `movil/foodstore_movil.db`: ejemplo con catálogo sintético y un borrador pendiente.
- `movil/simulador.py`, `tests/`: reproducción sin paquetes Python externos.
- `movil/servidor_pruebas.sql`, `snapshot_postgresql.sql`: fixture mínima y vista del contrato móvil.
- `docs/informe.pdf`: informe de TP8; fuente editable `docs/informe_tp8.md`.
- `docs/kiro/`: cuatro requisitos EARS, diseño y tareas; [simulación documental del flujo Specs](docs/kiro/simulacion_kiro.md), reconstruida por Codex después de implementar.
- `docs/evidencia_*.md`, `bitacora_ia.md`, `DUIA.md`, `defensa_tp8.md`: resultados, alcance y preparación de la defensa.

## 1. Requisitos y comprobación de versión

Python 3.10+ con SQLite **3.37+**. Alternativa manual: cliente sqlite3 3.37+ o DB Browser con ese motor. Para repetir las exportaciones, PostgreSQL 16+ y `psql` (se verificó con PostgreSQL 18).

Desde la raíz del repositorio:

```powershell
python -c "import sqlite3; print(sqlite3.sqlite_version)"
python -m unittest discover -s movil/tests -v
```

En Windows también se puede usar `py -3.10` en lugar de `python`. El `sqlite3.exe` encontrado en el PATH del entorno de preparación es 3.19.1: no soporta STRICT. Por eso la ejecución verificada usa el motor integrado de Python, sin depender de ese ejecutable.

## 2. Crear SQLite desde cero y simular

Los siguientes comandos usan únicamente archivos sintéticos, sin conexión PostgreSQL. El nombre de salida debe ser nuevo: el creador rechaza sobrescribir un archivo existente.

```powershell
python movil/simulador.py --crear-demo movil/demo_nueva.db
python movil/simulador.py --evaluar movil/demo_nueva.db
python movil/simulador.py --evaluar movil/demo_nueva.db
```

La primera evaluación devuelve `SIMULADO_APROBADO`; repetirla conserva el estado. Para observar C2, crear otra base nueva y cargar el CSV de precio modificado antes de evaluarla:

```powershell
python movil/simulador.py --crear-demo movil/demo_precio.db
python movil/simulador.py --evaluar movil/demo_precio.db --snapshot movil/snapshots/c2_precio.csv
```

Devuelve `CONFLICTO`. La prueba C2 muestra la aceptación actualizando el precio visto y creando una solicitud con otro UUID; no cambia PostgreSQL. Los casos completos C1–C7 y la aceptación están automatizados en `movil/tests/` y explicados en `docs/evidencia_casos.md`.

## 3. Alternativa SQL manual

Con **sqlite3 3.37+**, desde la raíz ejecutar `sqlite3 movil/manual_nueva.db` sobre un archivo nuevo y luego:

```sql
.bail on
.read movil/schema_sqlite.sql
.import --csv --skip 1 movil/servidor_snapshot.csv snapshot_servidor
.read movil/cargar_cache.sql
.bail off
.read movil/pruebas_sqlite.sql
.read movil/semaforo.sql
SELECT solicitud_uuid,estado,motivo FROM cola_sync;
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

C7 produce dos errores **intencionales** de CHECK y FK, seguidos de ROLLBACK y conteo cero para los borradores inválidos. Por eso ese archivo requiere continuar tras los errores. El runner automatizado verifica que se producen exactamente las excepciones previstas y que no quedan filas nuevas; otros errores no deben darse por aprobados. `foreign_keys=ON` se necesita en cada conexión.

Para importar otra instantánea completa, borrar primero las filas de `snapshot_servidor`, importar el nuevo CSV y ejecutar `cargar_cache.sql`; no borrar `producto_cache`, porque puede estar referenciado por borradores.

## 4. Repetir la parte PostgreSQL

La rama de referencia no incluye el esquema original completo: la entrega incorpora una **fixture mínima sintética**, compatible con los nombres usados por los scripts anteriores. No se afirma haber restaurado la base real del equipo.

Usar una instancia PostgreSQL nueva y aislada. En los comandos siguientes `55438` es el puerto utilizado en la prueba documentada; debe corresponder a esa instancia de pruebas. No ejecutar estos archivos sobre bases existentes sin revisar destino.

```powershell
createdb -h 127.0.0.1 -p 55438 -U postgres food_store
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -f movil/servidor_pruebas.sql -f movil/snapshot_postgresql.sql
```

En `psql`, desde la raíz:

```sql
\copy (SELECT * FROM tp8_servidor.v_snapshot_movil ORDER BY id) TO 'movil/servidor_snapshot.csv' CSV HEADER
SELECT count(*) AS pedidos FROM tp8_servidor.pedido;
SELECT id,precio,stock,activo FROM tp8_servidor.producto ORDER BY id;
```

Crear y evaluar una base SQLite nueva con ese CSV. Repetir las dos consultas PostgreSQL después: deben conservarse cantidad de pedidos, precio y stock. Las modificaciones de precio, stock y baja para preparar C2–C4 y sus exportaciones se detallan en `docs/evidencia_postgresql.md`. Son preparaciones deliberadas de escenarios, no acciones del móvil. Cada CSV anota la fecha UTC de copia. `activo=FALSE` se adapta como baja lógica y se exporta como lápida; la vista no filtra esa fila.

Para repetir los probes de revisión sin modificar roles globales:

```powershell
psql -h 127.0.0.1 -p 55438 -U postgres -d food_store -X -v ON_ERROR_STOP=1 -f movil/pruebas_revision_postgresql.sql
```

El esquema `tp8_servidor` se crea una sola vez: si ya existe, la fixture falla y no borra datos para continuar. Para otra ejecución completa usar otra instancia descartable.

## 5. Alcance de revisión y trabajo personal

La revisión TP8 detectó problemas en scripts históricos, entre ellos credenciales literales y autenticación de demostración que ignora la contraseña. **No ejecutar automáticamente los scripts de unidades anteriores**. Se conservaron como referencia y los hallazgos quedan documentados para una corrección separada; el paquete TP8 no necesita esos scripts para funcionar.

La asistencia real fue **Codex**. Los archivos de especificación están preparados y se agregó una simulación documental posterior del flujo Specs; esta no equivale a una sesión real de Kiro ni de OpenCode Plan. Antes de entregar, el equipo debe realizar esos pasos pedidos por la consigna, revisar y reproducir los resultados, completar la DUIA oficial si tiene un formato obligatorio y efectuar la defensa personal. No se inventan firmas ni validaciones humanas.

El ZIP de TP8 se puede entregar sin publicar el repositorio. La rama `sqlite` ya fue publicada por pedido del usuario; esta actualización documental debe publicarse por separado. No se creó una etiqueta `tp8` ni se realizó la entrega en campus.

## Referencia anterior: Unidades 4–7

La rama `NoSQL` incluye `sql/consultas_mongodb.js`, `sql/consultas_postgresql.sql`, `docs/informe_nosql.md` y `BITACORA.md`, además de los trabajos relacionales anteriores. Se conservan en el checkout con su historial; TP8 agrega archivos independientes.
