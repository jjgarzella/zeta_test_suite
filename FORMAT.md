# Hyperelliptic Zeta Test Case Format Guide

This document explains how **humans and AI systems should generate valid
hyperelliptic curve test cases** for the zeta-function test suite.

The format is **JSON** and follows the schema defined in the repository.

The goal is to produce **machine-readable test cases** that can be used
to verify implementations of algorithms computing zeta functions of
hyperelliptic curves.

------------------------------------------------------------------------

# File Structure

Each JSON file contains a list of test cases.

``` json
{
  "cases": [
    { ... test case ... },
    { ... test case ... }
  ]
}
```

Each entry in `"cases"` is a single hyperelliptic curve test case.

------------------------------------------------------------------------

# Test Case Structure

Each test case must have the following fields:

``` json
{
  "id": "...",
  "field": {...},
  "curve": {...},
  "expected": {...},
  "notes": "..."
}
```

------------------------------------------------------------------------

# 1. Case Identifier

    "id": "string"

A unique identifier for the test case.

Recommended naming convention:

    g{genus}_p{p}_a{a}_{index}

Example:

    g2_p7_a1_001

------------------------------------------------------------------------

# 2. Finite Field Definition

    "field": {
      "p": integer,
      "a": integer,
      "modulus_coeffs_asc": [...]
    }

This defines the field

F_q where q = p\^a.

### Prime Field

If `a = 1`, the base field is F_p and `modulus_coeffs_asc` should be
omitted.

Example:

``` json
"field": {
  "p": 7,
  "a": 1
}
```

------------------------------------------------------------------------

### Extension Field

If `a > 1`, the field is defined as

F_q = F_p\[t\] / (m(t))

    modulus_coeffs_asc = [c0, c1, ..., ca]

represents

m(t) = c0 + c1 t + ... + ca t\^a.

Example:

``` json
"field": {
  "p": 5,
  "a": 2,
  "modulus_coeffs_asc": [2,0,1]
}
```

which represents F_25 = F_5\[t\]/(t\^2 + 2).

------------------------------------------------------------------------

# 3. Curve Definition

Curves are stored in the hyperelliptic form

y\^2 + h(x) y = f(x)

This works in all characteristics.

    "curve": {
      "genus": integer,
      "model": {
        "pretty": "...",
        "x_var": "x",
        "y_var": "y",
        "t_var": "t",
        "h_coeffs_asc": [...],
        "f_coeffs_asc": [...]
      }
    }

------------------------------------------------------------------------

## Human-readable equation

`pretty` is a string representation of the equation.

Example:

    "pretty": "y^2 = x^5 + 2*x^3 + 1"

This field is **for humans only**.

The machine-readable representation uses coefficient arrays.

------------------------------------------------------------------------

# Polynomial Representation

## h(x)

    h_coeffs_asc = [h0, h1, ..., hn]

represents

h(x) = h0 + h1 x + ... + hn x\^n

------------------------------------------------------------------------

## f(x)

    f_coeffs_asc = [f0, f1, ..., fm]

represents

f(x) = f0 + f1 x + ... + fm x\^m

------------------------------------------------------------------------

# Field Element Encoding

Two encodings are used depending on the base field.

## Case 1: Prime Field (`a = 1`)

Coefficients are integers interpreted modulo `p`.

Example:

``` json
"f_coeffs_asc": [1,0,2,0,0,1]
```

represents

1 + 2x\^2 + x\^5 over F_p.

------------------------------------------------------------------------

## Case 2: Extension Field (`a > 1`)

Coefficients are arrays representing elements of

F_p\[t\]/(m(t)).

    [c0, c1, ..., c_{a-1}]

represents

c0 + c1 t + ... + c\_{a-1} t\^{a-1}.

Example:

``` json
[2,1]
```

represents

2 + t.

------------------------------------------------------------------------

# Normalization Rules

The format **does not enforce normalization**.

Allowed:

-   trailing zeros in polynomial coefficient arrays
-   trailing zeros in field element arrays

Programs reading the file may normalize internally.

------------------------------------------------------------------------

# 4. Expected Zeta Function

Each case stores the **L-polynomial** P(T) where

Z(C,T) = P(T) / ((1-T)(1-qT)).

    "expected": {
      "Lpoly": {
        "coeffs_asc": [...]
      }
    }

Example:

``` json
"expected": {
  "Lpoly": {
    "coeffs_asc": [1,3,10,21,49]
  }
}
```

This represents

P(T) = 1 + 3T + 10T\^2 + 21T\^3 + 49T\^4.

Constraints:

-   length = 2g + 1
-   coeffs_asc\[0\] = 1
-   coefficients are integers

------------------------------------------------------------------------

# 5. Metadata

    "notes": "string"

Free-form field describing:

-   provenance
-   references
-   generation method
-   remarks

Example:

    "notes": "Generated using Sage; genus 2 random curve over F7"

------------------------------------------------------------------------

# Guidelines for Humans and AI Systems

When generating new test cases:

Always verify:

-   `p` is prime
-   `modulus_coeffs_asc` defines an irreducible polynomial if `a > 1`
-   the equation defines a hyperelliptic curve
-   the genus field is correct
-   the L-polynomial matches the curve

Recommended workflow:

1.  Choose `p`, `a`, and genus.
2.  Generate a hyperelliptic curve.
3.  Compute the zeta function.
4.  Extract the L-polynomial.
5.  Store coefficients in ascending order.

------------------------------------------------------------------------

# Example Test Case

``` json
{
  "id": "g2_p7_a1_001",
  "field": {
    "p": 7,
    "a": 1
  },
  "curve": {
    "genus": 2,
    "model": {
      "pretty": "y^2 = x^5 + x^2 + 1",
      "x_var": "x",
      "y_var": "y",
      "t_var": "t",
      "h_coeffs_asc": [0],
      "f_coeffs_asc": [1,0,1,0,0,1]
    }
  },
  "expected": {
    "Lpoly": {
      "coeffs_asc": [1,3,10,21,49]
    }
  },
  "notes": "Example curve over F7"
}
```
