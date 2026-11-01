"""Utilidades opcionales TP8; los contratos de dominio estan en los scripts SQL."""
import argparse
import csv
import sqlite3
from pathlib import Path

MOVIL = Path(__file__).resolve().parent
COLUMNAS = ('id','nombre','precio_centavos','stock','disponible','eliminado','fecha_copia')


def conectar(ruta):
    if sqlite3.sqlite_version_info < (3,37,0):
        raise RuntimeError('Se requiere SQLite >= 3.37 para tablas STRICT')
    conexion = sqlite3.connect(ruta)
    conexion.execute('PRAGMA foreign_keys = ON')
    return conexion


def ejecutar(conexion, archivo):
    conexion.executescript((MOVIL / archivo).read_text(encoding='utf-8-sig'))


def importar_snapshot(conexion, ruta):
    """Reemplaza una instantanea completa; cualquier fila invalida revierte el lote."""
    with Path(ruta).open(encoding='utf-8-sig',newline='') as archivo:
        lector = csv.DictReader(archivo)
        if tuple(lector.fieldnames or ()) != COLUMNAS:
            raise ValueError('Cabecera CSV distinta del contrato v_snapshot_movil')
        filas = [tuple(fila[c] for c in COLUMNAS) for fila in lector]
    with conexion:
        conexion.execute('DELETE FROM snapshot_servidor')
        conexion.executemany('INSERT INTO snapshot_servidor VALUES (?,?,?,?,?,?,?)',filas)


def crear_demo(ruta, snapshot=None):
    """Crea una base nueva con datos inventados. Nunca sobreescribe archivos."""
    ruta = Path(ruta)
    with ruta.open('xb'):
        pass
    conexion = None
    try:
        conexion = conectar(ruta)
        ejecutar(conexion,'schema_sqlite.sql')
        importar_snapshot(conexion,snapshot or MOVIL/'servidor_snapshot.csv')
        ejecutar(conexion,'cargar_cache.sql')
        with conexion:
            conexion.execute("INSERT INTO pedido_borrador VALUES ('10000000-0000-4000-8000-000000000001','DEMO-01','EFECTIVO','2026-11-01T12:00:00Z')")
            conexion.execute("INSERT INTO item_borrador VALUES ('10000000-0000-4000-8000-000000000001',10,2,450000)")
            conexion.execute("INSERT INTO cola_sync VALUES ('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','PENDIENTE',NULL)")
    except Exception:
        if conexion is not None:
            conexion.close()
        ruta.unlink(missing_ok=True)
        raise
    else:
        conexion.close()


def main():
    parser=argparse.ArgumentParser(description='TP8: crear DB sintetica o evaluar borradores sin conexion al servidor')
    accion=parser.add_mutually_exclusive_group(required=True)
    accion.add_argument('--crear-demo',metavar='DB_NUEVA',type=Path)
    accion.add_argument('--evaluar',metavar='DB_EXISTENTE',type=Path)
    parser.add_argument('--snapshot',type=Path,help='CSV completo exportado de PostgreSQL; opcional')
    args=parser.parse_args()
    try:
        if args.crear_demo:
            crear_demo(args.crear_demo,args.snapshot)
            print('DB creada con un borrador PENDIENTE; ningun pedido confirmado.')
        else:
            if not args.evaluar.is_file():
                raise FileNotFoundError('No existe la base a evaluar')
            conexion=conectar(args.evaluar)
            try:
                if args.snapshot:
                    importar_snapshot(conexion,args.snapshot)
                    ejecutar(conexion,'cargar_cache.sql')
                ejecutar(conexion,'semaforo.sql')
                for fila in conexion.execute('SELECT solicitud_uuid,estado,motivo FROM cola_sync ORDER BY solicitud_uuid'):
                    print(' | '.join(fila))
            finally:
                conexion.close()
    except (OSError,ValueError,sqlite3.Error,RuntimeError) as error:
        parser.exit(1,f'No se completo la operacion: {error}\n')

if __name__=='__main__':
    main()
