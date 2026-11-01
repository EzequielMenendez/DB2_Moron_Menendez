# Bitácora de IA · TP8

Fecha de preparación: 01/11/2026. Herramienta utilizada en esta asistencia: **Codex**. Estas entradas describen pedidos y decisiones de esta sesión; no son un registro inventado de ejecución en Kiro u OpenCode ni acreditan revisión humana.

| Pedido recibido / tarea derivada | Aceptado | Descartado y motivo | Cómo se comprueba |
|---|---|---|---|
| «Hacer TP8 usando la rama NoSQL como referencia y crear sqlite». | Partir de `NoSQL`, conservar unidades anteriores y agregar SQLite, scripts, pruebas y documentos de TP8. | Reemplazar el modelo PostgreSQL o convertir los resultados verdes en ventas: contradice la consigna. | Historial de rama, diff y pruebas del semáforo; PG solo entrega instantáneas. |
| Analizar los scripts de la cursada y justificar hallazgos. | Revisar todos los scripts y probar hallazgos aislados en datos sintéticos. Registrar autenticación de ejemplo insegura y controles de restauración insuficientes. | Ejecutar `roles.sql` o `restore_test.ps1` sobre el entorno existente: contienen operaciones globales/destructivas y credenciales literales. | Inventario y evidencia de revisión; no se copian credenciales. |
| Evaluar si conviene eliminar el subtotal almacenado del detalle. | Conservar la definición existente `GENERATED ALWAYS AS (...) STORED`. | Eliminarlo por supuesta desincronización: el motor lo recalcula y rechaza su sobrescritura. | Prueba PostgreSQL aislada, detalle en `evidencia_revision.md`. |
| Preparar el contrato del CSV PostgreSQL/SQLite. | Staging con booleanos `t/f`, conversión explícita y lápidas; precios enteros en centavos. | Interpretar `t/f` mediante conversión numérica directa o borrar la fila dada de baja: altera disponibilidad o rompe referencias. | Pruebas SQLite y exportación PostgreSQL de ejemplo. |
| «Ok simula el uso de kiro ya q lo piden para el tp8». | Codex reconstruye documentalmente el flujo Specs con prompt, cuatro EARS, diseño, tareas y trazabilidad en `kiro/simulacion_kiro.md`. | Presentarlo como sesión real de Kiro o como planificación anterior al código: la simulación se elaboró después de implementar. | Contraste documental con especificaciones, SQL y evidencias existentes; no se ejecutan pruebas nuevas ni Kiro. |

## Límites y revisión del equipo

- Codex preparó especificaciones, implementación, pruebas y borrador documental. Los resultados se separan por motor y por tipo de verificación.
- Se agregó una simulación documental posterior en `kiro/simulacion_kiro.md`, a pedido del usuario; no acredita uso real de Kiro. No se afirma haber usado Kiro ni el agente Plan de OpenCode. El equipo debe realizar ese paso, registrar la salida real y explicar cualquier ajuste.
- No se atribuye a los estudiantes una revisión humana que todavía deben efectuar. Cada integrante debe releer, ejecutar y comprender lo entregado.
- No se copiaron valores de los secretos históricos a estos entregables; quedan hallazgos pendientes de corrección separada.
