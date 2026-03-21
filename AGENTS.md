# CLAUDE.md

This file provides context about the repository for new Claude Code sessions.

## Repository Overview

**hyperell_suite** is a test suite for zeta functions / L-polynomials of hyperelliptic curves. It provides a standardized, machine-readable JSON format for test cases that verify implementations of algorithms computing zeta functions of hyperelliptic curves over finite fields.

### Key files and directories

- `specv1.txt` / `schema_v1.json` / `FORMAT_v1.md` — Legacy one-field-per-case format
- `specv2.txt` / `schema_v2.json` / `FORMAT.md` — Grouped format with one shared curve and many prime/L-polynomial results
- `cases_v1/` — Legacy v1 JSON case files
- `cases_v2/` — Grouped v2 JSON case files
- `sage/loader.sage` — v1 loader helpers for legacy case files
- `sage/saver.sage` — v1 saver helpers for legacy case files
- `prompts/` — Prompts for getting LLMs to implement loaders/savers in other CAS systems
- `test/` — Unit tests for random curve generation

### Test case format summary

V1:
- each test case is one `(field, curve, expected)` tuple
- fields may be prime or extension fields

V2:
- each test case is one shared curve plus a `results` array
- each result stores a prime `p` and an expected L-polynomial
- the shared curve declares a coefficient-domain tag, with `integer` implemented and `number_field` reserved

---

## Git workflow

- Do not commit new features directly to `main`.
- For each new feature, create a new branch, do the work there, and only merge/push to `main` when the user approves.
