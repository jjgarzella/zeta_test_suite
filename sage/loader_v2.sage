"""
loader_v2.sage — Load grouped hyperelliptic curve test cases from the v2 JSON format.

Provides:
    load_case(case)            -> grouped named tuple
    expand_case(case)          -> list of per-prime named tuples
    load_cases(path)           -> list of grouped named tuples
    load_expanded_cases(path)  -> flattened list of per-prime named tuples
"""

import json
from collections import namedtuple

GroupedHyperellCase = namedtuple('GroupedHyperellCase', ['id', 'curve', 'results', 'notes'])
ExpandedHyperellCase = namedtuple('ExpandedHyperellCase', ['id', 'p', 'curve', 'expected_Lpoly', 'notes'])


def _require_integer_coeff_domain(curve_data):
    """
    Validate that the shared curve uses the implemented integer coefficient domain.
    """
    coeff_domain = curve_data['coeff_domain']
    kind = coeff_domain['kind']
    if kind != 'integer':
        raise NotImplementedError(
            "v2 loader currently supports only coeff_domain.kind == 'integer'; "
            f"got {kind!r}"
        )


def _to_sage_int(value):
    """
    Convert a JSON integer-like value into a Sage integer.
    """
    return ZZ(str(value))


def _poly_from_integer_coeffs(coeffs, R):
    """
    Build a polynomial in R from integer-like coefficients in ascending order.
    """
    x = R.gen()
    return sum(R.base_ring()(_to_sage_int(c)) * x**i for i, c in enumerate(coeffs))


def _curve_over_prime(curve_data, p):
    """
    Reduce the shared integer curve modulo p and construct the Sage curve.
    """
    _require_integer_coeff_domain(curve_data)

    model = curve_data['model']
    p = _to_sage_int(p)
    F = GF(p)
    R = PolynomialRing(F, 'x')

    h = _poly_from_integer_coeffs(model['h_coeffs_asc'], R)
    f = _poly_from_integer_coeffs(model['f_coeffs_asc'], R)

    return HyperellipticCurve(f, h)


def load_case(case):
    """
    Load one grouped v2 test case from a parsed JSON object.

    Returns a named tuple carrying the shared curve JSON data and raw results.
    """
    return GroupedHyperellCase(
        id=case['id'],
        curve=case['curve'],
        results=case['results'],
        notes=case['notes'],
    )


def expand_case(case):
    """
    Expand one grouped v2 test case into per-prime loaded Sage cases.
    """
    grouped = load_case(case)
    expanded = []

    for result in grouped.results:
        p = _to_sage_int(result['p'])
        curve = _curve_over_prime(grouped.curve, p)
        expected_Lpoly = [_to_sage_int(c) for c in result['Lpoly']['coeffs_asc']]
        expanded.append(
            ExpandedHyperellCase(
                id=grouped.id,
                p=p,
                curve=curve,
                expected_Lpoly=expected_Lpoly,
                notes=grouped.notes,
            )
        )

    return expanded


def load_cases(path):
    """
    Load grouped v2 test cases from a JSON file.
    """
    with open(path, 'r') as f:
        data = json.load(f)

    return [load_case(case) for case in data['cases']]


def load_expanded_cases(path):
    """
    Load grouped v2 test cases and expand them into per-prime Sage cases.
    """
    with open(path, 'r') as f:
        data = json.load(f)

    expanded = []
    for case in data['cases']:
        expanded.extend(expand_case(case))
    return expanded
