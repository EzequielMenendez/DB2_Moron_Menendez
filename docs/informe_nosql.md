# Informe Técnico — Unidad 7: NoSQL y Nuevas Formas de Almacenamiento (Food Store)

## Parte 1 — Modelo Documental y Migración

### Consigna 1: Esquema de Colección Documental
El subconjunto seleccionado corresponde a **pedidos y detalle de pedidos**.
- **En PostgreSQL relacional:** Intervienen las tablas `pedido` (cabecera), `detalle_pedido` (líneas de items), `cliente` (datos del comprador) y `producto` (datos del artículo).
- **En MongoDB (Colección `pedidos`):** Se adopta un modelo de **documento embebido**, donde cada documento en la colección representa un pedido completo autocontenido.
  - **Identificadores conservados:** Se preserva el `_id` original del pedido (`id`) y el `id_cliente` / `id_producto`.
  - **Objetos embebidos:** Se embebe el objeto `cliente` (nombre, apellido, email) y un arreglo `lineas` que contiene los detalles de los productos comprados (producto_id, nombre, cantidad, precio unitario, subtotal).

### Consigna 2 y 3: Migración e Integridad
- Se migraron 5 pedidos mediante instrucciones `insertMany()` en `sql/consultas_mongodb.js`.
- **Reglas de integridad conservadas:**
  1. **Integridad de dominio y tipos:** Los importes y cantidades se mantienen con tipos numéricos precisos (`NumberDecimal` / `Number`) y las fechas en formato ISODate.
  2. **Inmutabilidad histórica:** Los precios unitarios de cada línea de pedido se almacenan tal como fueron pactados en el momento de la compra (precio histórico), evitando alteraciones si el precio de lista del producto cambia en la tabla relacional.
- **Justificación del embedding:** Se embebieron las líneas de pedido y los datos esenciales del cliente porque en el dominio de Food Store el acceso frecuente es por **pedido completo** (para facturación, historial del cliente y visualización en el panel). Almacenar todo en un solo documento evita múltiples uniones (`JOIN`) en disco, optimizando la lectura en escenarios de alto tráfico de consultas.

---

## Parte 2 — Consultas y Verificación

### Consigna 4 y 5: Tabla de Verificación (PostgreSQL vs MongoDB)

Se ejecutaron las consultas equivalentes en ambos motores sobre el subconjunto migrado de 5 pedidos.

| Consulta | Cantidad en PostgreSQL | Cantidad en MongoDB | Coinciden los IDs |
|----------|------------------------|---------------------|-------------------|
| **Estado seleccionado** (`CONFIRMADO`) | 3 | 3 | **Sí** (IDs: 1, 3, 5) |
| **Producto seleccionado** (`producto_id = 10`) | 2 | 2 | **Sí** (IDs: 1, 3) |

*Nota:* No se detectaron diferencias entre los motores; los conjuntos de identificadores recuperados coinciden de forma exacta, validando la corrección del modelado documental.

---

## Parte 3 — Evaluación de la Tecnología e IA

### Consigna 6: Evaluación comparativa asistida por IA
Se consultó a OpenCode sobre las ventajas y desventajas de almacenar pedidos en PostgreSQL frente a MongoDB. La IA destacó que MongoDB ofrece alta velocidad de lectura para documentos completos sin necesidad de `JOIN`, mientras que PostgreSQL garantiza restricciones de integridad referencial estrictas y normalización sin redundancia.

### Consigna 7: Contraste con documentación oficial y Conclusión
- **Afirmación 1 de IA:** *"MongoDB requiere actualizar todos los documentos embebidos si cambia el nombre o la dirección de un cliente"* -> **Contraste con Doc oficial:** Verdadero. Al desnormalizar datos del cliente dentro del documento de pedido, un cambio en el perfil maestro del cliente no se propaga automáticamente, requiriendo operaciones de actualización masiva (`updateMany`).
- **Afirmación 2 de IA:** *"Las consultas que cruzan múltiples colecciones independientes son más eficientes en MongoDB que en PostgreSQL"* -> **Contraste con Doc oficial:** Falso / Inexacto. MongoDB prioriza el modelado embebido; las operaciones `$lookup` (equivalentes a `JOIN`) son costosas y desaconsejadas para consultas analíticas complejas en comparación con el optimizador relacional de PostgreSQL.

#### Conclusión Técnica (Menos de 200 palabras)
Para el subconjunto de pedidos y detalles de Food Store, **conviene utilizar MongoDB** si el patrón de acceso principal del sistema es la lectura de pedidos completos para el panel de clientes o facturación, ya que elimina las reuniones (`JOIN`) y agiliza la recuperación en una sola operación de lectura por documento. Sin embargo, para la gestión operativa general de inventarios, precios de lista y control estricto de stock, **PostgreSQL es indispensable** por sus garantías ACID y la integridad referencial. La arquitectura óptima para este dominio consiste en mantener **PostgreSQL como fuente de verdad transaccional** y replicar o proyectar periódicamente los pedidos cerrados hacia MongoDB cuando se requiere lectura analítica de alto rendimiento o catálogos dinámicos.
