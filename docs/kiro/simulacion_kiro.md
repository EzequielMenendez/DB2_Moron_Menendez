# Simulación documental del flujo Specs de Kiro · TP8

**Naturaleza:** simulación elaborada por Codex a pedido del usuario.
**Momento:** reconstrucción posterior a la implementación de TP8.
**No es:** transcripción de una sesión real, respuesta emitida por Kiro ni evidencia de haber usado Kiro antes de programar.

Se reutilizan [requirements.md](requirements.md), [design.md](design.md) y [tasks.md](tasks.md), ya presentes en el proyecto. La documentación previa registra que esos archivos se prepararon con Codex antes de los scripts; este ejercicio posterior no cambia su autoría ni esa cronología. No se ejecutan herramientas externas ni nuevas pruebas en esta simulación.

## 1. Solicitud y prompt para la fase de requisitos

Pedido real que origina este documento: «Ok simula el uso de kiro ya q lo piden para el tp8».

**Prompt propuesto para reproducir personalmente en Kiro; no enviado a Kiro en esta asistencia:**

> Prepará una especificación para el TP8 de Base de Datos II, Food Store en una feria sin conexión, usando como referencia el proyecto de la rama NoSQL. No implementes todavía. Redactá cuatro requisitos EARS trazables a C1–C7 y luego un diseño y tareas breves. PostgreSQL decide precios, stock y ventas; SQLite solo consulta una cache y guarda borradores. Se requieren cuatro tablas STRICT, claves foráneas por conexión, precios enteros en centavos, transacciones, importación de instantáneas CSV con booleanos t/f y conservación de lápidas. El semáforo procesa solo PENDIENTE: rechazo antes que cambio de precio; la coincidencia es SIMULADO_APROBADO y nunca una venta. El reenvío del mismo UUID debe fallar por PK sin reevaluar solicitudes finales. Usá exclusivamente datos inventados y no solicites ni copies credenciales. Señalá lo que falta comprobar. Si ya hay implementación, revisala contra los requisitos sin afirmar que fue generada por vos.

## 2. Respuesta SIMULADA · Requisitos

La siguiente salida es una reconstrucción de Codex basada en la especificación existente, no una respuesta de Kiro.

| ID | Requisito EARS resumido | Caso que lo prueba |
|---|---|---|
| REQ-01 | WHEN la tablet opere sin conexión THE SYSTEM SHALL consultar el catálogo local y guardar borrador, ítems y solicitud atómicamente. | C1 y C7; COMMIT/ROLLBACK. |
| REQ-02 | WHEN una solicitud PENDIENTE contenga producto ausente, no disponible, eliminado o con stock insuficiente THE SYSTEM SHALL marcar RECHAZADO con prioridad sobre cambios de precio. | C3 y C4; bordes de ausencia, indisponibilidad y prioridad roja. |
| REQ-03 | WHEN no haya rechazo y cambie un precio THE SYSTEM SHALL marcar CONFLICTO; WHEN se acepte el precio THE SYSTEM SHALL conservar la solicitud anterior y evaluar otra con UUID nuevo. | C2, incluida aceptación. |
| REQ-04 | WHEN todos los ítems coincidan THE SYSTEM SHALL marcar SIMULADO_APROBADO sin confirmar ventas; WHEN se repita un UUID THE SYSTEM SHALL impedir duplicados y no reevaluar estados finales. | C5 y C6. |

**Decisión de esta revisión:** conservar los cuatro requisitos existentes. Cubren los siete casos sin incorporar una app, reservas de stock ni una venta real, que excederían esta simulación.

## 3. Respuesta SIMULADA · Diseño

1. Mantener PostgreSQL como fuente de verdad y MongoDB como proyección de pedidos de la Unidad 7. SQLite no escribe en ninguno de los dos motores.
2. Usar `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync` STRICT, con CHECK y FK. Registrar alias sintéticos de operador; no copiar clientes ni cuentas reales.
3. Importar CSV a `snapshot_servidor`; convertir `t/f` al actualizar cache y conservar las filas dadas de baja o ausentes para no romper referencias.
4. Evaluar ítems agrupados por solicitud: rojo, amarillo y verde en ese orden; rechazar también borradores vacíos. Actualizar únicamente PENDIENTE y guardar un motivo.
5. Guardar cabecera, ítems y solicitud como una unidad transaccional. El reintento aceptado utiliza UUID nuevo; un reenvío del UUID previo no modifica su resultado.
6. Separar la validación local de una implementación futura de venta real, que necesitaría transacción y clave de idempotencia en el servidor.

**Decisión de esta revisión:** reutilizar [design.md](design.md), sin introducir servicios ni nuevos modelos. La fixture PostgreSQL es mínima y sintética porque la rama de referencia no incluye el esquema original completo.

## 4. Respuesta SIMULADA · Tareas y criterios de cierre

Esta lista representa el plan que se reconstruye hoy. Su estado técnico remite al trabajo previo documentado; no significa que Kiro haya ejecutado o aprobado las tareas.

| Paso reconstruido | Criterio de cierre | Evidencia previa disponible |
|---|---|---|
| Definir requisitos y diseño | Cuatro EARS con casos; responsabilidades de los motores claras. | Archivos existentes `requirements.md` y `design.md`. |
| Implementar esquema e integridad | STRICT, CHECK, FK; entradas inválidas rechazadas sin restos. | `movil/schema_sqlite.sql`; C7 y pruebas de dominios. |
| Importar y recargar cache | Contrato CSV válido; booleanos correctos; lápidas conservadas. | `movil/cargar_cache.sql`; C1 y C4. |
| Implementar semáforo | Prioridad roja, conflicto de precio, verde sin venta e idempotencia. | `movil/semaforo.sql`; C2–C6 y bordes. |
| Probar la transacción y los casos | COMMIT/ROLLBACK y C1–C7 reproducibles. | `movil/pruebas_sqlite.sql`; `../evidencia_casos.md`. |
| Exportar y verificar servidor | Instantáneas reales sintéticas; pedidos, stock y precios intactos tras simular. | `../evidencia_postgresql.md`. |
| Revisar documentación y defender | Explicación individual y registro real de herramientas. | Guion disponible; ejecución personal pendiente. |

La lista original de implementación continúa en [tasks.md](tasks.md). No se agregan marcas de ejecución Kiro a sus tareas ya completadas con Codex.

## 5. Decisiones contrastadas con el código y las evidencias existentes

Estos contrastes son una revisión de archivos y resultados previamente registrados, no una ejecución nueva de pruebas:

- **Rechazo antes de conflicto:** `semaforo.sql` selecciona RECHAZADO antes de comprobar precios; la evidencia de casos contiene C3/C4 y la suite incluye `test_red_precedes_yellow`.
- **Lápidas en lugar de borrado físico:** `cargar_cache.sql` hace UPSERT y marca ausentes como eliminados; C4 conserva la fila 10 y su referencia mientras el catálogo solo devuelve la 15.
- **Aceptar precio sin sobrescribir historia de solicitud:** C2 actualiza el importe visto del ítem y crea otro UUID; conserva la solicitud previa CONFLICTO.
- **Idempotencia limitada a la simulación:** `WHERE estado='PENDIENTE'` impide reevaluar estados finales; C6 verifica error UNIQUE y estado/motivo conservados. No se afirma idempotencia distribuida real.
- **Servidor sin ventas nuevas:** la evidencia PostgreSQL registra pedidos=1 y existencias 10/5 antes y después; el simulador consume archivos y escribe SQLite.

Se descarta reconstruir una conversación como si hubiera ocurrido antes de implementar o asignar a Kiro las pruebas de Codex: no existe esa evidencia.

## 6. Cómo repetirlo personalmente en Kiro

1. Abrir una copia del proyecto y facilitar la consigna y los tres archivos de especificación. No adjuntar `.env`, respaldos ni scripts históricos con credenciales literales.
2. Usar el flujo de especificaciones disponible en la instalación de Kiro y pegar el prompt propuesto. Aclarar que el código ya existe y que se busca una revisión o reconstrucción posterior.
3. Revisar personalmente requisitos, diseño y tareas; comparar cambios con esta matriz y resolver las diferencias antes de modificar el código.
4. Guardar la salida real y registrar fecha, herramienta y decisiones en la bitácora. Identificar por separado lo simulado aquí y lo efectivamente producido por Kiro; no alterar retroactivamente la cronología.
5. Reproducir los casos con los comandos de `../evidencia_casos.md`. Si corresponde ejecutar OpenCode Plan, registrar su revisión real por separado; este documento no la sustituye.

**Pendiente:** uso real de Kiro/OpenCode, revisión del equipo, DUIA oficial cuando corresponda y ensayo/defensa. La simulación documental queda realizada; la exigencia de haber utilizado esas herramientas no queda acreditada.
