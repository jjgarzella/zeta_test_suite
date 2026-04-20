# hyperell_suite

A test suite designed for writing and debugging algorithms which compute the
zeta function (sometimes called L-polynomial) of a smooth projective variety
over a finite field.

It includes a JSON format and a library of already-generated test cases,
together with Sage helpers for reading and writing them. We hope to support
MAGMA and Oscar in the future.

The format is described in `schema.json` / `spec.txt` / `FORMAT.md`. Each case
stores one shared variety together with multiple prime/L-polynomial results.
Test cases live under `cases/`.

The format generalizes beyond hyperelliptic curves: a case now describes a
variety of any dimension, with the model encoded as a tagged union over six
day-one kinds (hyperelliptic, superelliptic, plane curve, projective
hypersurface, double cover of P^2, cyclic cover). Each file declares its
schema version with a top-level `"schema_version": "3"` field.

This repository was entirely coded by AI, with human guidance.
