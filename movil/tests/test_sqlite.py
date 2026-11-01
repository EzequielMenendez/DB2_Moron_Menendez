"""Pruebas de contrato TP8: sólo SQLite en memoria, sin red ni datos reales."""
import csv
import sqlite3
import unittest
from pathlib import Path
from uuid import UUID

MOVIL = Path(__file__).resolve().parents[1]
DRAFT = "10000000-0000-4000-8000-000000000001"
REQUEST = "20000000-0000-4000-8000-000000000001"
REQUEST2 = "20000000-0000-4000-8000-000000000002"

class TabletTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        self.db.executescript((MOVIL / "schema_sqlite.sql").read_text(encoding="utf-8-sig"))
        self.db.execute("INSERT INTO snapshot_servidor VALUES (10,'Cafe',450000,10,'t','f','2026-11-01T12:00:00Z')")
        self.db.execute("INSERT INTO snapshot_servidor VALUES (15,'Azucar',120000,5,'t','f','2026-11-01T12:00:00Z')")
        self.cache()

    def cache(self):
        self.db.executescript((MOVIL / "cargar_cache.sql").read_text(encoding="utf-8-sig"))

    def draft(self, quantity=2, price=450000):
        self.db.execute("INSERT INTO pedido_borrador VALUES (?, 'DEMO-01','EFECTIVO','2026-11-01T12:00:00Z')", (DRAFT,))
        self.db.execute("INSERT INTO item_borrador VALUES (?,10,?,?)", (DRAFT, quantity, price))
        self.db.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE',NULL)", (REQUEST,DRAFT))
        self.db.commit()

    def evaluate(self):
        self.db.executescript((MOVIL / "semaforo.sql").read_text(encoding="utf-8-sig"))
        return self.db.execute("SELECT estado FROM cola_sync WHERE solicitud_uuid=?", (REQUEST,)).fetchone()[0]

    def test_strict_and_foreign_keys(self):
        self.assertEqual(self.db.execute("PRAGMA foreign_keys").fetchone()[0],1)
        self.assertEqual(sum(row[-1] for row in self.db.execute("PRAGMA table_list") if row[1] in ('producto_cache','pedido_borrador','item_borrador','cola_sync')),4)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE producto_cache SET precio_centavos='invalido' WHERE id=10")

    def test_c1_catalogue_offline(self):
        self.assertEqual(self.db.execute("SELECT id FROM producto_cache WHERE disponible=1 AND eliminado=0 ORDER BY id").fetchall(),[(10,),(15,)])

    def test_cache_tombstone_and_missing_keep_references(self):
        self.draft()
        self.db.execute("UPDATE snapshot_servidor SET eliminado='t' WHERE id=10")
        self.db.execute("DELETE FROM snapshot_servidor WHERE id=15")
        self.cache()
        self.assertEqual(self.db.execute("SELECT id,eliminado FROM producto_cache ORDER BY id").fetchall(),[(10,1),(15,1)])
        self.assertEqual(self.db.execute("SELECT count(*) FROM producto_cache WHERE disponible=1 AND eliminado=0").fetchone()[0],0)
        self.assertEqual(self.db.execute("SELECT count(*) FROM item_borrador").fetchone()[0],1)

    def test_c2_conflict_then_new_request(self):
        self.draft()
        self.db.execute("UPDATE snapshot_servidor SET precio_centavos=460000 WHERE id=10")
        self.assertEqual(self.evaluate(),'CONFLICTO')
        self.db.execute("UPDATE item_borrador SET precio_centavos_visto=460000 WHERE id_local=?",(DRAFT,))
        self.db.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE',NULL)",(REQUEST2,DRAFT))
        self.evaluate()
        self.assertEqual(self.db.execute("SELECT estado FROM cola_sync ORDER BY solicitud_uuid").fetchall(),[('CONFLICTO',),('SIMULADO_APROBADO',)])

    def test_c3_insufficient_stock(self):
        self.draft(quantity=11)
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_stock_exact_is_green(self):
        self.draft(quantity=10)
        self.assertEqual(self.evaluate(),'SIMULADO_APROBADO')

    def test_c4_deleted_is_red(self):
        self.draft()
        self.db.execute("UPDATE snapshot_servidor SET eliminado='t' WHERE id=10")
        self.assertEqual(self.evaluate(),'RECHAZADO')
        self.cache()
        self.assertEqual(self.db.execute("SELECT eliminado FROM producto_cache WHERE id=10").fetchone()[0],1)

    def test_unavailable_is_red(self):
        self.draft()
        self.db.execute("UPDATE snapshot_servidor SET disponible='f' WHERE id=10")
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_missing_is_red(self):
        self.draft()
        self.db.execute("DELETE FROM snapshot_servidor WHERE id=10")
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_red_precedes_yellow(self):
        self.draft(price=1)
        self.db.execute("UPDATE snapshot_servidor SET stock=0 WHERE id=10")
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_c5_green_does_not_mutate_snapshot(self):
        self.draft()
        before=self.db.execute("SELECT * FROM snapshot_servidor ORDER BY id").fetchall()
        self.assertEqual(self.evaluate(),'SIMULADO_APROBADO')
        self.assertEqual(self.db.execute("SELECT * FROM snapshot_servidor ORDER BY id").fetchall(),before)

    def test_c6_duplicate_uuid_and_reevaluation(self):
        self.draft()
        self.assertEqual(self.evaluate(),'SIMULADO_APROBADO')
        before=self.db.execute("SELECT * FROM cola_sync").fetchall()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE',NULL)",(REQUEST,DRAFT))
        self.db.rollback()
        self.db.execute("UPDATE snapshot_servidor SET stock=0")
        self.assertEqual(self.evaluate(),'SIMULADO_APROBADO')
        self.assertEqual(self.db.execute("SELECT * FROM cola_sync").fetchall(),before)

    def test_c7_zero_and_missing_product_atomic_rollback(self):
        for quantity,product in [(0,10),(1,999)]:
            with self.subTest(quantity=quantity,product=product):
                with self.assertRaises(sqlite3.IntegrityError):
                    with self.db:
                        self.db.execute("INSERT INTO pedido_borrador VALUES (?, 'DEMO-01','EFECTIVO','2026-11-01T12:00:00Z')",(DRAFT,))
                        self.db.execute("INSERT INTO item_borrador VALUES (?,?,?,1)",(DRAFT,product,quantity))
                self.assertEqual(self.db.execute("SELECT count(*) FROM pedido_borrador").fetchone()[0],0)
                self.assertEqual(self.db.execute("SELECT count(*) FROM item_borrador").fetchone()[0],0)

    def test_commit_and_rollback(self):
        self.draft()
        self.db.execute("UPDATE item_borrador SET cantidad=3")
        self.db.rollback()
        self.assertEqual(self.db.execute("SELECT cantidad FROM item_borrador").fetchone()[0],2)
        self.assertEqual(self.db.execute("SELECT count(*) FROM cola_sync").fetchone()[0],1)

    def test_domains_and_non_negative_money(self):
        self.draft()
        for sql in ["UPDATE producto_cache SET precio_centavos=-1", "UPDATE producto_cache SET disponible=2", "UPDATE producto_cache SET eliminado=2", "UPDATE pedido_borrador SET forma_pago='OTRA'", "UPDATE cola_sync SET estado='VENTA'", "UPDATE item_borrador SET precio_centavos_visto=-1"]:
            with self.subTest(sql=sql):
                with self.assertRaises(sqlite3.IntegrityError):
                    self.db.execute(sql)
                self.db.rollback()

    def test_empty_request_rejected(self):
        self.draft()
        self.db.execute("DELETE FROM item_borrador")
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_multiple_items_reject_any_red(self):
        self.draft()
        self.db.execute("INSERT INTO item_borrador VALUES (?,15,6,120000)",(DRAFT,))
        self.assertEqual(self.evaluate(),'RECHAZADO')

    def test_pruebas_sql_script_expected_errors(self):
        script=(MOVIL/'pruebas_sqlite.sql').read_text(encoding='utf-8-sig')
        errors=[]
        statement=''
        for line in script.splitlines(keepends=True):
            statement+=line
            if sqlite3.complete_statement(statement):
                try:
                    self.db.execute(statement)
                except sqlite3.IntegrityError as error:
                    errors.append(str(error))
                statement=''
        self.assertEqual(len(errors),2)
        self.assertIn('CHECK constraint failed',errors[0])
        self.assertIn('FOREIGN KEY constraint failed',errors[1])
        self.assertEqual(self.db.execute('SELECT count(*) FROM pedido_borrador').fetchone()[0],1)
        self.assertEqual(self.db.execute('SELECT count(*) FROM item_borrador').fetchone()[0],1)
        self.assertEqual(self.db.execute('SELECT count(*) FROM cola_sync').fetchone()[0],1)
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(),[])

    def test_multiple_items_price_conflict(self):
        self.draft()
        self.db.execute("INSERT INTO item_borrador VALUES (?,15,1,119999)",(DRAFT,))
        self.assertEqual(self.evaluate(),'CONFLICTO')

if __name__ == '__main__':
    unittest.main()
