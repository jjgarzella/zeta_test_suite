"""
test_loader_saver_v2.sage — Unit tests for the v2 grouped-case loader and saver.

Run from the repo root via:
    HOME=/tmp sage test/runtests.sage
"""

import json
import os
import unittest

load('sage/loader_v2.sage')
load('sage/saver_v2.sage')


FIXTURE = 'test/fixtures/grouped_integer_case_v2.json'


class TestLoaderV2(unittest.TestCase):

    def test_load_case_returns_grouped_data(self):
        cases = load_cases(FIXTURE)
        self.assertEqual(len(cases), 1)
        case = cases[0]
        self.assertEqual(case.id, 'g2_d5_a')
        self.assertEqual(case.curve['coeff_domain']['kind'], 'integer')
        self.assertEqual(case.curve['genus'], 2)
        self.assertEqual(len(case.results), 3)

    def test_expand_case_returns_loaded_prime_cases(self):
        cases = load_cases(FIXTURE)
        expanded = expand_case({
            'id': cases[0].id,
            'curve': cases[0].curve,
            'results': cases[0].results,
            'notes': cases[0].notes,
        })
        self.assertEqual(len(expanded), 3)
        self.assertEqual([item.p for item in expanded], [5, 7, 11])
        self.assertEqual(expanded[0].expected_Lpoly, [1, 5, 15, 25, 25])
        self.assertEqual(expanded[1].expected_Lpoly, [1, -1, 0, -7, 49])
        self.assertEqual(expanded[2].expected_Lpoly, [1, 7, 31, 77, 121])
        for item in expanded:
            self.assertEqual(item.curve.genus(), 2)

    def test_load_expanded_cases_flattens_file(self):
        expanded = load_expanded_cases(FIXTURE)
        self.assertEqual(len(expanded), 3)
        self.assertEqual(expanded[0].id, 'g2_d5_a')


class TestSaverV2(unittest.TestCase):

    def test_save_case_writes_grouped_singleton_case(self):
        F = GF(7)
        R = PolynomialRing(F, 'x')
        x = R.gen()
        C = HyperellipticCurve(x**5 - x + 1)
        out = '/tmp/hyperell_suite_v2_singleton.json'
        if os.path.exists(out):
            os.remove(out)

        save_case(C, [1, -1, 0, -7, 49], out, id='g2_d5_singleton', notes='singleton test')

        with open(out, 'r') as fh:
            data = json.load(fh)

        self.assertEqual(len(data['cases']), 1)
        case = data['cases'][0]
        self.assertEqual(case['id'], 'g2_d5_singleton')
        self.assertEqual(case['curve']['coeff_domain']['kind'], 'integer')
        self.assertEqual(case['results'], [
            {
                'p': 7,
                'Lpoly': {
                    'coeffs_asc': [1, -1, 0, -7, 49]
                }
            }
        ])

    def test_save_grouped_case_replaces_by_id(self):
        out = '/tmp/hyperell_suite_v2_grouped.json'
        if os.path.exists(out):
            os.remove(out)

        case1 = {
            'id': 'g2_d5_a',
            'curve': {
                'coeff_domain': {'kind': 'integer'},
                'genus': 2,
                'model': {
                    'pretty': 'y^2 = x^5 - x + 1',
                    'x_var': 'x',
                    'y_var': 'y',
                    't_var': 't',
                    'h_coeffs_asc': [0],
                    'f_coeffs_asc': [1, -1, 0, 0, 0, 1],
                },
            },
            'results': [
                {
                    'p': 5,
                    'Lpoly': {'coeffs_asc': [1, 5, 15, 25, 25]},
                }
            ],
            'notes': 'first version',
        }
        case2 = {
            'id': 'g2_d5_a',
            'curve': case1['curve'],
            'results': [
                {
                    'p': 7,
                    'Lpoly': {'coeffs_asc': [1, -1, 0, -7, 49]},
                }
            ],
            'notes': 'replacement version',
        }

        save_grouped_case(case1, out)
        save_grouped_case(case2, out)

        with open(out, 'r') as fh:
            data = json.load(fh)

        self.assertEqual(len(data['cases']), 1)
        self.assertEqual(data['cases'][0]['notes'], 'replacement version')
        self.assertEqual(data['cases'][0]['results'][0]['p'], 7)
