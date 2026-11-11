# Requirements: Plan de Mantenimiento y Recuperación ante Desastres — Food Store (Unidad 6)

## Historias de usuario y criterios de aceptación (EARS)

### RU-U6-01: Respaldo programado en formato custom
- **Como** administrador de base de datos,
- **Quiero** automatizar la generación de respaldos completos en formato custom (`pg_dump -Fc`) con registro de logs y marcas temporales,
- **Para que** la base `food_store` cuente con copias recuperables y auditables sin exponer credenciales en texto plano.

### RU-U6-02: Mantenimiento rutinario y chequeo de salud
- **Como** operador de base de datos,
- **Quiero** ejecutar rutinas periódicas de actualización de estadísticas (`ANALYZE`), limpieza (`VACUUM`) y diagnóstico de salud (`health_check.sql`),
- **Para que** el optimizador de consultas mantenga planes eficientes y se controlen las tuplas muertas, el tamaño en disco y las sesiones activas.

### RU-U6-03: Simulacro de desastre contra reloj (RTO / RPO) y verificación de integridad
- **Como** responsable de continuidad operativa,
- **Quiero** restaurar el último respaldo en una instancia aislada (`foodstore_restore_test`) midiendo el tiempo de recuperación (RTO) y verificando conteos y restricciones `CHECK`,
- **Para que** quede acreditada la capacidad de recuperación ante desastres con un informe post-incidente documentado.
