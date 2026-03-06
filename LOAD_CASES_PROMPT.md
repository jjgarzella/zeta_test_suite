# Prompt: Implement `load_cases`

Implement a function called `load_cases` in your chosen CAS/language.

This function should load **multiple hyperelliptic test cases from a JSON file** and convert them into native curve objects using the previously implemented `load_case` function.

## Input

The JSON file has the structure:

```json
{
  "cases": [
    { ... test case ... },
    { ... test case ... }
  ]
}
```

Each element of `"cases"` is a test case compatible with the function:

```text
load_case(case)
```

which returns:

```text
(curve, expected_Lpoly)
```

or a named tuple with the same information.

## Required behavior

1. Read the JSON file.
2. Extract the `"cases"` array.
3. Iterate through the cases.
4. For each case, call `load_case`.
5. Store the results in a list (or equivalent container in your language).
6. Return the list.

## Function signature

Use something like:

```text
load_cases(path)
```

where `path` is the JSON file path.

## Expected result

The function should return a list (or vector) of the objects returned by `load_case`.

Example conceptual behavior:

```text
cases = load_cases("cases.json")

for c in cases:
    computed = my_algorithm(c.curve)
    assert computed == c.expected_Lpoly
```

## Important rules

* Do not recompute anything.
* Do not modify `load_case`.
* Simply call `load_case` in a loop.
* Keep the implementation simple and idiomatic for the chosen language.

## Example structure

Conceptually the implementation should look like:

```text
read JSON
cases = json["cases"]

results = []

for case in cases:
    results.append(load_case(case))

return results
```

Write clean, idiomatic code for your CAS/language.

