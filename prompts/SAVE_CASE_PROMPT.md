# Prompt: Implement `save_case` (V3)

Implement v3 save helpers in your chosen CAS/language.

The v3 format stores one shared **variety** together with a `results` array of
prime/L-polynomial pairs. Each file declares its format with a top-level
`"schema_version": "3"` field.

## Reference implementations

Three working ports live in the repo — `sage/saver.sage` (Sage, all six model
kinds), `oscar/saver.jl` (Julia/Oscar, three kinds), and `magma/saver.magma`
(MAGMA, two kinds). Adapt the closest one rather than starting from scratch.

## Goal

Implement helpers equivalent to:

```text
save_case(variety, result, filename; id, notes="", p=None)
save_grouped_case(case, filename)
```

## Required behavior for `save_case`

`save_case` should:

1. Accept one variety description and one result.
   - The variety may be a native object specific to the language
     (e.g. a Sage `HyperellipticCurve` or an Oscar polynomial; see the
     reference implementations) or a plain dictionary already in v3
     `variety` shape — the implementer's choice.
   - The result may be either an iterable of integer-like coefficients
     (interpreted as the Lpoly shorthand) or a dictionary keyed by
     cohomological degree (interpreted as explicit `l_factors`).
2. Build a grouped v3 case with:
   - one shared `id`
   - one shared `variety`
   - a singleton `results` array
   - one shared `notes` string
3. Write or upsert that grouped case into the JSON file using
   `save_grouped_case`.

If `save_case` accepts a dictionary variety, the prime `p` cannot always be
inferred — accept it as an explicit keyword argument in that case.

## Required behavior for `save_grouped_case`

`save_grouped_case` should:

1. Accept a fully formed grouped case object.
2. Validate that the filename ends in `.json`.
3. Create the file if it does not exist, with a top-level
   `"schema_version": "3"` field plus a `"cases"` array seeded with the new
   case.
4. If the file exists:
   - read it,
   - refuse to write if the existing `"schema_version"` is not `"3"`,
   - replace any existing case with the same `id`,
   - otherwise append the case to the `"cases"` array.
5. Write valid pretty-printed JSON.

## Variety dispatch

If `save_case` accepts a native variety object, it should dispatch on the
object's type to build the correct `model.kind` block. v3 ships with six
recognized kinds:

| `kind`                    | Required model fields                              |
| ------------------------- | -------------------------------------------------- |
| `hyperelliptic`           | `pretty`, `h_coeffs_asc`, `f_coeffs_asc`           |
| `superelliptic`           | `pretty`, `m`, `f_coeffs_asc`                      |
| `plane_curve`             | `pretty`, `vars`, `monomials`, `coeffs`            |
| `projective_hypersurface` | `pretty`, `vars`, `monomials`, `coeffs`            |
| `double_cover_P2`         | `pretty`, `branch_vars`, `branch_monomials`, `branch_coeffs` |
| `cyclic_cover`            | `pretty`, `m`, `base_vars`, `branch_monomials`, `branch_coeffs` |

Multivariable kinds use a parallel-array polynomial encoding: `monomials[i]`
is an exponent vector of the same length as `vars`, parallel to `coeffs[i]`.
Entries with zero coefficient should be omitted.

The variety also requires a `non_middle_factors` block. A reasonable default
for varieties known to satisfy projective Lefschetz with a fully-stored middle
factor is:

```json
{ "kind": "projective_lefschetz", "middle_factor_content": "full" }
```

Implementers are free to expose this as a keyword argument with that default.

## Result encoding

Two result forms exist:

- **Shorthand**: `{ "p": ..., "Lpoly": { "coeffs_asc": [...] } }` — the
  middle-cohomology factor only. Forbidden when
  `variety.non_middle_factors.kind == "explicit"`.
- **Explicit**: `{ "p": ..., "l_factors": { "0": {...}, ..., "2*dim": {...} } }`
  — every cohomological degree present.

Numeric values may be encoded either as JSON integers or as integer-valued
strings.

Preferred behavior:

- write JSON integers for values with magnitude below `2^63`
- write strings for larger magnitudes

This rule applies to:

- shared variety coefficient arrays
- each result prime `p`
- each polynomial in `Lpoly.coeffs_asc` and `l_factors[*].coeffs_asc`

## Important notes

- The implemented v3 coefficient domain is `integer`.
- `number_field` is reserved in the schema but does not need to be implemented.
- Do not recompute the zeta function or expand shorthand into explicit
  `l_factors` when saving — that's a load-time concern.
- Preserve the top-level `"schema_version": "3"` and `"cases"` array structure.
