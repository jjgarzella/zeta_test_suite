"""
loader.sage — Load hyperelliptic curve test cases from the JSON test-suite format.

Provides:
    load_case(case)   -> named tuple (curve, expected_Lpoly)
    load_cases(path)  -> list of the above
"""

import json
from collections import namedtuple

HyperellCase = namedtuple('HyperellCase', ['curve', 'expected_Lpoly'])


def make_field(field_data):
    """
    Construct the finite field F_q from the JSON field descriptor.

    For a == 1: returns GF(p).
    For a > 1:  returns GF(p^a) defined by the irreducible polynomial
                given in modulus_coeffs_asc (ascending order).
    """
    p = field_data['p']
    a = field_data['a']

    if a == 1:
        return GF(p)

    # Extension field: need a modulus polynomial
    if 'modulus_coeffs_asc' not in field_data:
        raise ValueError("a > 1 but modulus_coeffs_asc is missing")

    Fp = GF(p)
    Pt = PolynomialRing(Fp, 't')
    t = Pt.gen()

    modulus_coeffs = field_data['modulus_coeffs_asc']
    modulus = Pt(modulus_coeffs)  # ascending order matches Sage's convention

    return GF(p**a, name='t', modulus=modulus)


def decode_field_element(c, F, a):
    """
    Convert a JSON coefficient into a field element of F.

    For a == 1: c is an integer; return F(c).
    For a > 1:  c is a list [c0, c1, ..., c_{a-1}]; return c0 + c1*t + ...
                where t is the generator of F.
    """
    if a == 1:
        return F(c)

    # c must be a list of integers representing c0 + c1*t + ... in F = GF(p^a)
    if not isinstance(c, list):
        raise ValueError(f"Expected list for extension field coefficient, got {c!r}")

    t = F.gen()
    # Sum c_i * t^i for i in range(len(c)); trailing zeros are fine
    return sum(F(ci) * t**i for i, ci in enumerate(c))


def poly_from_coeffs(coeffs, R, F, a):
    """
    Build a polynomial in R from a list of JSON coefficients in ascending order.

    R is the polynomial ring over F; coefficients are decoded via decode_field_element.
    """
    x = R.gen()
    return sum(decode_field_element(c, F, a) * x**i for i, c in enumerate(coeffs))


def load_case(case):
    """
    Load one hyperelliptic curve test case from a parsed JSON object.

    Parameters
    ----------
    case : dict
        One entry from the 'cases' array in the test-suite JSON.

    Returns
    -------
    HyperellCase
        A named tuple with fields:
            curve          -- Sage HyperellipticCurve object over F_q
            expected_Lpoly -- list of integers (L-polynomial coefficients, ascending)
    """
    field_data = case['field']
    model = case['curve']['model']

    p = field_data['p']
    a = field_data['a']

    # 1. Construct the finite field
    F = make_field(field_data)

    # 2. Construct the polynomial ring in x over F
    R = PolynomialRing(F, 'x')

    # 3 & 4. Decode coefficients and build h(x), f(x)
    # Coefficients are in ascending order: [c0, c1, ...] -> c0 + c1*x + ...
    h = poly_from_coeffs(model['h_coeffs_asc'], R, F, a)
    f = poly_from_coeffs(model['f_coeffs_asc'], R, F, a)

    # 5. Construct the hyperelliptic curve y^2 + h(x)*y = f(x)
    C = HyperellipticCurve(f, h)

    # 6. Extract the expected L-polynomial coefficients (unchanged)
    expected_Lpoly = case['expected']['Lpoly']['coeffs_asc']

    return HyperellCase(curve=C, expected_Lpoly=expected_Lpoly)


def load_cases(path):
    """
    Load all hyperelliptic curve test cases from a JSON file.

    Parameters
    ----------
    path : str
        Path to the JSON file containing a 'cases' array.

    Returns
    -------
    list of HyperellCase
    """
    with open(path, 'r') as f:
        data = json.load(f)

    return [load_case(case) for case in data['cases']]


# TODO: incorporate the id field into load_case and load_cases return values
def load_case_by_id(path, case_id):
    """
    Load a single hyperelliptic curve test case by its id field.

    Parameters
    ----------
    path : str
        Path to the JSON file containing a 'cases' array.
    case_id : str
        The id of the case to load.

    Returns
    -------
    HyperellCase
    """
    with open(path, 'r') as f:
        data = json.load(f)

    for case in data['cases']:
        if case['id'] == case_id:
            return load_case(case)

    raise ValueError(f"No case with id {case_id!r} found in {path}")


# ---------------------------------------------------------------------------
# Usage example
# ---------------------------------------------------------------------------
# sage: load = load_cases("../cases_v1/hyperelliptic_g2_p7_examples.json")
# sage: c = load[0]
# sage: c.curve
# Hyperelliptic Curve over Finite Field of size 7 defined by y^2 = x^5 + x^2 + 1
# sage: c.expected_Lpoly
# [1, 3, 10, 21, 49]
