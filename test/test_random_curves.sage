"""
test_random_curves.sage — Unit tests for random_curves.sage.

Run from the repo root via:
    sage test/runtests.sage
"""

import unittest

load('random_generation/random_curves.sage')


class TestRandomHyperellipticOddDegree(unittest.TestCase):

    def _check_curve(self, C, expected_genus, expected_degree):
        """Assert all structural properties of a generated curve."""
        f, h = C.hyperelliptic_polynomials()
        self.assertEqual(C.genus(), expected_genus,
                         f"Expected genus {expected_genus}, got {C.genus()}")
        self.assertEqual(f.degree(), expected_degree,
                         f"Expected deg(f)={expected_degree}, got {f.degree()}")
        self.assertTrue(f.is_monic(),
                        f"f is not monic: {f}")
        self.assertEqual(f[f.degree() - 1], 0,
                         f"f is not depressed (x^{f.degree()-1} coeff = {f[f.degree()-1]}): {f}")
        self.assertTrue(f.is_squarefree(),
                        f"f is not squarefree: {f}")
        self.assertEqual(h, 0,
                         f"Expected h=0, got h={h}")

    def test_genus2_p7(self):
        for _ in range(5):
            C = random_hyperelliptic_odd_degree(7, 2)
            self._check_curve(C, expected_genus=2, expected_degree=5)

    def test_genus3_p11(self):
        for _ in range(5):
            C = random_hyperelliptic_odd_degree(11, 3)
            self._check_curve(C, expected_genus=3, expected_degree=7)

    def test_genus1_p5(self):
        for _ in range(5):
            C = random_hyperelliptic_odd_degree(5, 1)
            self._check_curve(C, expected_genus=1, expected_degree=3)


class TestRandomHyperellipticEvenDegree(unittest.TestCase):

    def _check_curve(self, C, expected_genus, expected_degree):
        f, h = C.hyperelliptic_polynomials()
        self.assertEqual(C.genus(), expected_genus,
                         f"Expected genus {expected_genus}, got {C.genus()}")
        self.assertEqual(f.degree(), expected_degree,
                         f"Expected deg(f)={expected_degree}, got {f.degree()}")
        self.assertTrue(f.is_monic(),
                        f"f is not monic: {f}")
        self.assertEqual(f[f.degree() - 1], 0,
                         f"f is not depressed (x^{f.degree()-1} coeff = {f[f.degree()-1]}): {f}")
        self.assertTrue(f.is_squarefree(),
                        f"f is not squarefree: {f}")
        self.assertEqual(h, 0,
                         f"Expected h=0, got h={h}")

    def test_genus2_p7(self):
        for _ in range(5):
            C = random_hyperelliptic_even_degree(7, 2)
            self._check_curve(C, expected_genus=2, expected_degree=6)

    def test_genus3_p11(self):
        for _ in range(5):
            C = random_hyperelliptic_even_degree(11, 3)
            self._check_curve(C, expected_genus=3, expected_degree=8)

    def test_genus1_p5(self):
        for _ in range(5):
            C = random_hyperelliptic_even_degree(5, 1)
            self._check_curve(C, expected_genus=1, expected_degree=4)


class TestRandomHyperellipticWrapper(unittest.TestCase):

    def test_odd_degree_dispatches_correctly(self):
        C = random_hyperelliptic(7, 5)
        f, _ = C.hyperelliptic_polynomials()
        self.assertEqual(f.degree(), 5)
        self.assertEqual(C.genus(), 2)

    def test_even_degree_dispatches_correctly(self):
        C = random_hyperelliptic(7, 6)
        f, _ = C.hyperelliptic_polynomials()
        self.assertEqual(f.degree(), 6)
        self.assertEqual(C.genus(), 2)

    def test_raises_on_p2(self):
        with self.assertRaises(ValueError):
            random_hyperelliptic(2, 5)

    def test_raises_on_small_degree(self):
        with self.assertRaises(ValueError):
            random_hyperelliptic(7, 2)

    def test_raises_on_degree_1(self):
        with self.assertRaises(ValueError):
            random_hyperelliptic(7, 1)


