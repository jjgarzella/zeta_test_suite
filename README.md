# hyperell_suite

This is a test suite designed for writing and debugging algorithms which compute the zeta function (sometimes called L-polynomial) of a hyperelliptic curve.

It includes versioned JSON formats and a library of already-generated test cases, together with Sage helpers for reading and writing them. We hope to support MAGMA and Oscar in the future.

## Format Versions

- `schema_v1.json` / `specv1.txt` / `FORMAT_v1.md`: legacy format, where each case stores one curve over one finite field together with one L-polynomial.
- `schema_v2.json` / `specv2.txt` / `FORMAT.md`: grouped format, where each case stores one shared curve together with multiple prime/L-polynomial results.

The files under `cases_v1/` are still the legacy v1 library. New grouped work should target `cases_v2/`.

This repository was entirely coded by AI, with human guidance.
