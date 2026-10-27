# Design: Esquema de Roles y Permisos — Food Store

## 1. Arquitectura de Roles

```
[admin_datos] (Login)
  └── Acceso total DDL/DML

[app_web] (Login)
  ├── INHERITS rol_app_lectura (SELECT en tablas operativas)
  └── INHERITS rol_app_escritura (INSERT/UPDATE en pedidos y clientes)

[rol_soporte] (Grupo)
  └── SELECT limitado (columnas no sensibles) para atención al cliente

[rol_reportes] (Grupo)
  └── SELECT en vistas analíticas y tablas de negocio para BI
```

## 2. Justificación de Permisos (Mínimo Privilegio)
- **`rol_app_lectura`**: Permite consultar `producto`, `categoria`, `cliente`.
- **`rol_app_escritura`**: Permite registrar pedidos y líneas de detalle (`pedido`, `detalle_pedido`).
- **`rol_soporte`**: Acceso de consulta excluyendo datos privados o contraseñas de `usuario`.
- **`rol_reportes`**: Acceso de solo lectura a tablas e índices analíticos para reportes gerenciales.
- **`ALTER DEFAULT PRIVILEGES`**: Configurado para que tablas y secuencias futuras creadas por `postgres` otorguen automáticamente lectura/escritura a los grupos correspondientes.
