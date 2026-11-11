# AGENTS.md - Food Store (Base de Datos II)

## Proyecto

Base de datos relacional, documental y móvil para un sistema de gestión de tienda de alimentos (**Food Store**), desarrollado en el marco del curso de Base de Datos II (UTN · 2026).

## Stack tecnológico

- **Motor relacional (Servidor central):** PostgreSQL 18.x (`psql`, `pg_dump`, `pg_restore`, `createdb`)
- **Motor documental (Unidad 7):** MongoDB (`mongosh`)
- **Motor móvil offline (Unidad 8):** SQLite 3.37+ (`STRICT`, Python 3.10+ `sqlite3` / `unittest`)
- **Automatización:** PowerShell (`backup_foodstore.ps1`, `restore_test.ps1`) y Python (`movil/simulador.py`)
- **Control de versiones:** Git (`main` U4–U6, `NoSQL` U7, `sqlite` U8 e integración U4–U8)
- **Planificación:** Kiro (`.kiro/specs/` y `docs/kiro/`)
- **Asistente de código:** OpenCode

## Estructura del proyecto (Segunda Entrega Parcial · Unidades 4 a 8)

```
DB2_Moron_Menendez/
├── .kiro/
│   ├── specs/
│   │   ├── fnbc-y-desnormalizacion/  # Specs Kiro Unidad 4 (FNBC y desnormalización)
│   │   ├── roles-food-store/         # Specs Kiro Unidad 5 (Roles y mínimo privilegio)
│   │   ├── mantenimiento-u6/         # Specs Kiro Unidad 6 (Mantenimiento y DRP)
│   │   └── movil-sqlite-sync/        # Specs Kiro Unidad 8 (SQLite offline y semáforo)
│   └── steering/
│       └── security-policies.md      # Normas de seguridad del proyecto
├── db/
│   ├── preparar_food_store.sql       # Esquema alineado y carga determinista (100k pedidos)
│   ├── tp_fnbc_control_lote.sql      # U4: Descomposición FNBC, transacción y plan de reversión
│   ├── tp_desnormalizacion_top_categorias.sql # U4: Tabla resumen, 5 triggers y auditoría
│   ├── backup_foodstore.ps1          # U6: Respaldo automatizado en formato custom (-Fc)
│   ├── restore_test.ps1              # U6: Simulacro de desastre contra reloj (RTO/RPO)
│   ├── maintenance.sql               # U6: VACUUM (VERBOSE, ANALYZE) y verificación
│   └── health_check.sql              # U6: Monitoreo de salud, conexiones y tuplas muertas
├── sql/
│   ├── roles.sql                     # U5: Usuarios, roles de grupo/login y mínimo privilegio
│   ├── auditoria_test.sql            # U5: Pruebas de auditoría nativa
│   ├── simulacro_incidente.sql       # U5: Simulacro de acceso indebido
│   ├── usuario_anon.sql              # U5: Anonimización determinista (cliente_anon)
│   ├── consultas_mongodb.js          # U7: Modelo documental embebido y consultas MongoDB
│   └── consultas_postgresql.sql      # U7: Consultas SQL equivalentes sobre pedidos 1 a 5
├── movil/
│   ├── schema_sqlite.sql             # U8: Esquema SQLite STRICT con CHECK y FOREIGN KEY
│   ├── cargar_cache.sql              # U8: Importación CSV con conversión t/f y lápidas
│   ├── semaforo.sql                  # U8: Semáforo de sincronización (rojo > amarillo > verde)
│   ├── pruebas_sqlite.sql            # U8: Transacciones COMMIT/ROLLBACK y casos C1/C7
│   ├── snapshot_postgresql.sql       # U8: Vista v_snapshot_movil en PostgreSQL
│   ├── servidor_pruebas.sql          # U8: Fixture sintética de servidor PostgreSQL
│   ├── pruebas_revision_postgresql.sql # U8: Pruebas del code review sobre U4 y U5
│   ├── simulador.py                  # U8: CLI de simulación y evaluación de snapshots
│   ├── foodstore_movil.db            # U8: Base SQLite de ejemplo lista para pruebas
│   ├── servidor_snapshot.csv         # U8: Instantánea base exportada desde PostgreSQL
│   ├── snapshots/                    # U8: Instantáneas de conflicto C2, C3 y C4
│   └── tests/                        # U8: Suite de 25 tests automatizados (unittest)
├── docs/
│   ├── informe_segunda_entrega.md    # Informe Técnico Integrador (Unidades 4 a 8)
│   ├── informe.pdf                   # Informe Técnico en formato PDF
│   ├── informe_unidad4_fnbc.md       # U4: Informe de FNBC y desnormalización
│   ├── informe_auditoria.md          # U5: Informe de configuración de auditoría
│   ├── informe_incidente.md          # U5: Reconstrucción de acceso indebido y contención
│   ├── verificacion_roles.txt        # U5: Evidencia de permisos por rol
│   ├── verificacion_equivalencia.md  # U5: Equivalencia sobre 20.000 clientes anonimizados
│   ├── informe_u6.md                 # U6: Informe post-incidente y métricas RTO/RPO
│   ├── informe_nosql.md              # U7: Comparación documental vs. relacional
│   ├── informe_tp8.md                # U8: Informe detallado de base móvil e integración
│   ├── evidencia_casos.md            # U8: Evidencia de casos C1 a C7
│   ├── evidencia_postgresql.md       # U8: Invariancia de PostgreSQL antes y después
│   ├── evidencia_revision.md         # U8: Evidencia del code review asistido por IA
│   ├── evidencia_tdd.md              # U8: Evidencia del ciclo TDD
│   ├── defensa_tp8.md                # U8: Guion de defensa oral
│   ├── DUIA.md                       # Declaración de Uso de IA
│   └── bitacora_ia.md                # Bitácora de IA de Unidad 8
├── BITACORA.md                       # Bitácora general consolidada (Unidades 4 a 8)
├── SPEC_U6.md                        # Especificación de mantenimiento (Unidad 6)
├── AGENTS.md                         # Este archivo
└── README.md                         # Guía general y comandos de reproducción
```

## Seguridad

Respetar siempre las normas definidas en `.kiro/steering/security-policies.md`: nunca versionar archivos `.env` ni respaldos `.dump`, y utilizar variables de entorno para credenciales.
