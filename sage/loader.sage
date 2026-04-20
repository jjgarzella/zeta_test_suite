"""
loader.sage — Load v3 zeta-function test cases from JSON.

Provides:
    load_case(case)            -> GroupedCase named tuple
    expand_case(case)          -> list of ExpandedCase named tuples
    load_cases(path)           -> list of GroupedCase
    load_expanded_cases(path)  -> flattened list of ExpandedCase

Dispatches on `model.kind` for all six day-one kinds:
hyperelliptic, superelliptic, plane_curve, projective_hypersurface,
double_cover_P2, cyclic_cover.

Normalizes Lpoly shorthand into a full per-degree l_factors dict using
the variety's declared non_middle_factors convention. Raises
NotImplementedError for non_middle_factors.kind == 'toric_lefschetz' and
for coeff_domain.kind == 'number_field'.
"""

import json
from collections import namedtuple


SCHEMA_VERSION = "3"

LoadedVariety = namedtuple('LoadedVariety', [
    'kind',
    'dim',
    'genus',
    'coeff_domain',
    'non_middle_factors',
    'model_data',
    'polys',
    'sage_object',
])

GroupedCase = namedtuple('GroupedCase', ['id', 'variety', 'results', 'notes'])

ExpandedCase = namedtuple('ExpandedCase', [
    'id',
    'p',
    'notes',
    'variety',
    'expected_l_factors',
])


# ----------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------

def load_case(case):
    """
    Load one grouped v3 test case from a parsed JSON object.

    Returns a GroupedCase carrying the raw variety/results/notes data.
    Lpoly shorthand is left unexpanded; use expand_case for that.
    """
    return GroupedCase(
        id=case['id'],
        variety=case['variety'],
        results=case['results'],
        notes=case['notes'],
    )


def expand_case(case):
    """
    Expand one grouped v3 test case into per-prime ExpandedCase entries.

    Each ExpandedCase carries a LoadedVariety reduced over GF(p) plus a
    fully-normalized expected_l_factors dict (Sage integer coefficients).
    """
    grouped = load_case(case)
    expanded = []

    for result in grouped.results:
        p = _to_sage_int(result['p'])
        variety = _build_variety_over_prime(grouped.variety, p)
        l_factors = _result_to_l_factors(grouped.variety, result, p)
        expanded.append(ExpandedCase(
            id=grouped.id,
            p=p,
            notes=grouped.notes,
            variety=variety,
            expected_l_factors=l_factors,
        ))

    return expanded


def load_cases(path):
    """
    Load grouped v3 test cases from a JSON file at `path`.
    """
    data = _read_v3_json(path)
    return [load_case(c) for c in data['cases']]


def load_expanded_cases(path):
    """
    Load grouped v3 test cases from `path` and expand them per prime.
    """
    data = _read_v3_json(path)
    expanded = []
    for case in data['cases']:
        expanded.extend(expand_case(case))
    return expanded


# ----------------------------------------------------------------------
# JSON / scalar helpers
# ----------------------------------------------------------------------

def _read_v3_json(path):
    with open(path, 'r') as fh:
        data = json.load(fh)
    version = data.get('schema_version')
    if version != SCHEMA_VERSION:
        raise ValueError(
            f"Expected schema_version {SCHEMA_VERSION!r}, got {version!r}"
        )
    return data


def _to_sage_int(value):
    """Convert a JSON integer-like (int or integer-string) to a Sage Integer."""
    return ZZ(str(value))


def _coeffs_to_sage_int_list(coeffs):
    return [_to_sage_int(c) for c in coeffs]


# ----------------------------------------------------------------------
# Domain / convention dispatch
# ----------------------------------------------------------------------

def _require_supported_coeff_domain(variety):
    kind = variety['coeff_domain']['kind']
    if kind == 'integer':
        return
    if kind == 'number_field':
        raise NotImplementedError(
            "v3 loader does not yet support coeff_domain.kind == 'number_field'"
        )
    raise ValueError(f"Unknown coeff_domain.kind: {kind!r}")


def _require_supported_non_middle_factors(variety):
    nmf = variety['non_middle_factors']
    kind = nmf['kind']
    if kind == 'toric_lefschetz':
        raise NotImplementedError(
            "v3 loader does not yet support non_middle_factors.kind == 'toric_lefschetz'"
        )
    if kind not in ('projective_lefschetz', 'explicit'):
        raise ValueError(f"Unknown non_middle_factors.kind: {kind!r}")


# ----------------------------------------------------------------------
# Polynomial construction
# ----------------------------------------------------------------------

def _univariate_poly(coeffs_asc, R):
    x = R.gen()
    base = R.base_ring()
    return sum(base(_to_sage_int(c)) * x**i for i, c in enumerate(coeffs_asc))


def _multivariable_poly(monomials, coeffs, R):
    gens = R.gens()
    out = R.zero()
    base = R.base_ring()
    for mono, c in zip(monomials, coeffs):
        if len(mono) != len(gens):
            raise ValueError(
                f"monomial length {len(mono)} does not match number of vars {len(gens)}"
            )
        term = base(_to_sage_int(c))
        for j, e in enumerate(mono):
            term = term * gens[j]**int(e)
        out = out + term
    return out


# ----------------------------------------------------------------------
# Per-kind variety construction over GF(p)
# ----------------------------------------------------------------------

def _build_variety_over_prime(variety, p):
    _require_supported_coeff_domain(variety)
    _require_supported_non_middle_factors(variety)

    F = GF(int(p))
    model = variety['model']
    kind = model['kind']

    polys = {}
    sage_object = None

    if kind == 'hyperelliptic':
        R = PolynomialRing(F, 'x')
        polys['h'] = _univariate_poly(model['h_coeffs_asc'], R)
        polys['f'] = _univariate_poly(model['f_coeffs_asc'], R)
        sage_object = HyperellipticCurve(polys['f'], polys['h'])

    elif kind == 'superelliptic':
        R = PolynomialRing(F, 'x')
        polys['f'] = _univariate_poly(model['f_coeffs_asc'], R)
        polys['m'] = int(model['m'])

    elif kind == 'plane_curve':
        vars_ = model['vars']
        R = PolynomialRing(F, vars_)
        polys['F'] = _multivariable_poly(model['monomials'], model['coeffs'], R)
        Pn = ProjectiveSpace(F, len(vars_) - 1, names=vars_)
        sage_object = Curve(polys['F'], Pn)

    elif kind == 'projective_hypersurface':
        vars_ = model['vars']
        R = PolynomialRing(F, vars_)
        polys['F'] = _multivariable_poly(model['monomials'], model['coeffs'], R)
        Pn = ProjectiveSpace(F, len(vars_) - 1, names=vars_)
        sage_object = Pn.subscheme(polys['F'])

    elif kind == 'double_cover_P2':
        vars_ = model['branch_vars']
        R = PolynomialRing(F, vars_)
        polys['branch'] = _multivariable_poly(
            model['branch_monomials'], model['branch_coeffs'], R
        )
        polys['m'] = 2

    elif kind == 'cyclic_cover':
        vars_ = model['base_vars']
        R = PolynomialRing(F, vars_)
        polys['branch'] = _multivariable_poly(
            model['branch_monomials'], model['branch_coeffs'], R
        )
        polys['m'] = int(model['m'])

    else:
        raise ValueError(f"Unknown model.kind: {kind!r}")

    return LoadedVariety(
        kind=kind,
        dim=int(variety['dim']),
        genus=int(variety['genus']) if 'genus' in variety else None,
        coeff_domain=variety['coeff_domain'],
        non_middle_factors=variety['non_middle_factors'],
        model_data=model,
        polys=polys,
        sage_object=sage_object,
    )


# ----------------------------------------------------------------------
# Shorthand → l_factors expansion
# ----------------------------------------------------------------------

def _lefschetz_factor_at_degree(i, p):
    """
    Inherited Lefschetz contribution at cohomological degree i, returned
    as ascending integer coefficients of (1 - p^(i/2) T) for even i, or
    [1] for odd i.
    """
    if i < 0:
        raise ValueError(f"degree out of range: {i}")
    if i % 2 == 1:
        return [ZZ(1)]
    return [ZZ(1), -ZZ(p)**(i // 2)]


def _poly_mul_int_lists(a, b):
    out = [ZZ(0)] * (len(a) + len(b) - 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            out[i + j] += ZZ(ai) * ZZ(bj)
    return out


def _result_to_l_factors(variety, result, p):
    """
    Convert one result into a fully-normalized {int_degree: [Sage_int, ...]}
    l_factors dict.

    Two cases:
      - explicit form (`l_factors` key present): just parse all entries
        and verify completeness against 0..2*dim
      - shorthand form (`Lpoly` key present): expand using the declared
        non_middle_factors convention
    """
    dim = int(variety['dim'])
    nmf = variety['non_middle_factors']
    nmf_kind = nmf['kind']

    if 'l_factors' in result and 'Lpoly' in result:
        raise ValueError("Result has both 'l_factors' and 'Lpoly'; pick one")

    if 'l_factors' in result:
        out = {int(k): _coeffs_to_sage_int_list(v['coeffs_asc'])
               for k, v in result['l_factors'].items()}
        if nmf_kind == 'explicit':
            expected_keys = set(range(0, 2 * dim + 1))
            actual_keys = set(out.keys())
            missing = expected_keys - actual_keys
            extra = actual_keys - expected_keys
            if missing or extra:
                raise ValueError(
                    f"Explicit l_factors must have keys 0..{2*dim}; "
                    f"missing={sorted(missing)}, extra={sorted(extra)}"
                )
        return out

    if 'Lpoly' not in result:
        raise ValueError("Result must have either 'l_factors' or 'Lpoly'")

    if nmf_kind == 'explicit':
        raise ValueError(
            "Lpoly shorthand is forbidden when non_middle_factors.kind == 'explicit'"
        )
    if nmf_kind != 'projective_lefschetz':
        raise NotImplementedError(
            f"Shorthand expansion not implemented for non_middle_factors.kind == "
            f"{nmf_kind!r}"
        )

    middle_factor_content = nmf['middle_factor_content']
    middle_coeffs = _coeffs_to_sage_int_list(result['Lpoly']['coeffs_asc'])

    out = {}
    for i in range(0, 2 * dim + 1):
        if i == dim:
            if middle_factor_content == 'full':
                out[i] = list(middle_coeffs)
            elif middle_factor_content == 'primitive':
                lefschetz = _lefschetz_factor_at_degree(dim, p)
                out[i] = _poly_mul_int_lists(lefschetz, middle_coeffs)
            else:
                raise ValueError(
                    f"Unknown middle_factor_content: {middle_factor_content!r}"
                )
        else:
            out[i] = _lefschetz_factor_at_degree(i, p)

    return out
