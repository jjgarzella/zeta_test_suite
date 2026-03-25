# Prompt: Implement `load_cases` (V2)

Implement a function called `load_cases` in your chosen CAS/language.

This function should load **multiple grouped hyperelliptic test cases from a
v2 JSON file** and return the grouped objects produced by the v2 `load_case`
 function.

## Input

The JSON file has the structure:

```json
{
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
(id, curve, results, notes)
```

## Required behavior

1. Read the JSON file.
2. Extract the `"cases"` array.
3. Iterate through the cases.
4. For each case, call `load_case`.
5. Store the grouped results in a list or equivalent container.
6. Return the list.

## Function signature

Use something like:

```text
load_cases(path)
```

where `path` is the JSON file path.

## Important rules

- Do not recompute anything.
- Do not expand grouped cases into one object per prime inside `load_cases`.
- Keep the implementation simple and idiomatic for the chosen language.
