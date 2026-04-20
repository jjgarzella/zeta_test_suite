# Prompt: Implement `load_cases` (V3)

Implement a function called `load_cases` in your chosen CAS/language.

This function loads **multiple grouped variety test cases from a v3 JSON file**
and returns the grouped objects produced by the v3 `load_case` function.

## Input

The JSON file has the structure:

```json
{
  "schema_version": "3",
  "cases": [
    { ... grouped test case ... },
    { ... grouped test case ... }
  ]
}
```

Each element of `"cases"` is compatible with:

```text
load_case(case)
```

which returns one grouped case object containing:

```text
(id, variety, results, notes)
```

## Required behavior

1. Read the JSON file.
2. Verify the top-level `"schema_version"` is `"3"`. If absent or different,
   raise a clean error.
3. Extract the `"cases"` array.
4. Iterate through the cases.
5. For each case, call `load_case`.
6. Store the grouped results in a list or equivalent container.
7. Return the list.

## Function signature

Use something like:

```text
load_cases(path)
```

where `path` is the JSON file path.

## Important rules

- Verify the `schema_version` before doing any work; refuse to load files that
  do not advertise themselves as v3.
- Do not recompute anything.
- Do not expand grouped cases into one object per prime inside `load_cases`.
- Do not expand `Lpoly` shorthand into `l_factors` inside `load_cases`.
- Keep the implementation simple and idiomatic for the chosen language.

If your language has both a "load grouped" and a "load expanded" workflow,
mirror that with two separate entry points (e.g. `load_cases` and
`load_expanded_cases`). The reference Sage implementation provides both.
