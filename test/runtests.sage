"""
runtests.sage — Central test runner for the hyperell_suite test suite.

Run from the repo root:
    sage test/runtests.sage

To add a new test file, load it below and add its TestCase classes to the suite.
"""

import unittest
import os

# ── Load test modules ────────────────────────────────────────────────────────

load('test/test_random_curves.sage')

# ── Collect and run all tests ────────────────────────────────────────────────

loader = unittest.TestLoader()
suite = unittest.TestSuite()

# Add test cases here as new test files are added
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticOddDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticEvenDegree))
suite.addTests(loader.loadTestsFromTestCase(TestRandomHyperellipticWrapper))

runner = unittest.TextTestRunner(verbosity=2)
result = runner.run(suite)

os._exit(0 if result.wasSuccessful() else 1)
