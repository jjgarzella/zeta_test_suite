# AGENTS.md

This file provides context about the repository for new Claude Code sessions.
`CLAUDE.md` is a symlink to this file.

## Repository Overview

**zeta_test_suite** is a test suite for zeta functions / L-polynomials of
smooth projective varieties over finite fields. It provides a standardized,
machine-readable JSON format for test cases that verify implementations of
algorithms computing zeta functions of varieties (curves, surfaces, and
beyond).

### Key files and directories

- `schema.json` / `spec.txt` / `FORMAT.md` — v3 schema, compact reference, and authoring guide
- `cases/` — Grouped v3 JSON case files, organized by variety kind in subfolders (e.g. `cases/hyperelliptic/`)
- `sage/loader.sage` — v3 Sage loader (tagged-union dispatch over six model kinds)
- `sage/saver.sage` — v3 Sage saver (per-kind serializers, upsert by id)
- `oscar/loader.jl` / `oscar/saver.jl` — Julia/Oscar port (plane_curve, projective_hypersurface, double_cover_P2)
- `magma/loader.magma` / `magma/saver.magma` — MAGMA port (plane_curve, projective_hypersurface); `magma/json.magma` is an embedded JSON parser
- `prompts/` — CAS-agnostic prompts for getting LLMs to implement loaders/savers in yet another CAS
- `test/` — Unit tests for random curve generation and the loader/saver implementations
- `scripts/` — Generators for producing test cases at scale

### Test case format summary

- each test case is one shared variety plus a `results` array
- the variety declares `dim`, an optional `genus`, a `coeff_domain` tag
  (`integer` implemented; `number_field` reserved), a `non_middle_factors`
  convention (`projective_lefschetz` / `toric_lefschetz` with
  `middle_factor_content` `full`|`primitive`, or `explicit`), and a tagged-union
  `model` (six kinds: hyperelliptic, superelliptic, plane_curve,
  projective_hypersurface, double_cover_P2, cyclic_cover)
- each result stores a prime `p` and either an `Lpoly` shorthand (the
  middle-cohomology factor only) or a full `l_factors` dict keyed by
  cohomological degree
- each file carries a top-level `"schema_version": "3"` field

---

## Git workflow

- Do not commit new features directly to `main`.
- For each new feature, create a new branch, do the work there, and only merge/push to `main` when the user approves.
