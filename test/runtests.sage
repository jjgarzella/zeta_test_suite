"""
runtests.sage — Central test runner for the zeta_test_suite test suite.

Run from the repo root:
    sage test/runtests.sage

To add a new test file, load it below and add its TestCase classes to the suite.
"""

import unittest
import os

# ── Load test modules ────────────────────────────────────────────────────────

load('test/test_random_curves.sage')
load('test/test_random_curves_char2.sage')
load('test/test_loader_saver.sage')

# ── Collect and run all tests ────────────────────────────────────────────────

loader = unittest.TestLoader()
suite = unittest.TestSuite()

# Add test cases here as new test files are added
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticOddDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticEvenDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticWrapper))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticChar2OddDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticChar2EvenDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticWrapperChar2))
suite.addTests(loader.loadTestsFromTestCase(TestLoaderPerKind))
suite.addTests(loader.loadTestsFromTestCase(TestLoaderShorthandExpansion))
suite.addTests(loader.loadTestsFromTestCase(TestLoaderRejections))
suite.addTests(loader.loadTestsFromTestCase(TestSaverRoundTrip))
suite.addTests(loader.loadTestsFromTestCase(TestSaverFromSageObjects))
suite.addTests(loader.loadTestsFromTestCase(TestSaverUpsert))

runner = unittest.TextTestRunner(verbosity=2)
result = runner.run(suite)

os._exit(0 if result.wasSuccessful() else 1)
