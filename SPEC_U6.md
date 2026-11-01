# SPEC_U6.md — Especificación y Plan de Mantenimiento (Food Store)

## 1. Propósito
Establecer el procedimiento automatizado y seguro de respaldo, monitoreo, mantenimiento periódico y recuperación ante desastres para la base de datos `food_store` (PostgreSQL 18).

## 2. Plan de Mantenimiento

| Tarea mínima | Frecuencia propuesta | Evidencia esperada |
|--------------|----------------------|--------------------|
| **Respaldo de food_store** | Diaria | Archivo `.dump` en formato custom (`-Fc`) en `db/backups/` con fecha/hora y archivo de log en `db/logs/`. |
| **Chequeo de salud** | Diaria | Salida de `health_check.sql` (tamaño, conexiones, tuplas muertas, actividad). |
| **Revisión de mantenimiento** | Semanal | Estado de tuplas muertas, actividad de `autovacuum` y estadísticas en `maintenance.sql`. |
| **Restauración de prueba** | Semanal | Simulacro de restauración en base descartable `foodstore_restore_test` validando conteos y restricciones lógicas. |

## 3. Reglas de Seguridad y Operación
- **No exposición de credenciales:** Las contraseñas no se hardcodean en los scripts; se utiliza autenticación por entorno (`PGPASSWORD` o archivo `.pgpass`).
- **Entorno aislado:** Las pruebas destructivas y de restauración se ejecutan exclusivamente sobre bases de prueba (`foodstore_restore_test`), nunca sobre la base de producción/desarrollo principal `food_store`.
- **Formato custom:** Los respaldos se realizan mediante `pg_dump -Fc` para permitir restauraciones granulares y selectivas mediante `pg_restore`.
