"""
saver_v2.sage — Save grouped hyperelliptic curve test cases to the v2 JSON format.

Provides:
    save_case(curve, result, filename, id, notes="")
    save_grouped_case(case, filename)
"""

import json
import os

INT64_JSON_BOUND = 2**63


def _nonnegative_int(n, p):
    """
    Convert an element of GF(p) to its canonical integer representative in [0, p-1].
    """
    return int(n) % p


def _json_integer_like(n):
    """
    Encode an integer as a JSON int when its magnitude is below 2^63, else as a string.
    """
    value = ZZ(n)
    if abs(value) < INT64_JSON_BOUND:
        return int(value)
    return str(value)


def _normalize_json_like(value):
    """
    Recursively normalize Sage integers in JSON-like data structures.
    """
    if isinstance(value, dict):
        return {key: _normalize_json_like(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_normalize_json_like(item) for item in value]
    try:
        return _json_integer_like(value)
    except Exception:
        return value


def _encode_integer_poly(poly, p):
    """
    Encode a polynomial over GF(p) as ascending integer-like JSON values.
    """
    return [_json_integer_like(_nonnegative_int(c, p)) for c in poly.list()]


def _pretty_from_curve(curve):
    """
    Extract a human-readable defining equation from Sage's curve repr.
    """
    sage_str = str(curve)
    if 'defined by ' in sage_str:
        return sage_str.split('defined by ')[1]
    return sage_str


def _build_grouped_case(curve, result, case_id, notes):
    """
    Convert a Sage HyperellipticCurve over GF(p) into one grouped v2 case.
    """
    F = curve.base_ring()
    p = int(F.characteristic())
    a = int(F.degree())
    if a != 1:
        raise NotImplementedError(
            "v2 saver currently supports only prime-field curves; "
            f"got extension degree a={a}"
        )

    f, h = curve.hyperelliptic_polynomials()
    model = {
        'pretty': _pretty_from_curve(curve),
        'x_var': 'x',
        'y_var': 'y',
        't_var': 't',
        'h_coeffs_asc': _encode_integer_poly(h, p),
        'f_coeffs_asc': _encode_integer_poly(f, p),
    }

    return {
        'id': case_id,
        'curve': {
            'coeff_domain': {
                'kind': 'integer',
            },
            'genus': int(curve.genus()),
            'model': model,
        },
        'results': [
            {
                'p': _json_integer_like(p),
                'Lpoly': {
                    'coeffs_asc': [_json_integer_like(c) for c in result],
                },
            }
        ],
        'notes': notes,
    }


def save_grouped_case(case, filename):
    """
    Upsert one grouped v2 case into a JSON file by case id.
    """
    if not filename.endswith('.json'):
        raise ValueError(f"filename must end with '.json', got {filename!r}")

    case = _normalize_json_like(case)

    if not os.path.exists(filename):
        data = {'cases': [case]}
    else:
        with open(filename, 'r') as fh:
            data = json.load(fh)

        found = False
        for i, existing in enumerate(data['cases']):
            if existing['id'] == case['id']:
                data['cases'][i] = case
                found = True
                break

        if not found:
            data['cases'].append(case)

    with open(filename, 'w') as fh:
        json.dump(data, fh, indent=2)


def save_case(curve, result, filename, id, notes=""):
    """
    Save one Sage curve/result pair as a grouped v2 case with a singleton results array.
    """
    case = _build_grouped_case(curve, result, id, notes)
    save_grouped_case(case, filename)
