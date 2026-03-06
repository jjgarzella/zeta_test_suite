"""
random_curves.sage — Generate random hyperelliptic curves over F_p (odd p).

Curves are in the form y^2 = f(x) (i.e. h = 0), where f is monic, depressed
(x^(d-1) coefficient is zero), and squarefree.

Provides:
    random_hyperelliptic_odd_degree(p, g)   -> HyperellipticCurve, degree 2g+1
    random_hyperelliptic_even_degree(p, g)  -> HyperellipticCurve, degree 2g+2
    random_hyperelliptic(p, d)              -> HyperellipticCurve, degree d
"""


def _random_monic_depressed_squarefree(R, d):
    """
    Return a random monic depressed squarefree polynomial of degree d in R = F_p[x].

    'Monic'     : leading coefficient is 1.
    'Depressed' : coefficient of x^(d-1) is 0.

    Retries until squarefree; expected attempts ~ p/(p-1).
    """
    F = R.base_ring()
    x = R.gen()
    while True:
        # Build coefficient list in ascending order: [c_0, c_1, ..., c_{d-2}, 0, 1]
        coeffs = [F.random_element() for _ in range(d - 1)] + [F(0), F(1)]
        f = R(coeffs)
        if f.is_squarefree():
            return f


def random_hyperelliptic_odd_degree(p, g):
    """
    Generate a random genus-g hyperelliptic curve y^2 = f(x) over F_p,
    where f has odd degree d = 2g+1.

    f is monic, depressed, and squarefree.

    Parameters
    ----------
    p : prime (must be odd)
    g : genus (integer >= 1)

    Returns
    -------
    HyperellipticCurve over GF(p)
    """
    F = GF(p)
    R = PolynomialRing(F, 'x')
    d = 2 * g + 1
    f = _random_monic_depressed_squarefree(R, d)
    return HyperellipticCurve(f)


def random_hyperelliptic_even_degree(p, g):
    """
    Generate a random genus-g hyperelliptic curve y^2 = f(x) over F_p,
    where f has even degree d = 2g+2.

    f is monic, depressed, and squarefree.

    Note: with monic f of even degree, there are two points at infinity
    defined over F_p.

    Parameters
    ----------
    p : prime (must be odd)
    g : genus (integer >= 1)

    Returns
    -------
    HyperellipticCurve over GF(p)
    """
    F = GF(p)
    R = PolynomialRing(F, 'x')
    d = 2 * g + 2
    f = _random_monic_depressed_squarefree(R, d)
    return HyperellipticCurve(f)


def random_hyperelliptic(p, d):
    """
    Generate a random hyperelliptic curve y^2 = f(x) over F_p,
    where f has the given degree d.

    The genus is g = floor((d-1) / 2).

    Parameters
    ----------
    p : prime (must be odd)
    d : degree of f (integer >= 3)

    Returns
    -------
    HyperellipticCurve over GF(p)

    Raises
    ------
    ValueError if p is even or d < 3
    """
    if p == 2:
        raise ValueError("p must be odd; characteristic 2 requires a different model")
    if d < 3:
        raise ValueError(f"degree d must be >= 3 for a hyperelliptic curve, got {d}")

    g = (d - 1) // 2

    if d % 2 == 1:
        return random_hyperelliptic_odd_degree(p, g)
    else:
        return random_hyperelliptic_even_degree(p, g)


# ---------------------------------------------------------------------------
# Usage example
# ---------------------------------------------------------------------------
# sage: load('random_generation/random_curves.sage')
# sage: C = random_hyperelliptic(7, 5)   # genus 2, degree 5
# sage: C
# Hyperelliptic Curve over Finite Field of size 7 defined by y^2 = x^5 + ...
# sage: C.genus()
# 2
