# CLAUDE.md

This file provides context about the repository for new Claude Code sessions.

## Repository Overview

**hyperell_suite** is a test suite for zeta functions / L-polynomials of hyperelliptic curves. It provides a standardized, machine-readable JSON format for test cases that verify implementations of algorithms computing zeta functions of hyperelliptic curves over finite fields.

### Key files and directories

- `specv2.txt` / `schema_v2.json` / `FORMAT.md` — Grouped format with one shared curve and many prime/L-polynomial results
- `cases_v2/` — Grouped v2 JSON case files
- `sage/loader_v2.sage` — v2 loader helpers
- `sage/saver_v2.sage` — v2 saver helpers
- `prompts/` — Prompts for getting LLMs to implement loaders/savers in other CAS systems
- `test/` — Unit tests for random curve generation

### Test case format summary

- each test case is one shared curve plus a `results` array
- each result stores a prime `p` and an expected L-polynomial
- the shared curve declares a coefficient-domain tag, with `integer` implemented and `number_field` reserved

---

## Git workflow

- Do not commit new features directly to `main`.
- For each new feature, create a new branch, do the work there, and only merge/push to `main` when the user approves.
