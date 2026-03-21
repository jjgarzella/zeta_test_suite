# Hyperelliptic Zeta Test Case Format Guide (V2)

This document explains how to generate valid **v2** hyperelliptic curve
test cases for the zeta-function test suite.

The v2 format groups many prime/L-polynomial pairs under one shared curve.

Legacy one-field-per-case files are still described by `FORMAT_v1.md`,
`specv1.txt`, and `schema_v1.json`.

------------------------------------------------------------------------

# File Structure

Each JSON file contains a list of grouped test cases.

```json
{
  "cases": [
    { ... grouped test case ... },
    { ... grouped test case ... }
  ]
}
```

Each entry in `"cases"` is one shared curve together with one or more
prime/L-polynomial results.

------------------------------------------------------------------------

# Test Case Structure

Each grouped case has the following fields:

```json
{
  "id": "...",
  "curve": {...},
  "results": [...],
  "notes": "..."
}
```

------------------------------------------------------------------------

# 1. Case Identifier

```text
"id": "string"
```

A unique identifier for the shared curve.

Recommended naming convention:

```text
g{genus}_d{degree}_{label}
```

Example:

```text
g2_d5_a
```

------------------------------------------------------------------------

# 2. Shared Curve Definition

Curves are stored in the hyperelliptic form

```text
y^2 + h(x) y = f(x)
```

The v2 format stores one shared curve and then records its reductions
at different primes in the `"results"` array.

```json
"curve": {
  "coeff_domain": {
    "kind": "integer"
  },
  "genus": 2,
  "model": {
    "pretty": "y^2 = x^5 - x + 1",
    "x_var": "x",
    "y_var": "y",
    "t_var": "t",
    "h_coeffs_asc": [0],
    "f_coeffs_asc": [1, -1, 0, 0, 0, 1]
  }
}
```

## Coefficient Domain

The shared curve must declare how its coefficients should be interpreted
before reduction.

```json
"coeff_domain": {
  "kind": "integer"
}
```

Implemented in v2:

- `integer` — coefficients are integers and should be reduced modulo each
  result prime `p`

Reserved for future work:

- `number_field` — schema placeholder only in this version

## Human-readable Equation

`pretty` is a string representation of the equation.

Example:

```text
"pretty": "y^2 = x^5 - x + 1"
```

This field is for humans only. Programs should use the coefficient arrays.

## Polynomial Representation

```text
h_coeffs_asc = [h0, h1, ..., hn]
f_coeffs_asc = [f0, f1, ..., fm]
```

These represent

```text
h(x) = h0 + h1 x + ... + hn x^n
f(x) = f0 + f1 x + ... + fm x^m
```

For `integer` coefficient domains, entries may be written either as JSON
integers or as integer-valued strings.

Preferred encoding:

- use JSON integers for values whose magnitude is below `2^64`
- use integer-valued strings for larger magnitudes when BigInt-safe
  interchange matters

------------------------------------------------------------------------

# 3. Prime Results

Each grouped case stores one or more prime/L-polynomial pairs:

```json
"results": [
  {
    "p": 5,
    "Lpoly": {
      "coeffs_asc": [1, 5, 15, 25, 25]
    }
  },
  {
    "p": 7,
    "Lpoly": {
      "coeffs_asc": [1, "-1", 0, "-7", 49]
    }
  }
]
```

Each result describes the reduction of the shared curve modulo the prime `p`.

## Prime Field

```text
"p": integer encoded as either a JSON integer or an integer-valued string
```

This is the prime over which the shared curve is reduced before computing
the zeta function.

In v2, results are intentionally limited to prime reductions.

## Expected Zeta Function

Each result stores the L-polynomial `P(T)` where

```text
Z(C, T) = P(T) / ((1 - T)(1 - pT)).
```

```json
"Lpoly": {
  "coeffs_asc": [...]
}
```

Constraints:

- length = `2g + 1`
- `coeffs_asc[0] = 1` or `"1"`
- coefficients are integers or integer-valued strings
- values whose magnitude is below `2^64` should normally be encoded as
  JSON integers

------------------------------------------------------------------------

# 4. Metadata

```text
"notes": "string"
```

Free-form case-level metadata describing provenance, references,
generation method, or remarks about the shared curve.

In v2 there is no per-result metadata field.

------------------------------------------------------------------------

# Normalization Rules

The format does not enforce normalization.

Allowed:

- trailing zeros in polynomial coefficient arrays
- repeated primes in `"results"` are discouraged, but schema validation
  does not forbid them

Programs reading the file may normalize internally.

------------------------------------------------------------------------

# Guidelines for Humans and AI Systems

When generating new v2 test cases:

- choose one shared curve first
- encode that curve over its declared coefficient domain
- choose one or more primes `p`
- reduce the shared curve modulo each `p`
- compute the corresponding L-polynomial
- store each prime/L-polynomial pair in `"results"`

Always verify:

- the shared curve data is correct
- the coefficient domain tag matches the coefficient encoding
- each `p` is prime
- each reduction defines a valid hyperelliptic curve
- the stored genus matches the curve
- each L-polynomial matches its reduction

------------------------------------------------------------------------

# Example Grouped Case

```json
{
  "id": "g2_d5_a",
  "curve": {
    "coeff_domain": {
      "kind": "integer"
    },
    "genus": 2,
    "model": {
      "pretty": "y^2 = x^5 - x + 1",
      "x_var": "x",
      "y_var": "y",
      "t_var": "t",
      "h_coeffs_asc": [0],
      "f_coeffs_asc": [1, "-1", 0, 0, 0, "1"]
    }
  },
  "results": [
    {
      "p": 5,
      "Lpoly": {
        "coeffs_asc": [1, 5, 15, 25, 25]
      }
    },
    {
      "p": 7,
      "Lpoly": {
        "coeffs_asc": [1, "-1", 0, "-7", 49]
      }
    }
  ],
  "notes": "Example shared integer curve with two prime reductions"
}
```
