// =====================================================================
// sql/consultas_mongodb.js
// Unidad 7: NoSQL y nuevas formas de almacenamiento | Food Store
// Contiene:
//   - Creación de base y colección de pedidos con objetos embebidos y arreglos.
//   - Inserción (migración) de 5 pedidos de Food Store.
//   - Consultas a) b) c) d) de la Parte 2.
// =====================================================================

// 1. Conexión y selección de base de datos
use('foodstore_nosql');

// 2. Creación de la colección de pedidos con validación / estructura documental
db.createCollection("pedidos");

// 3. Migración / Inserción de 5 pedidos (conservando IDs de origen de Food Store)
db.pedidos.insertMany([
  {
    _id: 1,
    fecha: ISODate("2026-10-19T10:00:00Z"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 101,
      nombre: "Juan",
      apellido: "Pérez",
      email: "juan.perez@mail.com"
    },
    lineas: [
      { producto_id: 10, nombre_producto: "Café Molido 500g", cantidad: 2, precio_unitario: 4500.00, subtotal: 9000.00 },
      { producto_id: 15, nombre_producto: "Azúcar 1kg", cantidad: 3, precio_unitario: 1200.00, subtotal: 3600.00 }
    ],
    total_pedido: 12600.00
  },
  {
    _id: 2,
    fecha: ISODate("2026-10-19T11:30:00Z"),
    estado: "PENDIENTE",
    cliente: {
      id_cliente: 102,
      nombre: "María",
      apellido: "Gómez",
      email: "maria.gomez@mail.com"
    },
    lineas: [
      { producto_id: 20, nombre_producto: "Aceite de Oliva 1L", cantidad: 1, precio_unitario: 8500.00, subtotal: 8500.00 }
    ],
    total_pedido: 8500.00
  },
  {
    _id: 3,
    fecha: ISODate("2026-10-19T14:15:00Z"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 103,
      nombre: "Carlos",
      apellido: "López",
      email: "carlos.lopez@mail.com"
    },
    lineas: [
      { producto_id: 10, nombre_producto: "Café Molido 500g", cantidad: 1, precio_unitario: 4500.00, subtotal: 4500.00 },
      { producto_id: 22, nombre_producto: "Yerba Mate 1kg", cantidad: 4, precio_unitario: 3200.00, subtotal: 12800.00 },
      { producto_id: 30, nombre_producto: "Galletitas Dulces", cantidad: 2, precio_unitario: 1500.00, subtotal: 3000.00 }
    ],
    total_pedido: 20300.00
  },
  {
    _id: 4,
    fecha: ISODate("2026-10-19T16:00:00Z"),
    estado: "CANCELADO",
    cliente: {
      id_cliente: 104,
      nombre: "Ana",
      apellido: "Martínez",
      email: "ana.martinez@mail.com"
    },
    lineas: [
      { producto_id: 50, nombre_producto: "Harina de Trigo 1kg", cantidad: 5, precio_unitario: 950.00, subtotal: 4750.00 }
    ],
    total_pedido: 4750.00
  },
  {
    _id: 5,
    fecha: ISODate("2026-10-19T17:45:00Z"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 105,
      nombre: "Sofía",
      apellido: "Rodríguez",
      email: "sofia.rodriguez@mail.com"
    },
    lineas: [
      { producto_id: 22, nombre_producto: "Yerba Mate 1kg", cantidad: 2, precio_unitario: 3200.00, subtotal: 6400.00 },
      { producto_id: 15, nombre_producto: "Azúcar 1kg", cantidad: 2, precio_unitario: 1200.00, subtotal: 2400.00 }
    ],
    total_pedido: 8800.00
  }
]);

// =====================================================================
// CONSIGNA 4: Consultas en MongoDB
// =====================================================================

// a) Mostrar todos los pedidos, incluyendo su identificador y estado
print("--- a) Todos los pedidos (id y estado) ---");
db.pedidos.find({}, { _id: 1, estado: 1, fecha: 1 });

// b) Filtrar pedidos por un estado existente (ej: "CONFIRMADO")
print("--- b) Pedidos con estado CONFIRMADO ---");
db.pedidos.find({ estado: "CONFIRMADO" });

// c) Buscar pedidos que contengan un producto determinado dentro del arreglo de líneas (ej: producto_id: 10)
print("--- c) Pedidos que contienen el producto_id 10 ---");
db.pedidos.find({ "lineas.producto_id": 10 });

// d) Buscar pedidos cuyo total sea superior a un importe elegido (ej: total > 10000)
// Umbral elegido: 10000, justificado por representar pedidos mayoristas/medianos de la tienda.
print("--- d) Pedidos con total superior a 10000 ---");
db.pedidos.find({ total_pedido: { $gt: 10000 } });
