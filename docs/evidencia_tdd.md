# Evidencia de TDD - TP8

Fecha: 01/11/2026. Proyecto incorporado desde NoSQL 29cf3c2 en rama local sqlite.
No habia suite automatizada para SQLite ni archivos movil/; se agrego una suite aislada sin alterar scripts de unidades anteriores. Las especificaciones docs/kiro se escribieron antes del codigo de produccion. No se acredita una sesion en Kiro/OpenCode: se uso Codex.

## Ejecuciones reales

1. RED: `python -m unittest discover -s movil/tests -v` con 18 contratos escritos antes del esquema: **18 errores**, todos FileNotFoundError de schema_sqlite.sql inexistente. Se ejecuto con Python bundled.
2. GREEN: despues del esquema, carga y semaforo: **18/18**.
3. RED del ayudante: test_simulador.py referencia simulador.py inexistente: **18 pasan, 1 error de importacion**.
4. GREEN del ayudante: **21/21** con Python default 3.10 y SQLite 3.37.2. Hubo dos errores del arnes de pruebas en Windows porque el context manager de sqlite3 confirma/revierte pero no cierra la conexion; se corrigio el arnes usando contextlib.closing. No fue un fallo de los contratos SQL.
5. Triangulacion: CSV exportados realmente desde PostgreSQL se usan en tres pruebas de integracion (C2-C4): **24/24** en Python 3.10 y Python bundled.
6. Verificacion adicional del propio pruebas_sqlite.sql, ejecutando sus sentencias una por una y comprobando exactamente sus dos errores esperados y ninguna fila residual C7: **25/25**.

## TDD Cycle Evidence

| Tarea | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| Esquema e integridad | movil/tests/test_sqlite.py | SQLite en memoria | Sin archivos anteriores modificados | 18 errores por ausencia de schema | 18/18 | Tipos, dominios, cantidad cero y FK; COMMIT/ROLLBACK | Sin refactor productivo necesario |
| Cache e instantanea | movil/tests/test_sqlite.py | SQLite en memoria | Nuevo modulo aislado | Mismo RED inicial | 18/18 | Baja logica y ausencia; conserva FK | Sin cambios de comportamiento |
| Semaforo | movil/tests/test_sqlite.py | SQLite en memoria | Nuevo modulo aislado | Mismo RED inicial | 18/18 | Rojo/amarillo/verde, varios items, limite stock, idempotencia | Sin cambios de comportamiento |
| Generador y CSV | movil/tests/test_simulador.py | Archivo temporal SQLite | 18/18 previos | Importacion de modulo inexistente | 21/21 | Base nueva, no sobrescribir, CSV invalido revierte lote | Cierre explicito del arnes Windows |
| Casos CSV PG | movil/tests/test_snapshots_postgresql.py | Integracion local por CSV | 21/21 | Contratos existentes ya verdes; no se agrego logica productiva | 24/24 | C2 acepta con UUID nuevo; C3 stock; C4 lapida | No requerido |
| SQL demostrativo | movil/tests/test_sqlite.py | SQLite en memoria | 24/24 | Verificacion adicional, sin nuevo codigo productivo | 25/25 | Dos errores esperados, sin nuevas filas | No requerido |

La prueba de PostgreSQL esta documentada aparte en evidencia_postgresql.md. Las pruebas locales no acreditan un dispositivo real, una sincronizacion por red ni un ensayo personal de defensa.
