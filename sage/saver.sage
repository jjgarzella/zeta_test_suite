"""
saver.sage — Save v3 zeta-function test cases to JSON.

Provides:
    save_case(variety, result, filename, id, notes="",
              *, p=None, non_middle_factors=None)
    save_grouped_case(case, filename)

    # Per-kind model dict builders (use when constructing variety dicts):
    make_hyperelliptic_model(curve)
    make_superelliptic_model(m, f_poly, pretty=None)
    make_plane_curve_model(F, pretty=None)
    make_projective_hypersurface_model(F, pretty=None)
    make_double_cover_P2_model(branch_poly, pretty=None)
    make_cyclic_cover_model(m, branch_poly, pretty=None)

    # Wrappers:
    make_variety(model, dim, *, coeff_domain=..., non_middle_factors=..., genus=None)
    encode_lpoly(coeffs)
    encode_l_factors(factors_dict)
    encode_result(p, result)

`save_grouped_case` upserts the case by id (matching v2 saver semantics).
The output file always carries `schema_version: "3"` at the top level.
"""

import json
import os


SCHEMA_VERSION = "3"
INT64_JSON_BOUND = 2**63

DEFAULT_NON_MIDDLE_FACTORS = {
    "kind": "projective_lefschetz",
    "middle_factor_content": "full",
}


# ----------------------------------------------------------------------
# Scalar / poly encoding
# ----------------------------------------------------------------------

def _nonnegative_int(n, p):
    """Canonical [0, p-1] representative of an element of GF(p)."""
    return int(n) % int(p)


def _json_integer_like(n):
    """JSON int when |n| < 2^63, otherwise integer-valued string."""
    value = ZZ(n)
    if abs(value) < INT64_JSON_BOUND:
        return int(value)
    return str(value)


def _normalize_json_like(value):
    """Recursively coerce Sage scalars in a JSON-like dict/list to ints/strings."""
    if isinstance(value, dict):
        return {key: _normalize_json_like(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_normalize_json_like(item) for item in value]
    if isinstance(value, str):
        return value
    if isinstance(value, bool):
        return value
    try:
        return _json_integer_like(value)
    except Exception:
        return value


def _encode_univariate_poly(poly, p=None):
    """
    Encode a univariate polynomial as ascending integer-like JSON values.

    If `p` is provided, coefficients are reduced into [0, p-1] first.
    """
    if p is not None:
        return [_json_integer_like(_nonnegative_int(c, p)) for c in poly.list()]
    return [_json_integer_like(ZZ(c)) for c in poly.list()]


def _encode_multivariable_poly(poly, p=None):
    """
    Encode a multivariate polynomial as parallel monomials/coeffs arrays.

    Returns (monomials, coeffs) — each entry of monomials is a list of
    nonneg ints of length equal to the parent ring's number of generators;
    coeffs are integer-like JSON values.
    """
    monomials = []
    coeffs = []
    for mono, c in zip(poly.monomials(), poly.coefficients()):
        if c == 0:
            continue
        exps = [int(e) for e in mono.exponents()[0]]
        monomials.append(exps)
        if p is not None:
            coeffs.append(_json_integer_like(_nonnegative_int(c, p)))
        else:
            coeffs.append(_json_integer_like(ZZ(c)))
    return monomials, coeffs


def _vars_of_ring(R):
    return [str(g) for g in R.gens()]


def _ring_characteristic(R):
    p = R.base_ring().characteristic()
    return int(p) if p != 0 else None


# ----------------------------------------------------------------------
# Pretty-print helpers
# ----------------------------------------------------------------------

def _pretty_from_curve(curve):
    sage_str = str(curve)
    if 'defined by ' in sage_str:
        return sage_str.split('defined by ')[1]
    return sage_str


# ----------------------------------------------------------------------
# Per-kind model dict builders
# ----------------------------------------------------------------------

def make_hyperelliptic_model(curve):
    """
    Build a v3 model dict for a Sage HyperellipticCurve.
    """
    f, h = curve.hyperelliptic_polynomials()
    p = _ring_characteristic(f.parent())
    return {
        "kind": "hyperelliptic",
        "pretty": _pretty_from_curve(curve),
        "h_coeffs_asc": _encode_univariate_poly(h, p),
        "f_coeffs_asc": _encode_univariate_poly(f, p),
    }


def make_superelliptic_model(m, f_poly, pretty=None):
    """
    Build a v3 model dict for the superelliptic curve y^m = f(x).
    """
    p = _ring_characteristic(f_poly.parent())
    return {
        "kind": "superelliptic",
        "pretty": pretty if pretty is not None else f"y^{int(m)} = {f_poly}",
        "m": int(m),
        "f_coeffs_asc": _encode_univariate_poly(f_poly, p),
    }


def make_plane_curve_model(F, pretty=None):
    """
    Build a v3 model dict for a plane curve F(x,y,z) = 0 in P^2.

    F must be a homogeneous polynomial in a polynomial ring on exactly
    three generators.
    """
    R = F.parent()
    vars_ = _vars_of_ring(R)
    if len(vars_) != 3:
        raise ValueError(
            f"plane_curve requires exactly 3 variables, got {vars_}"
        )
    p = _ring_characteristic(R)
    monomials, coeffs = _encode_multivariable_poly(F, p)
    return {
        "kind": "plane_curve",
        "pretty": pretty if pretty is not None else f"{F} = 0",
        "vars": vars_,
        "monomials": monomials,
        "coeffs": coeffs,
    }


def make_projective_hypersurface_model(F, pretty=None):
    """
    Build a v3 model dict for a projective hypersurface F(x_0,...,x_n) = 0.
    """
    R = F.parent()
    vars_ = _vars_of_ring(R)
    if len(vars_) < 2:
        raise ValueError(
            f"projective_hypersurface requires >= 2 variables, got {vars_}"
        )
    p = _ring_characteristic(R)
    monomials, coeffs = _encode_multivariable_poly(F, p)
    return {
        "kind": "projective_hypersurface",
        "pretty": pretty if pretty is not None else f"{F} = 0",
        "vars": vars_,
        "monomials": monomials,
        "coeffs": coeffs,
    }


def make_double_cover_P2_model(branch_poly, pretty=None):
    """
    Build a v3 model dict for a double cover of P^2 branched along
    branch_poly(x_0,x_1,x_2) = 0.
    """
    R = branch_poly.parent()
    vars_ = _vars_of_ring(R)
    if len(vars_) != 3:
        raise ValueError(
            f"double_cover_P2 requires a 3-variable branch poly, got {vars_}"
        )
    p = _ring_characteristic(R)
    monomials, coeffs = _encode_multivariable_poly(branch_poly, p)
    return {
        "kind": "double_cover_P2",
        "pretty": pretty if pretty is not None else f"y^2 = {branch_poly}",
        "branch_vars": vars_,
        "branch_monomials": monomials,
        "branch_coeffs": coeffs,
    }


def make_cyclic_cover_model(m, branch_poly, pretty=None):
    """
    Build a v3 model dict for an m-fold cyclic cover w^m = branch_poly.
    """
    R = branch_poly.parent()
    vars_ = _vars_of_ring(R)
    p = _ring_characteristic(R)
    monomials, coeffs = _encode_multivariable_poly(branch_poly, p)
    return {
        "kind": "cyclic_cover",
        "pretty": pretty if pretty is not None else f"w^{int(m)} = {branch_poly}",
        "m": int(m),
        "base_vars": vars_,
        "branch_monomials": monomials,
        "branch_coeffs": coeffs,
    }


# ----------------------------------------------------------------------
# Variety / result wrappers
# ----------------------------------------------------------------------

def make_variety(model, dim, *,
                 coeff_domain=None,
                 non_middle_factors=None,
                 genus=None):
    """Wrap a model dict into a v3 variety dict."""
    variety = {
        "coeff_domain": coeff_domain or {"kind": "integer"},
        "dim": int(dim),
        "non_middle_factors": non_middle_factors or dict(DEFAULT_NON_MIDDLE_FACTORS),
        "model": model,
    }
    if genus is not None:
        variety["genus"] = int(genus)
    return variety


def encode_lpoly(coeffs):
    """Build a v3 Lpoly dict from an iterable of integer-like coefficients."""
    return {"coeffs_asc": [_json_integer_like(c) for c in coeffs]}


def encode_l_factors(factors):
    """
    Build a v3 l_factors dict from {int_or_str_degree: iterable_of_coeffs}.
    """
    return {
        str(k): {"coeffs_asc": [_json_integer_like(c) for c in v]}
        for k, v in factors.items()
    }


def encode_result(p, result):
    """
    Encode one prime result. `result` is one of:
      - iterable of integer-like values        -> Lpoly shorthand
      - dict {int_or_str_degree: iterable}     -> l_factors explicit

    The variety should agree with the chosen form (the loader enforces
    this on read; the saver does not double-check).
    """
    out = {"p": _json_integer_like(p)}
    if isinstance(result, dict):
        out["l_factors"] = encode_l_factors(result)
    else:
        out["Lpoly"] = encode_lpoly(result)
    return out


# ----------------------------------------------------------------------
# Public save_case / save_grouped_case
# ----------------------------------------------------------------------

def _detect_hyperelliptic_curve(obj):
    """Return True if obj quacks like a Sage HyperellipticCurve."""
    return hasattr(obj, 'hyperelliptic_polynomials') and hasattr(obj, 'genus')


def save_case(variety, result, filename, id, notes="", *,
              p=None, non_middle_factors=None):
    """
    Save one (variety, result) pair as a grouped v3 case (upsert by id).

    `variety` may be:
      - a Sage HyperellipticCurve over GF(p) — auto-built into a
        kind:"hyperelliptic" variety dict; p is taken from the curve's
        base ring, so the keyword `p` can be omitted
      - a v3 variety dict (used as-is; the keyword `p` is required)

    `result` may be:
      - an iterable of integer-like values (Lpoly shorthand)
      - a dict {degree: iterable} (explicit l_factors)

    `non_middle_factors` overrides the default convention when
    `variety` is a Sage curve (default: projective_lefschetz/full).
    """
    if isinstance(variety, dict):
        if p is None:
            raise ValueError(
                "save_case: keyword `p` is required when `variety` is a dict"
            )
        variety_dict = variety
        result_p = p
    elif _detect_hyperelliptic_curve(variety):
        model = make_hyperelliptic_model(variety)
        variety_dict = make_variety(
            model,
            dim=1,
            non_middle_factors=non_middle_factors or dict(DEFAULT_NON_MIDDLE_FACTORS),
            genus=int(variety.genus()),
        )
        result_p = p if p is not None else int(variety.base_ring().characteristic())
    else:
        raise TypeError(
            f"save_case: cannot interpret variety of type {type(variety).__name__}; "
            "pass a Sage HyperellipticCurve or a v3 variety dict"
        )

    case = {
        "id": id,
        "variety": variety_dict,
        "results": [encode_result(result_p, result)],
        "notes": notes,
    }
    save_grouped_case(case, filename)


def save_grouped_case(case, filename):
    """
    Upsert one grouped v3 case into a JSON file by case id.

    Creates the file with `schema_version: "3"` if it does not exist.
    """
    if not filename.endswith('.json'):
        raise ValueError(f"filename must end with '.json', got {filename!r}")

    case = _normalize_json_like(case)

    if not os.path.exists(filename):
        data = {"schema_version": SCHEMA_VERSION, "cases": [case]}
    else:
        with open(filename, 'r') as fh:
            data = json.load(fh)

        if data.get('schema_version') != SCHEMA_VERSION:
            raise ValueError(
                f"{filename}: existing schema_version "
                f"{data.get('schema_version')!r} != {SCHEMA_VERSION!r}"
            )

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


