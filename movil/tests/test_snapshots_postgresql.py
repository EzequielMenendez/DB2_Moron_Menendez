"""C2-C4 sobre CSV exportados realmente desde PostgreSQL aislado."""
import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

MOVIL=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('simulador',MOVIL/'simulador.py')
simulador=importlib.util.module_from_spec(spec)
spec.loader.exec_module(simulador)

class SnapshotPostgresqlTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        path=Path(self.tmp.name)/'demo.db'
        simulador.crear_demo(path)
        self.db=simulador.conectar(path)
        self.addCleanup(self.db.close)

    def estado(self):
        return self.db.execute('SELECT estado FROM cola_sync ORDER BY solicitud_uuid').fetchall()

    def importar_evaluar(self,nombre):
        simulador.importar_snapshot(self.db,MOVIL/'snapshots'/nombre)
        simulador.ejecutar(self.db,'cargar_cache.sql')
        simulador.ejecutar(self.db,'semaforo.sql')

    def test_csv_c2_precio_conflicto_y_aceptacion(self):
        self.importar_evaluar('c2_precio.csv')
        self.assertEqual(self.estado(),[('CONFLICTO',)])
        with self.db:
            self.db.execute('UPDATE item_borrador SET precio_centavos_visto=460000 WHERE producto_id=10')
            self.db.execute("INSERT INTO cola_sync SELECT '20000000-0000-4000-8000-000000000002',id_local,'PENDIENTE',NULL FROM pedido_borrador")
        simulador.ejecutar(self.db,'semaforo.sql')
        self.assertEqual(self.estado(),[('CONFLICTO',),('SIMULADO_APROBADO',)])

    def test_csv_c3_stock_rechazado(self):
        self.importar_evaluar('c3_stock.csv')
        self.assertEqual(self.estado(),[('RECHAZADO',)])

    def test_csv_c4_baja_rechazo_y_lapida(self):
        self.importar_evaluar('c4_baja.csv')
        self.assertEqual(self.estado(),[('RECHAZADO',)])
        self.assertEqual(self.db.execute('SELECT eliminado FROM producto_cache WHERE id=10').fetchone()[0],1)
        self.assertEqual(self.db.execute('SELECT id FROM producto_cache WHERE disponible=1 AND eliminado=0').fetchall(),[(15,)])
        self.assertEqual(self.db.execute('SELECT count(*) FROM item_borrador WHERE producto_id=10').fetchone()[0],1)

if __name__=='__main__':
    unittest.main()
