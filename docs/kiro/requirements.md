# Requirements: Tablet Offline SQLite y Simulación de Sincronización — Food Store (Unidad 8)

## Requisitos en formato EARS (Especificación Kiro)

- **REQ-01:** WHEN la tablet opere sin conexión THE SYSTEM SHALL consultar un catálogo local (`producto_cache`) y guardar borrador (`pedido_borrador`), ítems (`item_borrador`) y solicitud (`cola_sync`) atómicamente dentro de una transacción. Casos C1, C7 y COMMIT/ROLLBACK.
- **REQ-02:** WHEN una solicitud `PENDIENTE` contenga un producto ausente, no disponible, eliminado o sin stock suficiente THE SYSTEM SHALL marcar `RECHAZADO` con prioridad sobre cambios de precio. Casos C3, C4.
- **REQ-03:** WHEN no haya rechazo y cambie el precio respecto del precio visto THE SYSTEM SHALL marcar `CONFLICTO`; WHEN el cliente acepte el nuevo precio THE SYSTEM SHALL conservar la solicitud previa y evaluar otra con UUID nuevo. Caso C2.
- **REQ-04:** WHEN todos los ítems coincidan con la instantánea del servidor THE SYSTEM SHALL marcar `SIMULADO_APROBADO` sin confirmar ventas ni descontar stock en PostgreSQL; WHEN se repita un UUID THE SYSTEM SHALL impedir duplicados y no reevaluar estados finales. Casos C5, C6.
