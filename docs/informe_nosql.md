# Informe Técnico — Unidad 7: NoSQL y Nuevas Formas de Almacenamiento (Food Store)

## Parte 1 — Modelo Documental y Migración

### Consigna 1: Procedencia de los Datos y Esquema de Colección
- **Procedencia:** Los datos migrados no son sintéticos ni arbitrarios; corresponden exactamente a los **pedidos con IDs 1 al 5** extraídos de la base relacional transaccional `food_store` (PostgreSQL), incluyendo sus respectivos clientes (`cliente_id` 2 a 6) y sus líneas de detalle asociadas con precios, cantidades y subtotales históricos reales.
- **Tablas de origen en PostgreSQL:** `pedido`, `cliente`, `detalle_pedido` y `producto`.
- **Esquema Documental (MongoDB - Colección `pedidos`):**
  - Cada documento representa un pedido autocontenido.
  - Se conserva el identificador original (`_id` mapeado al `id` del pedido).
  - Se embebe el objeto `cliente` (datos del comprador) y un arreglo `lineas` que agrupa los ítems del detalle del pedido.

### Consigna 2 y 3: Inserción y Reglas de Integridad
- **Precisión Monetaria:** Todos los importes unitarios, subtotales y totales se modelan utilizando el tipo nativo **`NumberDecimal`** en MongoDB, evitando los errores de redondeo inherentes al tipo punto flotante de doble precisión (`double`).
- **Reglas de integridad conservadas:**
  1. **Integridad referencial y de dominio:** Se preservan los IDs originales de cliente y producto, así como la validez lógica de las cantidades (`> 0`) y precios (`>= 0`).
  2. **Inmutabilidad de precios históricos:** El precio pactado al momento de la compra se fija dentro del arreglo de líneas de cada documento, protegiendo el histórico ante futuras modificaciones en las tablas maestras.
  - **Justificación del Embedding:** Se eligió el modelo de documento embebido porque el patrón de acceso principal en Food Store para la vista de pedidos requiere consultar la cabecera, el cliente y sus líneas en una única operación de lectura, evitando el costo operativo de múltiples uniones (`JOIN`) en disco.

---

## Parte 2 — Consultas y Verificación

### Consigna 4 y 5: Tabla de Verificación (PostgreSQL vs MongoDB)
Las consultas ejecutadas en PostgreSQL fueron **estrictamente acotadas al subconjunto de los 5 pedidos migrados** (`WHERE p.id BETWEEN 1 AND 5`), permitiendo una comparación numérica y de identificadores exacta.

| Consulta | Cantidad en PostgreSQL | Cantidad en MongoDB | Coinciden los IDs |
|----------|------------------------|---------------------|-------------------|
| **Estado seleccionado** (`CONFIRMADO`) | 3 | 3 | **Sí** (IDs: 1, 2, 4) |
| **Producto seleccionado** (`producto_id = 80`) | 1 | 1 | **Sí** (ID: 2) |

---

## Parte 3 — Evaluación de la Tecnología e IA

### Consigna 6: Consulta a la Herramienta de IA
**Prompt profesional utilizado:**
> *"Actuando como Arquitecto de Bases de Datos especializado en sistemas transaccionales y NoSQL, analiza el subconjunto de pedidos, clientes y detalles de la plataforma Food Store. Compara el almacenamiento y rendimiento de consultas entre un modelo relacional normalizado en PostgreSQL y un modelo documental en MongoDB, considerando el acceso frecuente a pedidos completos, la necesidad de respetar la coherencia de precios históricos y el uso de tipos de datos monetarios de alta precisión. Detalla ventajas y desventajas técnicas de cada enfoque."*

**Resumen de la respuesta de la IA:** La IA evaluó que MongoDB destaca en la velocidad de lectura de pedidos completos gracias al uso de documentos embebidos (evitando `JOIN`), pero advirtió que la desnormalización complica las actualizaciones masivas de datos maestros de clientes. Asimismo, recomendó el uso de tipos decimales de alta precisión frente a punto flotante.

### Consigna 7: Contraste con Documentación Oficial y Conclusión
- **Afirmación 1 de la IA:** *"Los datos embebidos en MongoDB eliminan la necesidad de transacciones complejas para mantener la consistencia entre entidades relacionadas"* -> **Contraste con Doc Oficial (MongoDB Data Modeling):** Parcialmente inexacto. Si bien el modelo embebido provee atomicidad a nivel de documento individual, las transacciones multi-documento (`ACID transactions`) siguen siendo necesarias cuando un cambio afecta a múltiples colecciones o documentos independientes.
- **Afirmación 2 de la IA:** *"El tipo NumberDecimal en MongoDB previene la pérdida de precisión en cálculos monetarios frente a los tipos float estándar"* -> **Contraste con Doc Oficial (MongoDB Reference):** Exacto y verificado. La documentación oficial recomienda explícitamente el uso de `Decimal128` (`NumberDecimal`) para aplicaciones financieras y contables donde el redondeo binario de punto flotante resulta inaceptable.

#### Conclusión Técnica (Menos de 200 palabras)
Para el subconjunto de pedidos y detalles de Food Store, **conviene adoptar MongoDB** si la prioridad arquitectónica es la baja latencia en la lectura de pedidos completos para interfaces de usuario y paneles de clientes, ya que agrupa la información relacionada en un único disco contiguo. No obstante, **PostgreSQL sigue siendo superior** para garantizar la integridad referencial estricta y evitar anomalías de actualización en datos maestros altamente normalizados. La solución híbrida más robusta para Food Store consiste en mantener PostgreSQL como la fuente de verdad transaccional principal y utilizar MongoDB como una réplica de lectura optimizada (*read model*) para reportes de pedidos y visualización de e-commerce.
