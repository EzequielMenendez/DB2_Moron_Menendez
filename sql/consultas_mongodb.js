// =====================================================================
// sql/consultas_mongodb.js
// Unidad 7: NoSQL y nuevas formas de almacenamiento | Food Store
// 
// PROCEDENCIA DE DATOS:
// Los 5 documentos migrados corresponden a registros reales extraídos 
// directamente de la base relacional Food Store (pedidos con IDs 1 al 5),
// preservando sus identificadores de origen, fechas, cliente, productos,
// cantidades y precios históricos.
// =====================================================================

use('foodstore_nosql');

db.dropDatabase();
db.createCollection("pedidos");

// Inserción (migración) con NumberDecimal para estricta precisión monetaria
db.pedidos.insertMany([
  {
    _id: 1,
    fecha: ISODate("2026-07-20T18:21:15.692-03:00"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 2,
      nombre: "Cliente2",
      apellido: "Apellido2",
      email: "cliente2@mail.com"
    },
    lineas: [
      { producto_id: 49, cantidad: 3, precio_unitario: NumberDecimal("289.88"), subtotal: NumberDecimal("869.64") },
      { producto_id: 66, cantidad: 4, precio_unitario: NumberDecimal("85.30"), subtotal: NumberDecimal("341.20") },
      { producto_id: 83, cantidad: 5, precio_unitario: NumberDecimal("124.34"), subtotal: NumberDecimal("621.70") }
    ],
    total_pedido: NumberDecimal("1832.54")
  },
  {
    _id: 2,
    fecha: ISODate("2026-03-29T10:14:55.499-03:00"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 3,
      nombre: "Cliente3",
      apellido: "Apellido3",
      email: "cliente3@mail.com"
    },
    lineas: [
      { producto_id: 80, cantidad: 4, precio_unitario: NumberDecimal("191.32"), subtotal: NumberDecimal("765.28") },
      { producto_id: 97, cantidad: 5, precio_unitario: NumberDecimal("295.22"), subtotal: NumberDecimal("1476.10") },
      { producto_id: 114, cantidad: 1, precio_unitario: NumberDecimal("62.27"), subtotal: NumberDecimal("62.27") }
    ],
    total_pedido: NumberDecimal("2303.65")
  },
  {
    _id: 3,
    fecha: ISODate("2026-09-12T01:44:48.470-03:00"),
    estado: "PENDIENTE",
    cliente: {
      id_cliente: 4,
      nombre: "Cliente4",
      apellido: "Apellido4",
      email: "cliente4@mail.com"
    },
    lineas: [
      { producto_id: 111, cantidad: 5, precio_unitario: NumberDecimal("409.94"), subtotal: NumberDecimal("2049.70") },
      { producto_id: 128, cantidad: 1, precio_unitario: NumberDecimal("335.66"), subtotal: NumberDecimal("335.66") },
      { producto_id: 145, cantidad: 2, precio_unitario: NumberDecimal("446.50"), subtotal: NumberDecimal("893.00") }
    ],
    total_pedido: NumberDecimal("3278.36")
  },
  {
    _id: 4,
    fecha: ISODate("2026-01-11T00:44:05.411-03:00"),
    estado: "CONFIRMADO",
    cliente: {
      id_cliente: 5,
      nombre: "Cliente5",
      apellido: "Apellido5",
      email: "cliente5@mail.com"
    },
    lineas: [
      { producto_id: 142, cantidad: 1, precio_unitario: NumberDecimal("214.68"), subtotal: NumberDecimal("214.68") },
      { producto_id: 159, cantidad: 2, precio_unitario: NumberDecimal("497.29"), subtotal: NumberDecimal("994.58") },
      { producto_id: 176, cantidad: 3, precio_unitario: NumberDecimal("120.25"), subtotal: NumberDecimal("360.75") }
    ],
    total_pedido: NumberDecimal("1570.01")
  },
  {
    _id: 5,
    fecha: ISODate("2026-02-11T13:38:35.719-03:00"),
    estado: "CANCELADO",
    cliente: {
      id_cliente: 6,
      nombre: "Cliente6",
      apellido: "Apellido6",
      email: "cliente6@mail.com"
    },
    lineas: [
      { producto_id: 173, cantidad: 2, precio_unitario: NumberDecimal("307.90"), subtotal: NumberDecimal("615.80") },
      { producto_id: 190, cantidad: 3, precio_unitario: NumberDecimal("375.59"), subtotal: NumberDecimal("1126.77") },
      { producto_id: 207, cantidad: 4, precio_unitario: NumberDecimal("472.93"), subtotal: NumberDecimal("1891.72") }
    ],
    total_pedido: NumberDecimal("3634.29")
  }
]);

// =====================================================================
// CONSIGNA 4: Consultas en MongoDB
// =====================================================================

// a) Mostrar todos los pedidos, incluyendo su identificador y estado
print("--- a) Todos los pedidos (id y estado) ---");
db.pedidos.find({}, { _id: 1, estado: 1, fecha: 1 }).toArray();

// b) Filtrar pedidos por un estado existente (ej: "CONFIRMADO")
print("--- b) Pedidos con estado CONFIRMADO ---");
db.pedidos.find({ estado: "CONFIRMADO" }).toArray();

// c) Buscar pedidos que contengan un producto determinado dentro del arreglo de líneas (ej: producto_id: 80)
print("--- c) Pedidos que contienen el producto_id 80 ---");
db.pedidos.find({ "lineas.producto_id": 80 }).toArray();

// d) Buscar pedidos cuyo total sea superior a un importe elegido (ej: total > 2000)
// Umbral elegido: 2000, justificado por representar pedidos medianos/altos dentro de la muestra.
print("--- d) Pedidos con total superior a 2000 ---");
db.pedidos.find({ total_pedido: { $gt: NumberDecimal("2000") } }).toArray();
