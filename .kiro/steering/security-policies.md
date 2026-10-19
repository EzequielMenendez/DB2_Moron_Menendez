---
inclusion: always
---

# Normas de seguridad del proyecto — Food Store (Base de Datos II)

Estas reglas se aplican en cada conversación, sin que sea necesario pedirlas.

## Secretos y variables de entorno

- **Nunca** hardcodear contraseñas, tokens ni claves de API en el código o en
  los scripts SQL. Todo secreto va en `.env`, que está en `.gitignore`.
- `.env.example` se versiona y solo contiene los **nombres** de las variables,
  sin valores reales.
- La contraseña del usuario `postgres` de este entorno de desarrollo es un
  secreto local: no se escribe en ningún archivo del repositorio ni en los
  entregables.

## Consultas SQL

- Validar y sanitizar todo input que venga del usuario antes de usarlo en una
  consulta SQL: usar **parámetros** (`$1`, `psycopg2.extras.RealDictCursor`
  con binds, o equivalentes), **nunca concatenar strings**.
- No construir SQL dinámico con nombres de tabla/columna provenientes del
  exterior sin una lista blanca explícita.

## Datos de usuarios

- Las contraseñas de usuarios se guardan **siempre hasheadas** (bcrypt/argon2),
  nunca en texto plano.
- No exponer mensajes de error de la base de datos directamente al cliente:
  registrar el error en servidor y devolver una respuesta genérica.

## Bases de datos y respaldos

- Los respaldos (`db/backups/*.dump`, `*.sql`) pueden contener datos reales:
  esa carpeta está en `.gitignore` y **no se commitea**.
- Antes de un `ALTER TABLE` o migración de schema relevante, generar un
  `pg_dump` de respaldo.
- Trabajo sobre la base `food_store`; no tocar otras bases (`food_store_tp*`)
  sin confirmación explícita.

## Control de versiones

- Nunca commitear `.env` ni contraseñas sueltas en el código.
- Revisar el `git status` antes de cada commit para no incluir archivos
  sensibles o generados.
