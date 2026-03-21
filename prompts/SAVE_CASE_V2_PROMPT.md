# Prompt: Implement `save_case` (V2)

Implement v2 save helpers in your chosen CAS/language.

The v2 format stores one shared curve together with a `results` array of
prime/L-polynomial pairs.

## Goal

Implement helpers equivalent to:

```text
save_case(curve, result, filename; id, notes="")
save_grouped_case(case, filename)
```

## Required behavior for `save_case`

`save_case` should:

1. Accept one native hyperelliptic curve object and one expected
   L-polynomial.
2. Build a grouped v2 case with:
   - one shared `id`
   - one shared `curve`
   - a singleton `results` array
   - one shared `notes` string
3. Write or upsert that grouped case into the JSON file.

## Required behavior for `save_grouped_case`

`save_grouped_case` should:

1. Accept a fully formed grouped case object.
2. Validate that the filename ends in `.json`.
3. Create the file if it does not exist.
4. If the file exists, replace any existing grouped case with the same `id`.
5. Otherwise append the grouped case.
6. Write valid pretty-printed JSON.

## Numeric encoding

The v2 format allows integer-valued data to be encoded as either:

- JSON integers
- integer-valued strings

Preferred behavior:

- write JSON integers for values with magnitude below `2^63`
- write strings for larger magnitudes

This rule applies to:

- shared curve coefficient arrays
- each result prime `p`
- each `Lpoly.coeffs_asc` entry

## Important notes

- The implemented v2 coefficient domain is `integer`.
- `number_field` is reserved in the schema but does not need to be implemented.
- Do not recompute the zeta function.
- Preserve the top-level `"cases"` array structure.
