# Ensayo de defensa · TP8 · 10 minutos

Este es un guion para practicar; no acredita que el ensayo se haya realizado.

| Tiempo | Exposición / demostración |
|---|---|
| 0:00–2:00 | Mostrar el mapa de motores: PostgreSQL decide datos operativos; MongoDB contiene el subconjunto documental del TP7; SQLite guarda cache y borradores. Explicar por qué el verde no es una venta. |
| 2:00–3:00 | Mostrar `schema_sqlite.sql`: cuatro tablas STRICT, centavos, CHECK y FK. Explicar por qué la FK se activa en cada conexión. |
| 3:00–6:00 | Ejecutar C2: crear borrador, subir precio en copia de pruebas, importar instantánea y obtener CONFLICTO. Aceptar precio y enviar UUID nuevo: SIMULADO_APROBADO. Mostrar stock y pedidos intactos por la simulación. |
| 6:00–7:00 | Ejecutar reenvío C6. Mostrar error PK y que el resultado anterior no se reevalúa. Explicar protección transaccional equivalente en un servidor real. |
| 7:00–9:00 | Desarrollar el descarte de quitar `subtotal`: mostrar columna generada y prueba que impide sobrescribirla. Diferenciar esto del hallazgo aceptado sobre autenticación de ejemplo. |
| 9:00–10:00 | Explicar mantenimiento y qué hacer tras restaurar un respaldo viejo. Declarar asistencia de IA, límites y revisión personal. |

## Preguntas para cada integrante

1. ¿Qué pasa si el precio cambió y además el stock no alcanza? ¿Por qué?
2. ¿Por qué no borramos de `producto_cache` la fila dada de baja?
3. ¿Qué protege una transacción que guarda cabecera, ítems y solicitud?
4. ¿Una PK local impide que dos tablets registren la misma venta en el servidor?
5. ¿Cómo se garantiza que C7 no deje cabeceras o solicitudes huérfanas?
6. ¿Por qué almacenar centavos enteros? ¿Dónde se transforman los booleanos `t/f`?
7. ¿Qué se vuelve a validar después de una restauración antigua del servidor?
8. ¿Qué hallazgo descartaron, con qué prueba y qué límite tiene esa prueba?

Antes de clase: ejecutar los casos en una copia, anotar las salidas propias y distribuir preguntas entre integrantes. No usar bases existentes para la demostración destructiva.
