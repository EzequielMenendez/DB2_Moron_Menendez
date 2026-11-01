# Requisitos TP8 (EARS)

Borrador técnico generado con Codex antes de los scripts. No acredita una sesión en Kiro.

- REQ-01 WHEN la tablet opere sin conexión THE SYSTEM SHALL consultar un catálogo local y guardar borrador, ítems y solicitud atómicamente. Casos C1, C7 y COMMIT/ROLLBACK.
- REQ-02 WHEN una solicitud PENDIENTE contenga un producto ausente, no disponible, eliminado o sin stock suficiente THE SYSTEM SHALL marcar RECHAZADO con prioridad sobre cambios de precio. Casos C3, C4.
- REQ-03 WHEN no haya rechazo y cambie el precio THE SYSTEM SHALL marcar CONFLICTO; WHEN el cliente acepte el nuevo precio THE SYSTEM SHALL conservar la solicitud previa y evaluar otra con UUID nuevo. Caso C2.
- REQ-04 WHEN todos los ítems coincidan THE SYSTEM SHALL marcar SIMULADO_APROBADO sin confirmar ventas; WHEN se repita un UUID THE SYSTEM SHALL impedir duplicados y no reevaluar estados finales. Casos C5, C6.
