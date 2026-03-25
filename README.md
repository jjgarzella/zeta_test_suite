# hyperell_suite

This is a test suite designed for writing and debugging algorithms which compute the zeta function (sometimes called L-polynomial) of a hyperelliptic curve.

It includes a JSON format and a library of already-generated test cases, together with Sage helpers for reading and writing them. We hope to support MAGMA and Oscar in the future.

The format is described in `schema_v2.json` / `specv2.txt` / `FORMAT.md`. Each case stores one shared curve together with multiple prime/L-polynomial results. Test cases live under `cases_v2/`.

This repository was entirely coded by AI, with human guidance.
