# Prompt for Implementing `load_case` in a CAS (V2)

Implement a function called `load_case` in the chosen computer algebra system.
The purpose of this function is to read **one grouped hyperelliptic curve test
case** from the v2 JSON format and return the shared case data without expanding
it into per-prime curve objects.

## Goal

Given one parsed JSON object `case`, implement:

```text
load_case(case) -> (id, curve, results, notes)
```

If your language supports named tuples or records, prefer returning a named
object.

## Input format

The input `case` has this shape:

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
      "f_coeffs_asc": [1, -1, 0, 0, 0, 1]
    }
  },
  "results": [
    {
      "p": 5,
      "Lpoly": {
        "coeffs_asc": [1, 5, 15, 25, 25]
      }
    }
  ],
  "notes": "Example grouped case"
}
```

## Required behavior

1. Read the case identifier.
2. Read the shared curve object unchanged.
3. Read the `results` array unchanged.
4. Read the `notes` string.
5. Return those values in one grouped object.

## Important notes

- Do not recompute the zeta function.
- Do not expand the grouped case into one object per prime inside `load_case`.
- The v2 shape allows numeric values to be encoded either as JSON integers or as
  integer-valued strings.
- The only implemented coefficient domain in v2 is `integer`.
- `number_field` may appear in the schema as a reserved option, but it is not
  implemented yet.
