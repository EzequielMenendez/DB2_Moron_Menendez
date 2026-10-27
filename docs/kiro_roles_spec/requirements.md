# Requirements: Esquema de Roles y Permisos — Food Store

## Historias de usuario y criterios de aceptación

### RU-01: Roles de grupo y login (Principio de mínimo privilegio)
- **Como** administrador de base de datos,
- **Quiero** definir roles de grupo con privilegios acotados y roles de login que los hereden,
- **Para que** las aplicaciones y usuarios solo accedan a los datos estrictamente necesarios para su función.

**Criterios de aceptación:**
1. Se definen cuatro roles de grupo: `rol_app_lectura`, `rol_app_escritura`, `rol_soporte`, `rol_reportes`.
2. Se definen roles de login: `app_web` (hereda lectura y escritura acotada) y `admin_datos` (privilegios administrativos/maestros).
3. Ningún rol de aplicación posee permisos de superusuario ni `GRANT ALL` innecesario sobre esquemas críticos.

### RU-02: Privilegios a nivel de columna
- **Como** responsable de seguridad,
- **Quiero** restringir el acceso a columnas sensibles (como hash de contraseñas o datos de contacto en `usuario` o `cliente`),
- **Para que** roles operativos como soporte no visualicen información confidencial.

**Criterios de aceptación:**
1. Se otorgan permisos selectivos a nivel de columna (ej. `GRANT SELECT (id, nombre, email) ON cliente TO rol_soporte`).
2. Se excluyen columnas sensibles de los grants generales.

### RU-03: Privilegios por defecto en objetos futuros
- **Como** administrador,
- **Quiero** configurar políticas por defecto para tablas y secuencias futuras,
- **Para que** cualquier nueva tabla creada herede automáticamente el esquema de permisos de mínimo privilegio.
