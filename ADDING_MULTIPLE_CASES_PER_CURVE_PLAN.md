# Add Grouped Multi-Prime Cases as Schema V2

## Summary

Add a new **v2** wire format that keeps the top-level `"cases"` array, but changes each case from “one curve + one field + one L-polynomial” into “one shared curve + many prime/L-polynomial results”.

Use these defaults:

- `schema_v1.json` and `specv1.txt` stay intact as legacy.
- New work lands in `schema_v2.json` and `specv2.txt`.
- Each v2 case has one shared `id`, one shared `curve`, one shared `notes`, and a `results` array.
- Each `results` entry stores only `p` and `Lpoly`.
- The shared curve gets an explicit coefficient-domain tag.
- Implement only the `integer` curve-domain now; include a `number_field` schema branch as a placeholder, but have Sage v2 loaders reject it with a clear “not implemented yet” error.
- Actual conversion of files in `cases/` is out of scope for this task.

A concrete v2 case shape should be:

```json
{
  "cases": [
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
          "p": 7,
          "Lpoly": {
            "coeffs_asc": [1, 3, 10, 21, 49]
          }
        }
      ],
      "notes": "..."
    }
  ]
}
```

## Key Changes

- Add `schema_v2.json` and `specv2.txt`.
  - `schema_v2.json` defines the grouped case shape above.
  - `curve.coeff_domain.kind` is a tagged union with `integer` implemented and `number_field` reserved.
  - `results[*]` requires `p` and `Lpoly.coeffs_asc`, with no per-result metadata.
  - `schema_v1.json` and `specv1.txt` stay unchanged.

- Update repository docs to describe both versions and make v2 the forward path.
  - `README.md` should explain that v1 is legacy and v2 is the grouped format for new work.
  - `AGENTS.md` should list both versions and note that grouped multi-prime cases are v2.
  - `FORMAT.md` should become the v2 guide, with a short note pointing legacy readers to v1.
  - Add `FORMAT_v1.md` as a copy/archive of the current detailed v1 guide so v1 documentation is not lost.

- Add parallel Sage v2 loaders/savers instead of rewriting the v1 ones in place.
  - Keep `sage/loader.sage` and `sage/saver.sage` as v1.
  - Add `sage/loader_v2.sage` with:
    - `load_case(case)` returning a grouped case object with `id`, shared curve data, raw results, and `notes`
    - `expand_case(case)` returning one loaded per-prime case per `results` entry
    - `load_cases(path)` returning grouped cases
    - `load_expanded_cases(path)` returning the flattened expanded list
  - Add `sage/saver_v2.sage` with:
    - `save_case(curve, result, filename, id, notes="")` writing one v2 grouped case with a singleton `results` array; for a Sage curve over `GF(p)`, lift coefficients canonically to integers in `[0, p-1]` and set `coeff_domain.kind = "integer"`
    - `save_grouped_case(case_dict, filename)` upserting a complete grouped case by `id`

- Update generator scripts to target v2 output.
  - `scripts/generate_cases.sage`, `scripts/generate_large_prime_cases.sage`, `scripts/generate_p41_odd_degree.sage`, and `scripts/generate_p41_even_degree.sage` should import `saver_v2.sage` and keep emitting one grouped case per generated curve, with a singleton `results` array.
  - `scripts/generate_specific_cases.sage` is the major rewrite: one case id per shared integer curve, aggregate all valid primes into one `results` array, then write once via `save_grouped_case`. Its ids should become curve-level ids such as `g2_d5_a`, not per-prime ids.

- Add parallel v2 prompt files rather than overwriting the v1 prompts.
  - Keep the current prompt files as v1 references.
  - Add `prompts/LOAD_CASE_V2_PROMPT.md`, `prompts/LOAD_CASES_V2_PROMPT.md`, and `prompts/SAVE_CASE_V2_PROMPT.md`.
  - The v2 load prompts should describe grouped loading plus expansion helpers.
  - The v2 save prompt should describe singleton grouped writes and full grouped-case writes.

- Add v2-focused tests and keep the random-curve generator tests as-is.
  - `random_generation/random_curves.sage`, `test/test_random_curves.sage`, and `test/test_random_curves_char2.sage` do not need logic changes.
  - Add a new Sage test file for v2 loader/saver behavior and register it in `test/runtests.sage`.
  - Add small v2 fixture JSON files under `test/fixtures/` to exercise grouped cases without migrating `cases/`.

- Update CI only enough to cover v2 fixtures while leaving legacy case validation alone.
  - `.github/workflows/ci.yml` should continue validating `cases/*.json` against `schema_v1.json` until the migration task.
  - Add one new validation step for the new v2 fixture files against `schema_v2.json`.
  - Keep the Sage test runner step; it will pick up the new v2 tests through `test/runtests.sage`.

## Test Plan

- Validate one integer-domain grouped v2 fixture with multiple `results` entries against `schema_v2.json`.
- Validate one singleton v2 fixture produced by the v2 saver path against `schema_v2.json`.
- Confirm `loader_v2.load_case` returns grouped case data without expanding.
- Confirm `loader_v2.expand_case` reduces the shared integer curve modulo each `p` and returns the expected number of per-prime loaded cases.
- Confirm `saver_v2.save_case` writes a valid singleton grouped case from a Sage curve over `GF(p)`.
- Confirm `saver_v2.save_grouped_case` preserves one case per curve id and replaces, not duplicates, an existing grouped case with the same id.
- Confirm the existing random-curve tests still pass unchanged.

## Assumptions

- V2 intentionally narrows grouped results to **prime reductions only**; extension-field-per-result support stays in legacy v1 for now.
- `number_field` is a schema placeholder only in this task; v2 Sage loaders/savers reject it explicitly.
- No conversion of the real files in `cases/` happens in this task.
- Existing v1 loaders/savers/prompts remain available during the transition; v2 is added in parallel rather than replacing them immediately.
