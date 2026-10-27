# Informe de Auditoría y Configuración (Parte B) — Food Store

## 1. Configuración del Servidor de Desarrollo
Para cumplir con los requerimientos de la Parte B, se activaron o verificaron los siguientes parámetros en `postgresql.conf` (mediante `ALTER SYSTEM` o configuración local):
- `log_connections = 'on'` (registra cada intento de conexión exitoso con IP y puerto).
- `log_disconnections = 'on'` (registra la duración y cierre de sesión).
- `log_statement = 'mod'` (registra todas las sentencias de modificación de datos: INSERT, UPDATE, DELETE, DDL).

## 2. Fragmento de Log Capturado (`log_auditoria_prueba.txt`)
Ver archivo adjunto en `docs/log_auditoria_prueba.txt` con la traza de conexión, llamada a `fn_autenticar`, consulta SELECT, e inserción/actualización en `categoria`.

## 3. Utilidad y Limitaciones del Registro Nativo
- **Útil para:** Identificar quién se conectó (`log_connections`), cuándo (`timestamp`), desde dónde (`client_addr`), y qué cambios de datos se realizaron (`log_statement = 'mod'`).
- **Fuera de alcance (Limitaciones):** El log nativo no ofrece granularidad a nivel de **detalle fila por fila** (saber exactamente qué valores específicos se alteraron en cada columna de una tupla en un UPDATE masivo, algo que resolvería una extensión especializada como `pgaudit`). Tampoco audita lecturas (`SELECT`) a menos que se configure `log_statement = 'all'`, lo cual satura los discos en producción.

## 4. Sensibilidad del Archivo de Log
- **¿Es un activo sensible?** Sí, el archivo de log es altamente sensible. Contiene metadatos de acceso, direcciones IP, sentencias SQL ejecutadas (que pueden incluir valores de parámetros o identificadores de usuario) y posibles fallos de autenticación.
- **¿Quién debe poder leerlo y con qué permisos?** Únicamente el usuario del sistema operativo del motor (`postgres` o `root` según el entorno) y administradores autorizados de infraestructura, con permisos restrictivos a nivel de sistema operativo (ej. `chmod 600` o lectura exclusiva para el grupo del motor). Ninguna aplicación web ni usuario operativo debe tener acceso de lectura al directorio de logs.
