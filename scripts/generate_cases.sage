"""
generate_cases.sage — Generate random hyperelliptic curve test cases.

Generates 10 random curves per (p, degree) pair for genus 1–5 (degrees 3–12),
split across four files by characteristic range.

Run from repo root:
    sage scripts/generate_cases.sage
"""

import sys

load('random_generation/random_curves.sage')
load('sage/saver.sage')


def lpoly_coeffs(C):
    """Return L-polynomial coefficients in ascending order as a list of ints."""
    poly = C.frobenius_polynomial()
    # poly.list() is descending (leading coeff first); reverse for ascending order
    return [int(c) for c in reversed(poly.list())]


def generate_cases(primes, degrees, n_per, filename, label):
    """
    Generate n_per random curves for each (p, d) pair and save to filename.

    primes  : list of prime integers
    degrees : list of degrees (3..12 for genus 1..5)
    n_per   : number of curves per (p, d) pair
    filename: output JSON path
    label   : short string for progress messages
    """
    total = len(primes) * len(degrees) * n_per
    done = 0
    errors = 0

    for p in primes:
        for d in degrees:
            g = (d - 1) // 2
            for i in range(1, n_per + 1):
                case_id = "p{}_d{}_{:03d}".format(p, d, i)
                try:
                    C = random_hyperelliptic(p, d)
                    coeffs = lpoly_coeffs(C)
                    notes = "Random genus-{} curve over GF({}), deg(f)={}".format(g, p, d)
                    save_case(C, coeffs, filename, case_id, notes=notes)
                    done += 1
                    print("[{}] {}/{}: {}".format(label, done, total, case_id))
                    sys.stdout.flush()
                except Exception as e:
                    errors += 1
                    print("[{}] ERROR on {}: {}".format(label, case_id, e), file=sys.stderr)
                    sys.stderr.flush()

    print("[{}] Done. {}/{} cases written to {} ({} errors)".format(
        label, done, total, filename, errors))


# Degrees 3–12 give genus 1–5: genus = floor((d-1)/2)
DEGREES = list(range(3, 13))
N = 10  # curves per (p, d) pair

# ── File 1: p = 2 ─────────────────────────────────────────────────────────────
generate_cases(
    primes=[2],
    degrees=DEGREES,
    n_per=N,
    filename="cases/hyperelliptic/random_p2.json",
    label="p2",
)

# ── File 2: 3 ≤ p ≤ 13 ────────────────────────────────────────────────────────
generate_cases(
    primes=prime_range(3, 14),   # [3, 5, 7, 11, 13]
    degrees=DEGREES,
    n_per=N,
    filename="cases/hyperelliptic/random_p3_to_13.json",
    label="p3-13",
)

# ── File 3: 17 ≤ p ≤ 50 ───────────────────────────────────────────────────────
generate_cases(
    primes=prime_range(17, 51),  # [17, 19, 23, 29, 31, 37, 41, 43, 47]
    degrees=DEGREES,
    n_per=N,
    filename="cases/hyperelliptic/random_p17_to_50.json",
    label="p17-50",
)

# ── File 4: 53 ≤ p ≤ 97 ───────────────────────────────────────────────────────
generate_cases(
    primes=prime_range(53, 98),  # [53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
    degrees=DEGREES,
    n_per=N,
    filename="cases/hyperelliptic/random_p53_to_97.json",
    label="p53-97",
)
