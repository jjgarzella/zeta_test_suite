"""
test_loader_saver.sage — Unit tests for the v3 loader and saver.

Run from the repo root via:
    sage test/runtests.sage
"""

import copy
import json
import os
import tempfile
import unittest

load('sage/loader.sage')
load('sage/saver.sage')


FIXTURE_DIR = 'test/fixtures'


def _fixture_path(name):
    return os.path.join(FIXTURE_DIR, name)


def _read_json(path):
    with open(path, 'r') as fh:
        return json.load(fh)


def _to_json_native(obj):
    if isinstance(obj, dict):
        return {k: _to_json_native(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_to_json_native(x) for x in obj]
    if isinstance(obj, str):
        return obj
    if isinstance(obj, bool):
        return obj
    try:
        return int(obj)
    except (TypeError, ValueError):
        return obj


def _write_tmp(doc):
    fd, path = tempfile.mkstemp(suffix='.json')
    with os.fdopen(fd, 'w') as fh:
        json.dump(_to_json_native(doc), fh)
    return path


# ----------------------------------------------------------------------
# TestLoaderPerKind: each kind's fixture loads cleanly
# ----------------------------------------------------------------------

class TestLoaderPerKind(unittest.TestCase):

    def test_hyperelliptic(self):
        cases = load_cases(_fixture_path('hyperelliptic.json'))
        self.assertEqual(len(cases), 1)
        case = cases[0]
        self.assertEqual(case.id, 'g2_d5_a')
        self.assertEqual(case.variety['model']['kind'], 'hyperelliptic')
        self.assertEqual(case.variety['dim'], 1)
        self.assertEqual(case.variety['genus'], 2)

        expanded = load_expanded_cases(_fixture_path('hyperelliptic.json'))
        self.assertEqual(len(expanded), 3)
        self.assertEqual([e.p for e in expanded], [5, 7, 11])
        self.assertEqual(expanded[0].variety.kind, 'hyperelliptic')
        self.assertEqual(expanded[0].variety.sage_object.genus(), 2)
        self.assertEqual(expanded[1].expected_l_factors[1], [1, -1, 0, -7, 49])

    def test_superelliptic(self):
        expanded = load_expanded_cases(_fixture_path('superelliptic.json'))
        self.assertEqual(len(expanded), 1)
        case = expanded[0]
        self.assertEqual(case.variety.kind, 'superelliptic')
        self.assertEqual(case.variety.dim, 1)
        self.assertEqual(case.variety.genus, 3)
        self.assertEqual(case.variety.polys['m'], 3)

    def test_plane_curve(self):
        expanded = load_expanded_cases(_fixture_path('plane_curve.json'))
        case = expanded[0]
        self.assertEqual(case.variety.kind, 'plane_curve')
        self.assertEqual(case.variety.dim, 1)
        self.assertIsNotNone(case.variety.sage_object)

    def test_projective_hypersurface(self):
        expanded = load_expanded_cases(_fixture_path('projective_hypersurface.json'))
        case = expanded[0]
        self.assertEqual(case.variety.kind, 'projective_hypersurface')
        self.assertEqual(case.variety.dim, 2)
        # Explicit mode: all five degrees 0..4 must be present.
        self.assertEqual(sorted(case.expected_l_factors.keys()), [0, 1, 2, 3, 4])
        self.assertEqual(case.expected_l_factors[4], [1, -49])

    def test_double_cover_P2(self):
        expanded = load_expanded_cases(_fixture_path('double_cover_P2.json'))
        case = expanded[0]
        self.assertEqual(case.variety.kind, 'double_cover_P2')
        self.assertEqual(case.variety.dim, 2)
        self.assertEqual(case.variety.polys['m'], 2)

    def test_cyclic_cover(self):
        expanded = load_expanded_cases(_fixture_path('cyclic_cover.json'))
        case = expanded[0]
        self.assertEqual(case.variety.kind, 'cyclic_cover')
        self.assertEqual(case.variety.polys['m'], 3)


# ----------------------------------------------------------------------
# TestLoaderShorthandExpansion
# ----------------------------------------------------------------------

class TestLoaderShorthandExpansion(unittest.TestCase):

    def test_hyperelliptic_shorthand_full(self):
        # Curve dim=1, full middle: P_0 = (1 - T), P_2 = (1 - pT), P_1 = given Lpoly.
        expanded = load_expanded_cases(_fixture_path('hyperelliptic.json'))
        first = expanded[0]
        self.assertEqual(first.expected_l_factors[0], [1, -1])
        self.assertEqual(first.expected_l_factors[2], [1, -5])
        self.assertEqual(first.expected_l_factors[1], [1, 5, 15, 25, 25])

    def test_cyclic_cover_primitive_middle(self):
        # dim=2, primitive middle: P_2 = (1 - pT) * primitive.
        # Fixture has p=7, primitive middle = [1, 0, 0, 0, 49].
        # (1 - 7T) * (1 + 49 T^4) = [1, -7, 0, 0, 49, -343]
        expanded = load_expanded_cases(_fixture_path('cyclic_cover.json'))
        case = expanded[0]
        self.assertEqual(case.expected_l_factors[0], [1, -1])
        self.assertEqual(case.expected_l_factors[4], [1, -49])
        self.assertEqual(case.expected_l_factors[2], [1, -7, 0, 0, 49, -343])
        # Odd degrees inherit lefschetz factor 1.
        self.assertEqual(case.expected_l_factors[1], [1])
        self.assertEqual(case.expected_l_factors[3], [1])


# ----------------------------------------------------------------------
# TestLoaderRejections: each error path raises the expected exception
# ----------------------------------------------------------------------

class TestLoaderRejections(unittest.TestCase):

    def _make_doc(self, **overrides):
        doc = _read_json(_fixture_path('hyperelliptic.json'))
        doc['cases'] = doc['cases'][:1]
        doc['cases'][0]['results'] = doc['cases'][0]['results'][:1]
        for k, v in overrides.items():
            doc[k] = v
        return doc

    def test_wrong_schema_version(self):
        bad = self._make_doc(schema_version="2")
        path = _write_tmp(bad)
        try:
            with self.assertRaises(ValueError):
                load_cases(path)
        finally:
            os.unlink(path)

    def test_number_field_coeff_domain(self):
        bad = self._make_doc()
        bad['cases'][0]['variety']['coeff_domain'] = {"kind": "number_field"}
        path = _write_tmp(bad)
        try:
            with self.assertRaises(NotImplementedError):
                load_expanded_cases(path)
        finally:
            os.unlink(path)

    def test_toric_lefschetz(self):
        bad = self._make_doc()
        bad['cases'][0]['variety']['non_middle_factors'] = {
            "kind": "toric_lefschetz",
            "middle_factor_content": "full",
        }
        path = _write_tmp(bad)
        try:
            with self.assertRaises(NotImplementedError):
                load_expanded_cases(path)
        finally:
            os.unlink(path)

    def test_shorthand_with_explicit_convention(self):
        bad = self._make_doc()
        bad['cases'][0]['variety']['non_middle_factors'] = {"kind": "explicit"}
        # Result still uses Lpoly shorthand — should be rejected.
        path = _write_tmp(bad)
        try:
            with self.assertRaises(ValueError):
                load_expanded_cases(path)
        finally:
            os.unlink(path)

    def test_explicit_missing_keys(self):
        bad = _read_json(_fixture_path('projective_hypersurface.json'))
        # Drop one required degree from explicit l_factors.
        del bad['cases'][0]['results'][0]['l_factors']["3"]
        path = _write_tmp(bad)
        try:
            with self.assertRaises(ValueError):
                load_expanded_cases(path)
        finally:
            os.unlink(path)

    def test_both_lpoly_and_l_factors(self):
        bad = self._make_doc()
        bad['cases'][0]['results'][0]['l_factors'] = {"0": {"coeffs_asc": [1]}}
        path = _write_tmp(bad)
        try:
            with self.assertRaises(ValueError):
                load_expanded_cases(path)
        finally:
            os.unlink(path)


# ----------------------------------------------------------------------
# TestSaverRoundTrip: save then load each kind, verify equivalence
# ----------------------------------------------------------------------

class TestSaverRoundTrip(unittest.TestCase):

    def _round_trip(self, fixture_name):
        original = _read_json(_fixture_path(fixture_name))
        # Re-save the original case via save_grouped_case into a fresh
        # file, then reload and compare structure.
        fd, path = tempfile.mkstemp(suffix='.json')
        os.close(fd)
        os.unlink(path)
        try:
            for case in original['cases']:
                save_grouped_case(case, path)
            roundtripped = _read_json(path)
            self.assertEqual(roundtripped['schema_version'], '3')
            self.assertEqual(len(roundtripped['cases']), len(original['cases']))
            self.assertEqual(roundtripped['cases'][0]['id'],
                             original['cases'][0]['id'])
            self.assertEqual(roundtripped['cases'][0]['variety']['model']['kind'],
                             original['cases'][0]['variety']['model']['kind'])
        finally:
            if os.path.exists(path):
                os.unlink(path)

    def test_hyperelliptic_round_trip(self):
        self._round_trip('hyperelliptic.json')

    def test_superelliptic_round_trip(self):
        self._round_trip('superelliptic.json')

    def test_plane_curve_round_trip(self):
        self._round_trip('plane_curve.json')

    def test_projective_hypersurface_round_trip(self):
        self._round_trip('projective_hypersurface.json')

    def test_double_cover_P2_round_trip(self):
        self._round_trip('double_cover_P2.json')

    def test_cyclic_cover_round_trip(self):
        self._round_trip('cyclic_cover.json')


# ----------------------------------------------------------------------
# TestSaverFromSageObjects: build a case from a Sage curve
# ----------------------------------------------------------------------

class TestSaverFromSageObjects(unittest.TestCase):

    def test_save_case_with_hyperelliptic_curve(self):
        F = GF(7)
        R = PolynomialRing(F, 'x')
        x = R.gen()
        C = HyperellipticCurve(x**5 - x + 1)

        fd, path = tempfile.mkstemp(suffix='.json')
        os.close(fd)
        os.unlink(path)
        try:
            save_case(C, [1, -1, 0, -7, 49], path,
                      id='g2_d5_singleton', notes='from Sage curve')
            data = _read_json(path)
            self.assertEqual(data['schema_version'], '3')
            case = data['cases'][0]
            self.assertEqual(case['variety']['model']['kind'], 'hyperelliptic')
            self.assertEqual(case['variety']['dim'], 1)
            self.assertEqual(case['variety']['genus'], 2)
            self.assertEqual(case['results'][0]['p'], 7)
            self.assertEqual(case['results'][0]['Lpoly']['coeffs_asc'],
                             [1, -1, 0, -7, 49])
        finally:
            if os.path.exists(path):
                os.unlink(path)

    def test_save_case_with_dict_variety_and_explicit_p(self):
        F = GF(7)
        R = PolynomialRing(F, ['x', 'y', 'z'])
        x, y, z = R.gens()
        F_poly = x**3 + y**3 + z**3
        model = make_plane_curve_model(F_poly)
        variety = make_variety(model, dim=1, genus=1)

        fd, path = tempfile.mkstemp(suffix='.json')
        os.close(fd)
        os.unlink(path)
        try:
            save_case(variety, [1, -4, 7], path,
                      id='fermat_cubic', notes='dict variety', p=7)
            data = _read_json(path)
            self.assertEqual(data['cases'][0]['variety']['model']['kind'],
                             'plane_curve')
            self.assertEqual(data['cases'][0]['results'][0]['p'], 7)
        finally:
            if os.path.exists(path):
                os.unlink(path)


# ----------------------------------------------------------------------
# TestSaverUpsert: upsert-by-id and append-different-id semantics
# ----------------------------------------------------------------------

class TestSaverUpsert(unittest.TestCase):

    def test_upsert_replaces_by_id(self):
        F = GF(7)
        R = PolynomialRing(F, 'x')
        x = R.gen()
        C1 = HyperellipticCurve(x**5 - x + 1)
        C2 = HyperellipticCurve(x**5 + x**3 + 1)

        fd, path = tempfile.mkstemp(suffix='.json')
        os.close(fd)
        os.unlink(path)
        try:
            save_case(C1, [1, -1, 0, -7, 49], path, id='shared', notes='first')
            save_case(C2, [1, 1, 1, 1, 1], path, id='shared', notes='second')
            data = _read_json(path)
            self.assertEqual(len(data['cases']), 1)
            self.assertEqual(data['cases'][0]['notes'], 'second')
        finally:
            if os.path.exists(path):
                os.unlink(path)

    def test_append_keeps_distinct_ids(self):
        F = GF(7)
        R = PolynomialRing(F, 'x')
        x = R.gen()
        C1 = HyperellipticCurve(x**5 - x + 1)
        C2 = HyperellipticCurve(x**5 + x**3 + 1)

        fd, path = tempfile.mkstemp(suffix='.json')
        os.close(fd)
        os.unlink(path)
        try:
            save_case(C1, [1, -1, 0, -7, 49], path, id='id_a', notes='a')
            save_case(C2, [1, 1, 1, 1, 1], path, id='id_b', notes='b')
            data = _read_json(path)
            self.assertEqual(sorted(c['id'] for c in data['cases']),
                             ['id_a', 'id_b'])
        finally:
            if os.path.exists(path):
                os.unlink(path)

    def test_save_grouped_case_rejects_non_v3_file(self):
        # Pre-write a file that claims to be v2.
        fd, path = tempfile.mkstemp(suffix='.json')
        with os.fdopen(fd, 'w') as fh:
            json.dump({"schema_version": "2", "cases": []}, fh)
        try:
            case = {
                "id": "x",
                "variety": {
                    "coeff_domain": {"kind": "integer"},
                    "dim": 1,
                    "non_middle_factors": {
                        "kind": "projective_lefschetz",
                        "middle_factor_content": "full",
                    },
                    "model": {
                        "kind": "hyperelliptic",
                        "pretty": "...",
                        "h_coeffs_asc": [0],
                        "f_coeffs_asc": [1, 0, 0, 0, 0, 1],
                    },
                },
                "results": [{"p": 7, "Lpoly": {"coeffs_asc": [1]}}],
                "notes": "",
            }
            with self.assertRaises(ValueError):
                save_grouped_case(case, path)
        finally:
            if os.path.exists(path):
                os.unlink(path)
