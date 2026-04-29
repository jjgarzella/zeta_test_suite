"""
generate_p41_odd_degree.sage — Generate 2 random genus-g hyperelliptic curve
test cases for each genus g = 1..30, with odd-degree f (deg = 2g+1) over GF(41).

Stops early if a single frobenius_polynomial() call exceeds TIME_LIMIT seconds,
since computation time grows steeply with genus.

Run from repo root:
    sage scripts/generate_p41_odd_degree.sage
"""

import sys
import time

load('random_generation/random_curves.sage')
load('sage/saver.sage')


def lpoly_coeffs(C):
    """Return L-polynomial coefficients in ascending order as a list of ints."""
    poly = C.frobenius_polynomial()
    # poly.list() is descending (leading coeff first); reverse for ascending order
    return [int(c) for c in reversed(poly.list())]


P = 41
N_PER_GENUS = 2
MAX_GENUS = 30
TIME_LIMIT = 60  # seconds; stop after first case that exceeds this
FILENAME = "cases/hyperelliptic/hyperelliptic_p41_odd_degree.json"

print("Generating odd-degree (2g+1) curves over GF({}) for g=1..{}".format(P, MAX_GENUS))
print("Output: {}".format(FILENAME))
print("Time limit per case: {}s".format(TIME_LIMIT))
print()

for g in range(1, MAX_GENUS + 1):
    d = 2 * g + 1
    stop = False

    for i in range(1, N_PER_GENUS + 1):
        case_id = "p41_g{}_d{}_{:03d}".format(g, d, i)
        try:
            C = random_hyperelliptic_odd_degree(P, g)
            t0 = time.time()
            coeffs = lpoly_coeffs(C)
            elapsed = time.time() - t0
            notes = "Random genus-{} curve over GF({}), deg(f)={}, computed via frobenius_polynomial()".format(g, P, d)
            save_case(C, coeffs, FILENAME, case_id, notes=notes)
            print("[p41-odd] g={:2d}, case {}/{}: {} ({:.2f}s)".format(
                g, i, N_PER_GENUS, case_id, elapsed))
            sys.stdout.flush()
            if elapsed > TIME_LIMIT:
                print("[p41-odd] Exceeded time limit ({:.2f}s > {}s). Stopping at genus {}.".format(
                    elapsed, TIME_LIMIT, g))
                stop = True
                break
        except Exception as e:
            print("[p41-odd] ERROR on {}: {}".format(case_id, e), file=sys.stderr)
            sys.stderr.flush()

    if stop:
        break

print()
print("[p41-odd] Done. Output written to {}".format(FILENAME))
