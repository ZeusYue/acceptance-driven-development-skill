import unittest

from reporter import export_rows, item_label


class ReporterTests(unittest.TestCase):
    def test_one_item(self):
        self.assertEqual("1 item", item_label(1))

    def test_plural_items(self):
        self.assertEqual("0 items", item_label(0))
        self.assertEqual("2 items", item_label(2))

    def test_existing_export(self):
        self.assertEqual(list(range(10)), export_rows(range(20)))
