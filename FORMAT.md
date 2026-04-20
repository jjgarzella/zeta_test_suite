# Zeta Test Case Format Guide (v3)

This document explains how to author valid v3 test cases for the
zeta-function test suite. v3 generalizes the format beyond hyperelliptic
curves: a test case now describes a smooth projective **variety** of any
dimension, with results stored either as the middle-cohomology factor
(shorthand) or as a full per-degree `l_factors` dictionary.

The companion files `schema.json` and `spec.txt` are the normative
machine-readable definitions; this guide is for human authors.

------------------------------------------------------------------------

# File Structure

Each JSON file contains a top-level `schema_version` plus a list of
grouped test cases.

```json
{
  "schema_version": "3",
  "cases": [
    { ... grouped test case ... },
    { ... grouped test case ... }
  ]
}
```

`"schema_version": "3"` is required and must equal the literal string
`"3"`. Each entry in `"cases"` is one shared variety together with one
or more prime results.

------------------------------------------------------------------------

# Test Case Structure

Each grouped case has the following fields:

```json
{
  "id": "...",
  "variety": {...},
  "results": [...],
  "notes": "..."
}
```

------------------------------------------------------------------------

# 1. Case Identifier

```text
"id": "string"
```

A unique identifier for the shared variety.

Recommended naming conventions:

- curves: `g{genus}_d{degree}_{label}` (e.g. `g2_d5_a`)
- surfaces: `{family}_{degree}_{label}` (e.g. `quartic_K3_a`)
- general: any short slug that uniquely identifies the case

------------------------------------------------------------------------

# 2. The Variety

The `variety` block declares everything about the shared variety
that does not depend on a specific prime reduction.

```json
"variety": {
  "coeff_domain": { "kind": "integer" },
  "dim": 1,
  "genus": 2,
  "non_middle_factors": {
    "kind": "projective_lefschetz",
    "middle_factor_content": "full"
  },
  "model": { ... }
}
```

## Coefficient Domain

```json
"coeff_domain": { "kind": "integer" }
```

Implemented in v3:

- `integer` — coefficients are integers and are reduced modulo each
  result prime `p`

Reserved (recognized by the schema but loaders raise not-implemented):

- `number_field` — coefficients live in a number field; reduction
  modulo primes of that field is left to a future version

## Dimension and Genus

- `dim` (required) — the dimension of the variety (0 for points,
  1 for curves, 2 for surfaces, …).
- `genus` (optional) — the genus of a curve. Authors should set this
  whenever it is well-defined. Loaders may use it as a sanity check
  against the L-polynomial degree.

## Non-Middle Factors Convention

The `non_middle_factors` block declares how the loader should populate
the L-factors at cohomological degrees other than the middle (`H^d`
for a `d`-dimensional variety).

Three kinds are recognized:

- `projective_lefschetz` — the variety satisfies the projective
  Lefschetz hyperplane theorem, so non-middle cohomology comes from a
  surrounding projective space and the L-factors are determined.
- `toric_lefschetz` — the toric analogue (recognized by the schema;
  loaders may raise not-implemented in v3).
- `explicit` — no convention; every L-factor must be supplied
  explicitly (see Section 3 below).

When the kind is `projective_lefschetz` or `toric_lefschetz`, the
`middle_factor_content` field must also be set:

- `full` — the supplied middle factor is the entire `H^d` characteristic
  polynomial.
- `primitive` — the supplied middle factor is just the primitive
  cohomology piece, and the loader will multiply in the inherited
  Lefschetz contribution to recover the full `H^d`.

When the kind is `explicit`, `middle_factor_content` must be omitted.

## Model

The `model` is a tagged union: the `kind` field selects which set of
remaining fields applies. v3 ships with six day-one kinds — see
Section 4 for the per-kind schemas.

------------------------------------------------------------------------

# 3. Prime Results

Each grouped case stores one or more prime results:

```json
"results": [
  { "p": 5, "Lpoly": { "coeffs_asc": [1, 5, 15, 25, 25] } },
  { "p": 7, "l_factors": {
      "0": { "coeffs_asc": [1, -1] },
      "1": { "coeffs_asc": [1] },
      "2": { "coeffs_asc": [1, 0, 0, 0, 49] }
  }}
]
```

There are two result forms.

## Shorthand: `Lpoly`

```json
{ "p": 7, "Lpoly": { "coeffs_asc": [1, 3, 10, 21, 49] } }
```

Shorthand stores only the middle-cohomology factor `P_d(T)`. The loader
expands shorthand into a full `l_factors` dict using the variety's
declared `non_middle_factors` convention.

Shorthand is **only valid** when `variety.non_middle_factors.kind` is
not `"explicit"`. The schema enforces this with an `if/then/else` rule.

For curves (`dim = 1`), `P_1(T)` is the L-polynomial — its degree is
`2g` and `P_1(0) = 1`.

## Explicit: `l_factors`

```json
{ "p": 7, "l_factors": {
    "0": { "coeffs_asc": [1, -1] },
    "1": { "coeffs_asc": [1] },
    "2": { "coeffs_asc": [1, 0, 0, 0, 49] }
}}
```

The keys are decimal-string cohomological degrees (`"0"`, `"1"`, …).
When `non_middle_factors.kind == "explicit"`, every key from `"0"` to
`"2*dim"` (inclusive) must be present. The runtime loader enforces this;
the JSON Schema cannot, because `dim` is dynamic.

The full zeta function is reconstructed as

```text
Z(X/F_p, T) = ∏_{i=0}^{2 dim} P_i(T) ^ ((-1)^(i+1)).
```

## The Prime Field

```text
"p": <integer or integer-string>
```

`p` is the prime over which the shared variety is reduced before
computing the zeta function. v3 still restricts to prime reductions; a
future minor version may add `prime_power_q` results.

------------------------------------------------------------------------

# 4. Per-Kind Model Schemas

Below: the required fields for each `model.kind`, plus a complete
example case.

## 4.1 hyperelliptic

Form: `y^2 + h(x) y = f(x)`. Always `dim = 1`.

Fields:

- `kind`: `"hyperelliptic"`
- `pretty`: human-readable equation
- `h_coeffs_asc`: ascending-degree integer coefficients of `h(x)`
- `f_coeffs_asc`: ascending-degree integer coefficients of `f(x)`

Example:

```json
{
  "id": "g2_d5_a",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 1,
    "genus": 2,
    "non_middle_factors": {
      "kind": "projective_lefschetz",
      "middle_factor_content": "full"
    },
    "model": {
      "kind": "hyperelliptic",
      "pretty": "y^2 = x^5 - x + 1",
      "h_coeffs_asc": [0],
      "f_coeffs_asc": [1, -1, 0, 0, 0, 1]
    }
  },
  "results": [
    { "p": 5, "Lpoly": { "coeffs_asc": [1, 5, 15, 25, 25] } },
    { "p": 7, "Lpoly": { "coeffs_asc": [1, "-1", 0, "-7", 49] } }
  ],
  "notes": "Genus-2 hyperelliptic curve with two prime reductions."
}
```

## 4.2 superelliptic

Form: `y^m = f(x)` with `m ≥ 2`. Always `dim = 1`.

Fields:

- `kind`: `"superelliptic"`
- `pretty`
- `m`: cyclic exponent (integer ≥ 2)
- `f_coeffs_asc`

Example:

```json
{
  "id": "trielliptic_d4_a",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 1,
    "genus": 3,
    "non_middle_factors": {
      "kind": "projective_lefschetz",
      "middle_factor_content": "full"
    },
    "model": {
      "kind": "superelliptic",
      "pretty": "y^3 = x^4 + 1",
      "m": 3,
      "f_coeffs_asc": [1, 0, 0, 0, 1]
    }
  },
  "results": [
    { "p": 7, "Lpoly": { "coeffs_asc": [1, 0, 0, 0, 0, 0, 343] } }
  ],
  "notes": "Trielliptic curve example."
}
```

## 4.3 plane_curve

Form: a homogeneous polynomial `F(x, y, z) = 0` in `P^2`. Always
`dim = 1`.

Fields:

- `kind`: `"plane_curve"`
- `pretty`
- `vars`: exactly three variable names
- `monomials`, `coeffs`: parallel arrays describing `F`

Example (Fermat cubic):

```json
{
  "id": "fermat_cubic",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 1,
    "genus": 1,
    "non_middle_factors": {
      "kind": "projective_lefschetz",
      "middle_factor_content": "full"
    },
    "model": {
      "kind": "plane_curve",
      "pretty": "x^3 + y^3 + z^3 = 0",
      "vars": ["x", "y", "z"],
      "monomials": [[3, 0, 0], [0, 3, 0], [0, 0, 3]],
      "coeffs": [1, 1, 1]
    }
  },
  "results": [
    { "p": 7, "Lpoly": { "coeffs_asc": [1, -4, 7] } }
  ],
  "notes": "Fermat cubic in P^2."
}
```

## 4.4 projective_hypersurface

Form: a homogeneous polynomial `F(x_0, …, x_n) = 0` in `P^n`. The
variety has `dim = n - 1`.

Fields:

- `kind`: `"projective_hypersurface"`
- `pretty`
- `vars`: array of `≥ 2` variable names
- `monomials`, `coeffs`: parallel arrays

Example (Fermat quartic surface, full `l_factors`):

```json
{
  "id": "fermat_quartic_K3",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 2,
    "non_middle_factors": { "kind": "explicit" },
    "model": {
      "kind": "projective_hypersurface",
      "pretty": "x^4 + y^4 + z^4 + w^4 = 0",
      "vars": ["x", "y", "z", "w"],
      "monomials": [[4,0,0,0],[0,4,0,0],[0,0,4,0],[0,0,0,4]],
      "coeffs": [1, 1, 1, 1]
    }
  },
  "results": [
    { "p": 7, "l_factors": {
        "0": { "coeffs_asc": [1, -1] },
        "1": { "coeffs_asc": [1] },
        "2": { "coeffs_asc": [1, 0, 0, 0, 1] },
        "3": { "coeffs_asc": [1] },
        "4": { "coeffs_asc": [1, -49] }
    }}
  ],
  "notes": "Fermat quartic K3 surface with full per-degree L-factors."
}
```

## 4.5 double_cover_P2

Form: a double cover of `P^2` branched over the curve `b(x_0, x_1, x_2) = 0`,
where `b` is a homogeneous form of even degree. Always `dim = 2`.

Fields:

- `kind`: `"double_cover_P2"`
- `pretty`
- `branch_vars`: exactly three variable names (variables of `P^2`)
- `branch_monomials`, `branch_coeffs`: parallel arrays describing the
  branch curve `b`

Example:

```json
{
  "id": "double_cover_branch_sextic",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 2,
    "non_middle_factors": {
      "kind": "projective_lefschetz",
      "middle_factor_content": "primitive"
    },
    "model": {
      "kind": "double_cover_P2",
      "pretty": "y^2 = x_0^6 + x_1^6 + x_2^6",
      "branch_vars": ["x_0", "x_1", "x_2"],
      "branch_monomials": [[6,0,0],[0,6,0],[0,0,6]],
      "branch_coeffs": [1, 1, 1]
    }
  },
  "results": [],
  "notes": "Double cover of P^2 branched along a Fermat sextic."
}
```

## 4.6 cyclic_cover

Form: an `m`-fold cyclic cover of `P^{n}` (where `n = len(base_vars) - 1`)
branched along `b(base_vars) = 0`.

Fields:

- `kind`: `"cyclic_cover"`
- `pretty`
- `m`: cyclic exponent (integer ≥ 2)
- `base_vars`: variables of the base projective space (`≥ 2` entries)
- `branch_monomials`, `branch_coeffs`: parallel arrays describing the
  branch divisor

Example:

```json
{
  "id": "cyclic_3_branch_cubic_p2",
  "variety": {
    "coeff_domain": { "kind": "integer" },
    "dim": 2,
    "non_middle_factors": {
      "kind": "projective_lefschetz",
      "middle_factor_content": "primitive"
    },
    "model": {
      "kind": "cyclic_cover",
      "pretty": "w^3 = x^3 + y^3 + z^3",
      "m": 3,
      "base_vars": ["x", "y", "z"],
      "branch_monomials": [[3,0,0],[0,3,0],[0,0,3]],
      "branch_coeffs": [1, 1, 1]
    }
  },
  "results": [],
  "notes": "Triple cover of P^2 branched along a Fermat cubic."
}
```

------------------------------------------------------------------------

# 5. Polynomial Encoding

## Univariate (hyperelliptic, superelliptic)

Coefficient arrays are positional, ascending degree:

```text
h_coeffs_asc = [h0, h1, ..., hn]
f_coeffs_asc = [f0, f1, ..., fm]
```

represent

```text
h(x) = h0 + h1 x + ... + hn x^n
f(x) = f0 + f1 x + ... + fm x^m
```

## Multivariable (parallel arrays)

For multivariable polynomials, the variety stores `vars`, `monomials`,
and `coeffs` arrays. `monomials[i]` is an exponent vector parallel to
`coeffs[i]`. Together they describe

```text
F(vars) = sum_i  coeffs[i] * prod_j  vars[j] ^ monomials[i][j]
```

Conventions:

- each `monomials[i]` has length `len(vars)`
- entries with a zero coefficient should be omitted, not zero-padded
- monomials are not required to be sorted

## Integer Encoding

For `integer` coefficient domains, scalar values may be written as
either JSON integers or integer-valued strings.

Preferred:

- JSON integers when `|value| < 2^64`
- integer-valued strings for larger magnitudes (BigInt-safe interchange)

------------------------------------------------------------------------

# 6. Metadata

```text
"notes": "string"
```

Free-form case-level metadata: provenance, references, generation
method, remarks about the shared variety. Required (use `""` if you
have nothing to say).

There is no per-result metadata field in v3.

------------------------------------------------------------------------

# 7. Normalization Rules

The format does not enforce normalization.

Allowed:

- trailing zeros in univariate coefficient arrays
- monomials in any order in multivariable encodings
- repeated primes in `"results"` are discouraged but not forbidden

Programs reading the file may normalize internally.

------------------------------------------------------------------------

# 8. Guidelines for Humans and AI Systems

When generating new v3 test cases:

1. choose one shared variety first
2. encode it over its declared `coeff_domain`
3. set `dim` (and `genus` if applicable)
4. choose a `non_middle_factors` convention; prefer
   `projective_lefschetz` with shorthand whenever applicable
5. choose one or more primes `p`
6. reduce the variety modulo each `p`
7. compute the L-polynomial(s) and store them either as `Lpoly`
   shorthand or as a full `l_factors` dict
8. validate the file against `schema.json`

Always verify:

- the variety data is correct (homogeneity, degree, smoothness as
  appropriate)
- the coefficient domain tag matches the encoding
- each `p` is prime
- the reduction modulo `p` defines a valid object of the declared kind
- a stored `genus` matches the curve
- each L-polynomial matches its reduction
- in shorthand mode, the `non_middle_factors` convention applies

------------------------------------------------------------------------

# 9. Example: Two Reductions of One Hyperelliptic Curve

```json
{
  "schema_version": "3",
  "cases": [
    {
      "id": "g2_d5_a",
      "variety": {
        "coeff_domain": { "kind": "integer" },
        "dim": 1,
        "genus": 2,
        "non_middle_factors": {
          "kind": "projective_lefschetz",
          "middle_factor_content": "full"
        },
        "model": {
          "kind": "hyperelliptic",
          "pretty": "y^2 = x^5 - x + 1",
          "h_coeffs_asc": [0],
          "f_coeffs_asc": [1, "-1", 0, 0, 0, "1"]
        }
      },
      "results": [
        { "p": 5, "Lpoly": { "coeffs_asc": [1, 5, 15, 25, 25] } },
        { "p": 7, "Lpoly": { "coeffs_asc": [1, "-1", 0, "-7", 49] } }
      ],
      "notes": "Example shared integer curve with two prime reductions."
    }
  ]
}
```
