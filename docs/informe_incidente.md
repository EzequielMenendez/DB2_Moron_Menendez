# Informe de Incidente y Contraste con IA (Parte C) — Food Store

## 1. Prompt enviado a OpenCode (con log anonimizado)
> "Analiza el siguiente fragmento de log de PostgreSQL de Food Store y propón una hipótesis de qué ocurrió y qué medidas tomar:
> 
> ```
> 2026-10-27 12:10:00.100 -03 [9999] LOG:  statement: SELECT fn_autenticar('atacante_anon@mail.com', '***');
> 2026-10-27 12:10:02.200 -03 [9999] LOG:  statement: SELECT fn_autenticar('atacante_anon@mail.com', '***');
> 2026-10-27 12:10:04.300 -03 [9999] LOG:  statement: SELECT fn_autenticar('atacante_anon@mail.com', '***');
> 2026-10-27 12:10:15.500 -03 [9999] LOG:  statement: SELECT fn_autenticar('cliente_legitimo@mail.com', '***');
> 2026-10-27 12:10:20.800 -03 [9999] LOG:  statement: SELECT * FROM cliente LIMIT 500;
> 2026-10-27 12:10:35.900 -03 [9999] LOG:  statement: GRANT admin_datos TO rol_app_lectura;
> 2026-10-27 12:10:35.905 -03 [9999] ERROR:  permission denied for role "admin_datos"
> ```"

## 2. Respuesta resumida obtenida de OpenCode
La IA indicó que se observa un ataque de fuerza bruta o iterativo contra la función de autenticación (`fn_autenticar`), seguido de un inicio de sesión exitoso y una extracción masiva de datos de la tabla `cliente`. Posteriormente, detectó un intento explícito de escalamiento de privilegios (`GRANT admin_datos...`) que fue bloqueado por el motor con un error `permission denied`. Sugirió bloquear la IP o usuario atacante y revisar credenciales.

## 3. Contraste Crítico (Lectura Crítica)
- **¿Qué acertó la IA?** Identificó correctamente los intentos de login repetidos como una fase de escaneo/fuerza bruta, reconoció la extracción masiva de registros (`SELECT * FROM cliente LIMIT 500`) y validó que el intento de escalamiento de privilegios falló gracias al control de acceso.
- **¿Qué omitió o asumió sin evidencia?** La IA asumió que `cliente_legitimo@mail.com` fue un acceso legítimo posterior al ataque, cuando en la ejecución real formaba parte de la secuencia de prueba; tampoco pudo inferir la dirección IP exacta dado que el log anonimizado ofuscaba los orígenes. No inventó afirmaciones falsas graves, pero sobreestimó la intencionalidad del login posterior.

## 4. Decisión Final de Contención (Criterio del Equipo)
Basado en la evidencia del log y no en la automatización ciega de la IA, el equipo aplicaría las siguientes medidas reales de contención:
1. **Revocación y rotación:** Forzar el cambio inmediato de contraseña para las cuentas comprometidas o involucradas en los intentos de fuerza bruta.
2. **Bloqueo perimetral:** Bloquear temporalmente la dirección IP o el origen de la sesión `[9999]` en el firewall o balanceador de carga de la aplicación web.
3. **Auditoría de sesiones:** Invalidar los tokens JWT o sesiones activas asociadas al identificador del atacante para frenar la exfiltración masiva de datos (`cliente`).
