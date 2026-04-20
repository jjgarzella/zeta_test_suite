"""
generate_large_prime_cases.sage — Generate 100 random hyperelliptic curve test cases
for random primes in [100, 10000], genus 1–4 (degrees 3–10).

Even-degree genus-5 curves (d=12) are excluded because frobenius_polynomial()
takes ~16s each at primes near 10000.

Run from repo root:
    sage scripts/generate_large_prime_cases.sage
"""

import sys

load('random_generation/random_curves.sage')
load('sage/saver.sage')


def lpoly_coeffs(C):
    """Return L-polynomial coefficients in ascending order as a list of ints."""
    poly = C.frobenius_polynomial()
    # poly.list() is descending (leading coeff first); reverse for ascending order
    return [int(c) for c in reversed(poly.list())]


FILENAME = "cases/random_p100_to_10000.json"
N = 100
DEGREES = list(range(3, 11))  # d = 3..10, genus 1..4

done = 0
errors = 0

while done < N:
    p = random_prime(10000, lbound=100)
    d = DEGREES[ZZ.random_element(len(DEGREES))]
    g = (d - 1) // 2
    i = done + 1
    case_id = "largep_p{}_d{}_{:03d}".format(p, d, i)
    try:
        C = random_hyperelliptic(p, d)
        coeffs = lpoly_coeffs(C)
        notes = "Random genus-{} curve over GF({}), deg(f)={}".format(g, p, d)
        save_case(C, coeffs, FILENAME, case_id, notes=notes)
        done += 1
        print("[large-p] {}/{}: {}".format(done, N, case_id))
        sys.stdout.flush()
    except Exception as e:
        errors += 1
        print("[large-p] ERROR on {}: {}".format(case_id, e), file=sys.stderr)
        sys.stderr.flush()

print("[large-p] Done. {}/{} cases written to {} ({} errors)".format(done, N, FILENAME, errors))
