# Informe de Verificación de Equivalencia y Anonimización (Parte D) — Food Store

## 1. Script de Creación de Tabla Anonimizada (`sql/usuario_anon.sql`)
Se construyó la tabla `cliente_anon` a partir de `cliente`, reemplazando nombres, apellidos y correos electrónicos por valores sintéticos deterministas (`md5` sobre el ID), preservando la volumetría y los identificadores relacionales.

## 2. Consultas de Agregación Paralelas
Se ejecutaron conteos sobre ambas tablas:
- **Tabla real (`cliente`):** 20.000 filas.
- **Tabla anonimizada (`cliente_anon`):** 20.000 filas.

Resultado: **Mismos conteos, misma estructura agregada.**

## 3. Información que NUNCA debe salir hacia un Asistente de IA
Nunca deben exponerse correos electrónicos reales, nombres y apellidos de clientes, ni datos financieros o de transacciones asociadas a identidades reales. Pasar estos datos por un proceso riguroso de anonimización garantiza que la IA pueda ser consultada para optimización de consultas, análisis estadístico o depuración de código sin violar la privacidad ni exponer información sensible de negocio.
