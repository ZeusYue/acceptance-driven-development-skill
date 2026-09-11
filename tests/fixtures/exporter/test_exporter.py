import unittest

from exporter import export_rows


class ExportTests(unittest.TestCase):
    def test_default_limit(self):
        self.assertEqual(list(range(10)), export_rows(range(30)))

    def test_explicit_limit(self):
        self.assertEqual(list(range(5)), export_rows(range(30), 5))

    def test_short_input(self):
        self.assertEqual(["a", "b"], export_rows(["a", "b"]))

    def test_nonpositive_limit(self):
        self.assertEqual([], export_rows(range(30), 0))
        self.assertEqual([], export_rows(range(30), -1))
