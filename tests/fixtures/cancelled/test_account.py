import unittest

from account import account_label, analytics_enabled


class AccountTests(unittest.TestCase):
    def test_display_name(self):
        self.assertEqual("Ada", account_label(" Ada "))

    def test_analytics_stays_off(self):
        self.assertFalse(analytics_enabled())
