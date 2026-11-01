# Informe Post-Incidente y de Recuperación (Parte 5) — Food Store

## 1. Datos del Respaldo Utilizado
- **Archivo de respaldo:** `food_store_20261101_125256.dump`
- **Fecha y hora de creación:** 01/11/2026 12:52:56
- **Formato:** Custom (`-Fc`) comprimido con metadatos independientes.

## 2. Métricas del Simulacro (RPO y RTO)
- **RTO (Recovery Time Objective) observado:** **3,52 segundos** (tiempo medido desde la creación de la base `foodstore_restore_test`, restauración con `pg_restore --no-owner --no-privileges` y validación lógica).
- **RPO (Recovery Point Objective) observado:** **~24 minutos** (antigüedad del archivo `.dump` al momento del simulacro de recuperación).

## 3. Resultado de las Validaciones Lógicas y de Integridad
- **Conteo de tuplas por tabla:**
  - `categoria`: 9 filas
  - `cliente`: 20.000 filas
  - `producto`: 10.000 filas
  - `pedido`: 100.000 filas
  - `detalle_pedido`: 300.000 filas
- **Restricciones CHECK (`precio >= 0`, `stock >= 0`, `cantidad > 0`):**
  - Productos con valores inválidos: **0**
  - Detalles de pedido con valores inválidos: **0**

## 4. Problema Encontrado y Mejora Propuesta
- **Problema encontrado:** Durante la primera ejecución del script de restauración, el comando `dropdb` falló al intentar eliminar la base de prueba si esta no existía previamente, ya que el parámetro `--if-exists` requiere soporte o manejo explícito del código de salida/advertencia en automatización de comandos nativos de PowerShell.
- **Mejora concreta:** Se ajustó el script `restore_test.ps1` para validar y manejar de forma limpia la existencia previa de la base de prueba antes de la ejecución de borrado, garantizando idempotencia en la automatización.

## 5. Asistencia de IA (OpenCode) y Verificación Humana
- **Asistencia:** OpenCode colaboró en la estructuración inicial de los scripts automatizados de respaldo (`backup_foodstore.ps1`) y restauración (`restore_test.ps1`), así como en las consultas de `health_check.sql` y `maintenance.sql`.
- **Verificación humana:** Todos los scripts fueron revisados y ejecutados manualmente contra la base de desarrollo `food_store` y la base de prueba `foodstore_restore_test`, validando que no expongan credenciales, operen con rutas absolutas seguras y verifiquen códigos de salida de forma estricta.
