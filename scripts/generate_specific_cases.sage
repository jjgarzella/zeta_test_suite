"""
generate_specific_cases.sage — Compute L-polynomials at all primes ≤ 10000 for
specific hyperelliptic curves, two per (degree, genus) pair.

Degrees 3–10 cover genus 1–4. Even-degree genus-5 (d=12) is excluded due to
prohibitive computation time at large primes.

One output JSON file per curve.

Run from repo root:
    sage scripts/generate_specific_cases.sage
"""

import sys

load('sage/saver_v2.sage')


def lpoly_coeffs(C):
    """Return L-polynomial coefficients in ascending order as a list of ints."""
    poly = C.frobenius_polynomial()
    # poly.list() is descending (leading coeff first); reverse for ascending order
    return [int(c) for c in reversed(poly.list())]


# ---------------------------------------------------------------------------
# Specific curves: (genus, degree, label, pretty, f_coeffs_asc)
# All curves are y^2 = f(x) (h = 0), defined over Z, reduced mod p.
# Ascending coefficients: [c0, c1, ..., cd] means c0 + c1*x + ... + cd*x^d.
# ---------------------------------------------------------------------------
CURVES = [
    # genus 1, degree 3
    (1, 3, 'a', 'y^2 = x^3 - x + 1',     [1, -1,  0,  1]),
    (1, 3, 'b', 'y^2 = x^3 + x + 1',     [1,  1,  0,  1]),
    # genus 1, degree 4
    (1, 4, 'a', 'y^2 = x^4 - x + 1',     [1, -1,  0,  0,  1]),
    (1, 4, 'b', 'y^2 = x^4 + x^3 + 1',   [1,  0,  0,  1,  1]),
    # genus 2, degree 5
    (2, 5, 'a', 'y^2 = x^5 - x + 1',     [1, -1,  0,  0,  0,  1]),
    (2, 5, 'b', 'y^2 = x^5 + x^2 + 1',   [1,  0,  1,  0,  0,  1]),
    # genus 2, degree 6
    (2, 6, 'a', 'y^2 = x^6 - x + 1',     [1, -1,  0,  0,  0,  0,  1]),
    (2, 6, 'b', 'y^2 = x^6 + x^3 + 1',   [1,  0,  0,  1,  0,  0,  1]),
    # genus 3, degree 7
    (3, 7, 'a', 'y^2 = x^7 - x + 1',     [1, -1,  0,  0,  0,  0,  0,  1]),
    (3, 7, 'b', 'y^2 = x^7 + x^2 + 1',   [1,  0,  1,  0,  0,  0,  0,  1]),
    # genus 3, degree 8
    (3, 8, 'a', 'y^2 = x^8 - x + 1',     [1, -1,  0,  0,  0,  0,  0,  0,  1]),
    (3, 8, 'b', 'y^2 = x^8 + x^3 + 1',   [1,  0,  0,  1,  0,  0,  0,  0,  1]),
    # genus 4, degree 9
    (4, 9, 'a', 'y^2 = x^9 - x + 1',     [1, -1,  0,  0,  0,  0,  0,  0,  0,  1]),
    (4, 9, 'b', 'y^2 = x^9 + x^2 + 1',   [1,  0,  1,  0,  0,  0,  0,  0,  0,  1]),
    # genus 4, degree 10
    (4, 10, 'a', 'y^2 = x^10 - x + 1',   [1, -1,  0,  0,  0,  0,  0,  0,  0,  0,  1]),
    (4, 10, 'b', 'y^2 = x^10 + x^3 + 1', [1,  0,  0,  1,  0,  0,  0,  0,  0,  0,  1]),
]

ODD_PRIMES  = prime_range(3, 10001)  # odd-degree curves: all primes up to 10000
EVEN_PRIMES = prime_range(3, 5001)   # even-degree curves: capped at 5000 (slow above that)


def process_curve(g, d, label, pretty, f_coeffs_asc):
    filename = "cases_v2/specific_g{}_d{}_{}.json".format(g, d, label)
    case_id = "g{}_d{}_{}".format(g, d, label)
    all_primes = ODD_PRIMES if d % 2 == 1 else EVEN_PRIMES

    # Verify squarefreeness over Z once up front
    Zx = PolynomialRing(ZZ, 'x')
    f_over_Z = Zx(f_coeffs_asc)
    if not f_over_Z.is_squarefree():
        print("WARNING: {} is not squarefree over Z — skipping".format(pretty), file=sys.stderr)
        return

    total = len(all_primes)
    done = 0
    skipped = 0
    results = []

    print("[g{} d{} {}] {} primes for {}".format(g, d, label, total, pretty))
    sys.stdout.flush()

    for p in all_primes:
        try:
            F = GF(p)
            R = PolynomialRing(F, 'x')
            f = R(f_coeffs_asc)

            # Skip bad primes where f becomes singular
            if not f.is_squarefree():
                skipped += 1
                continue

            C = HyperellipticCurve(f)

            # Genus can degenerate at bad primes; skip those
            if C.genus() != g:
                skipped += 1
                continue

            coeffs = lpoly_coeffs(C)
            results.append({
                'p': int(p),
                'Lpoly': {
                    'coeffs_asc': coeffs,
                },
            })
            done += 1

        except Exception:
            skipped += 1

    grouped_case = {
        'id': case_id,
        'curve': {
            'coeff_domain': {
                'kind': 'integer',
            },
            'genus': g,
            'model': {
                'pretty': pretty,
                'x_var': 'x',
                'y_var': 'y',
                't_var': 't',
                'h_coeffs_asc': [0],
                'f_coeffs_asc': f_coeffs_asc,
            },
        },
        'results': results,
        'notes': "{} over Z, reduced at valid primes".format(pretty),
    }
    save_grouped_case(grouped_case, filename)

    print("[g{} d{} {}] Done. {}/{} primes saved, {} skipped. -> {}".format(
        g, d, label, done, total, skipped, filename))
    sys.stdout.flush()


for curve_spec in CURVES:
    process_curve(*curve_spec)
