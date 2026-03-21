# CLAUDE.md

This file provides context about the repository for new Claude Code sessions.

## Repository Overview

**hyperell_suite** is a test suite for zeta functions / L-polynomials of hyperelliptic curves. It provides a standardized, machine-readable JSON format for test cases that verify implementations of algorithms computing zeta functions of hyperelliptic curves over finite fields.

### Key files and directories

- `specv1.txt` — Compact spec of the test case format
- `FORMAT.md` — Detailed guide for generating valid test cases (read this to understand the format)
- `schema_v1.json` — JSON Schema (draft 2020-12) for validating case files
- `cases/` — JSON files containing test cases
- `sage/loader.sage` — `load_case(case)` / `load_cases(path)`: deserialize JSON → Sage `HyperellipticCurve` objects
- `sage/saver.sage` — `save_case(curve, result, filename, id, notes)`: serialize Sage curves → JSON test cases
- `prompts/` — Prompts for getting LLMs to implement loaders/savers in other CAS systems
- `test/` — Unit tests for random curve generation

### Test case format summary

Each test case is a JSON object with:
- `id` — unique string identifier (convention: `g{genus}_p{p}_a{a}_{index}`)
- `field` — finite field F_q: `p` (prime), `a` (extension degree), optional `modulus_coeffs_asc`
- `curve` — hyperelliptic curve y² + h(x)y = f(x), stored as ascending coefficient arrays
- `expected` — L-polynomial P(T) where Z(C,T) = P(T) / ((1-T)(1-qT)), as `coeffs_asc`
- `notes` — free-form provenance/metadata string

Extension field elements are encoded as integer arrays `[c0, c1, ..., c_{a-1}]` representing c0 + c1·t + ··· in F_p[t]/(m(t)).

---

## Git workflow

- Do not commit new features directly to `main`.
- For each new feature, create a new branch, do the work there, and only merge/push to `main` when the user approves.
