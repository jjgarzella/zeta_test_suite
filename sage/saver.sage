"""
saver.sage — Save hyperelliptic curve test cases to the JSON test-suite format.

Provides:
    save_case(curve, result, filename, id, notes="")
"""

import json
import os


def _encode_field_element(c, a):
    """
    Encode a Sage field element as a JSON-compatible value.

    For a == 1: returns an int.
    For a > 1:  returns a list of ints [c0, c1, ..., c_{a-1}]
                representing c0 + c1*t + ... in F_p[t]/(m(t)).
    """
    if a == 1:
        return int(c)

    # polynomial() gives coefficients in ascending order
    coeffs = c.polynomial().list()
    # Pad to length a (in case of trailing zeros being stripped)
    coeffs += [0] * (a - len(coeffs))
    return [int(x) for x in coeffs]


def _encode_poly(poly, a):
    """
    Encode a Sage polynomial over F_q as a list of JSON field elements,
    in ascending coefficient order.
    """
    # poly.list() returns ascending coefficients; may omit trailing zeros
    return [_encode_field_element(c, a) for c in poly.list()]


def _build_case(curve, result, case_id, notes):
    """
    Convert a Sage HyperellipticCurve and L-polynomial into the JSON case dict.
    """
    F = curve.base_ring()
    p = int(F.characteristic())
    a = int(F.degree())

    # Field data
    field_data = {'p': p, 'a': a}
    if a > 1:
        # modulus polynomial over GF(p), coefficients in ascending order
        mod_coeffs = [int(c) for c in F.modulus().list()]
        field_data['modulus_coeffs_asc'] = mod_coeffs

    # Curve polynomials: HyperellipticCurve stores y^2 + h*y = f
    # hyperelliptic_polynomials() returns (f, h)
    f, h = curve.hyperelliptic_polynomials()

    # Pretty string: extract the equation from Sage's repr
    sage_str = str(curve)
    if 'defined by ' in sage_str:
        pretty = sage_str.split('defined by ')[1]
    else:
        pretty = sage_str

    model = {
        'pretty':       pretty,
        'x_var':        'x',
        'y_var':        'y',
        't_var':        't',
        'h_coeffs_asc': _encode_poly(h, a),
        'f_coeffs_asc': _encode_poly(f, a),
    }

    return {
        'id':    case_id,
        'field': field_data,
        'curve': {
            'genus': int(curve.genus()),
            'model': model,
        },
        'expected': {
            'Lpoly': {
                'coeffs_asc': list(result),
            }
        },
        'notes': notes,
    }


def save_case(curve, result, filename, id, notes=""):
    """
    Save a hyperelliptic curve test case to a JSON file.

    If the file does not exist, it is created with a single case.
    If the file exists, the case is appended or replaces an existing case
    with the same id.

    Parameters
    ----------
    curve    : HyperellipticCurve — Sage curve object
    result   : list of int       — L-polynomial coefficients in ascending order
    filename : str               — path to the JSON file (must end in .json)
    id       : str               — unique identifier for this test case
    notes    : str               — optional metadata (default "")
    """
    if not filename.endswith('.json'):
        raise ValueError(f"filename must end with '.json', got {filename!r}")

    case = _build_case(curve, result, id, notes)

    if not os.path.exists(filename):
        data = {'cases': [case]}
    else:
        with open(filename, 'r') as fh:
            data = json.load(fh)

        found = False
        for i, c in enumerate(data['cases']):
            if c['id'] == id:
                data['cases'][i] = case
                found = True
                break

        if not found:
            data['cases'].append(case)

    with open(filename, 'w') as fh:
        json.dump(data, fh, indent=2)


# ---------------------------------------------------------------------------
# Usage example
# ---------------------------------------------------------------------------
# sage: load('sage/loader.sage')
# sage: load('sage/saver.sage')
# sage: cases = load_cases("cases_v1/hyperelliptic_g2_p7_examples.json")
# sage: c = cases[0]
# sage: save_case(c.curve, c.expected_Lpoly, "/tmp/out.json", id="g2_p7_case_001", notes="round-trip test")
