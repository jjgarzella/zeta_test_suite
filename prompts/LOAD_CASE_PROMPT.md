# Prompt for Implementing `load_case` in a CAS (V3)

Implement a function called `load_case` in the chosen computer algebra system.
The purpose of this function is to read **one grouped variety test case** from
the v3 JSON format and return the shared case data without expanding it into
per-prime objects.

The v3 format generalizes v2 beyond hyperelliptic curves: a case now describes
a smooth projective **variety** of any dimension, with results stored either as
the middle-cohomology factor (shorthand) or as a full per-degree `l_factors`
dictionary.

## Goal

Given one parsed JSON object `case`, implement:

```text
load_case(case) -> (id, variety, results, notes)
```

If your language supports named tuples or records, prefer returning a named
object.

## Input format

The input `case` has this shape:

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
    {
      "p": 5,
      "Lpoly": { "coeffs_asc": [1, 5, 15, 25, 25] }
    }
  ],
  "notes": "Example grouped case"
}
```

The enclosing file always carries a top-level `"schema_version": "3"` field.
`load_case` operates on one element of the file's `"cases"` array; the file
loader (`load_cases`) is responsible for verifying `schema_version`.

## Required behavior

1. Read the case identifier.
2. Read the shared `variety` object unchanged.
3. Read the `results` array unchanged.
4. Read the `notes` string.
5. Return those values in one grouped object.

`load_case` should NOT:

- recompute the zeta function
- expand the grouped case into one object per prime (that is `expand_case`'s
  job, defined as a separate helper)
- expand the `Lpoly` shorthand into a full `l_factors` dict (also part of the
  per-prime expansion path)

## Variety dispatch

The `variety.model` field is a tagged union — `model.kind` selects which
remaining fields apply. v3 ships with six recognized kinds:

| `kind`                    | Description                                  |
| ------------------------- | -------------------------------------------- |
| `hyperelliptic`           | `y^2 + h(x) y = f(x)`; uses `h_coeffs_asc`, `f_coeffs_asc` |
| `superelliptic`           | `y^m = f(x)`; uses `m`, `f_coeffs_asc`       |
| `plane_curve`             | homogeneous `F(x,y,z) = 0` in `P^2`          |
| `projective_hypersurface` | homogeneous `F(x_0,...,x_n) = 0` in `P^n`    |
| `double_cover_P2`         | double cover of `P^2` along a branch curve   |
| `cyclic_cover`            | `m`-fold cyclic cover of `P^n` along a branch divisor |

Multivariable kinds (everything except hyperelliptic and superelliptic) use a
parallel-array polynomial encoding: `vars` (or `branch_vars` / `base_vars`),
`monomials` (each entry an exponent vector parallel to `coeffs`/`branch_coeffs`).

`load_case` itself does not need to dispatch on `model.kind` — it simply hands
the variety dict back. Per-kind dispatch happens in the per-prime construction
helpers.

## Non-middle factors convention

`variety.non_middle_factors` declares how the loader (when expanding) should
populate L-factors at cohomological degrees other than the middle:

- `{"kind": "projective_lefschetz", "middle_factor_content": "full" | "primitive"}`
- `{"kind": "toric_lefschetz", "middle_factor_content": "full" | "primitive"}`
- `{"kind": "explicit"}` — every L-factor must be supplied explicitly

`load_case` does not interpret this; it just preserves the field.

## Important notes

- Numeric values may be encoded either as JSON integers or as integer-valued
  strings. Both forms appear in the same file when L-polynomial coefficients
  exceed roughly `2^63`.
- The only implemented `coeff_domain.kind` in v3 is `"integer"`. The schema
  reserves `"number_field"` for future work; loaders should raise a clean
  not-implemented error if they encounter it.
- The recognized `non_middle_factors.kind` set is fixed in v3. Loaders should
  raise a clean not-implemented error for `"toric_lefschetz"` until a future
  version adds the required cohomological machinery.
