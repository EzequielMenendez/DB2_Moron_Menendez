import importlib.util
from contextlib import closing
import tempfile
import sqlite3
from pathlib import Path
import unittest

MODULE = Path(__file__).resolve().parents[1] / 'simulador.py'
spec=importlib.util.spec_from_file_location('simulador',MODULE)
simulador=importlib.util.module_from_spec(spec)
spec.loader.exec_module(simulador)

class DemoTest(unittest.TestCase):
    def test_demo_new_database(self):
        with tempfile.TemporaryDirectory() as tmp:
            target=Path(tmp)/'demo.db'
            simulador.crear_demo(target)
            with closing(simulador.conectar(target)) as db:
                self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok')
                self.assertEqual(db.execute('SELECT count(*) FROM pedido_borrador').fetchone()[0],1)
                self.assertEqual(db.execute('SELECT estado FROM cola_sync').fetchone()[0],'PENDIENTE')
                self.assertEqual(db.execute('SELECT count(*) FROM snapshot_servidor').fetchone()[0],2)

    def test_demo_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            target=Path(tmp)/'demo.db'
            target.write_bytes(b'contenido previo')
            with self.assertRaises(FileExistsError):
                simulador.crear_demo(target)
            self.assertEqual(target.read_bytes(),b'contenido previo')

    def test_import_invalid_csv_rolls_back(self):
        with tempfile.TemporaryDirectory() as tmp:
            target=Path(tmp)/'demo.db'
            simulador.crear_demo(target)
            with closing(simulador.conectar(target)) as db:
                before=db.execute('SELECT * FROM snapshot_servidor ORDER BY id').fetchall()
                bad=Path(tmp)/'bad.csv'
                bad.write_text('id,nombre,precio_centavos,stock,disponible,eliminado,fecha_copia\n10,Cafe,100,5,t,f,2026-11-01\n15,Azucar,-1,3,t,f,2026-11-01\n',encoding='utf-8')
                with self.assertRaises(sqlite3.IntegrityError):
                    simulador.importar_snapshot(db,bad)
                self.assertEqual(db.execute('SELECT * FROM snapshot_servidor ORDER BY id').fetchall(),before)

if __name__=='__main__':
    unittest.main()
