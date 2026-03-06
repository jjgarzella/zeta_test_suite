# Prompt for Implementing `load_case` in a CAS

Implement a function called `load_case` in the chosen computer algebra system. The purpose of this function is to read **one hyperelliptic curve test case** from the JSON test-suite format and return a tuple, preferably a named tuple if the language supports it.

## Goal

Given one parsed JSON object `case`, implement:

```text
load_case(case) -> (curve, expected_Lpoly)
```

Optionally, if convenient, return extra fields too, such as `id` or `notes`, but the required outputs are:

* `curve`: the native hyperelliptic curve object in the CAS
* `expected_Lpoly`: the expected L-polynomial coefficients in ascending order

If your language supports named tuples or similar, prefer something like:

```text
(curve = ..., expected_Lpoly = ...)
```

## Input format

The input `case` is one JSON object with this shape:

```json
{
  "id": "g2_p7_a1_001",
  "field": {
    "p": 7,
    "a": 1,
    "modulus_coeffs_asc": [ ... ]
  },
  "curve": {
    "genus": 2,
    "model": {
      "pretty": "y^2 = x^5 + x^2 + 1",
      "x_var": "x",
      "y_var": "y",
      "t_var": "t",
      "h_coeffs_asc": [0],
      "f_coeffs_asc": [1, 0, 1, 0, 0, 1]
    }
  },
  "expected": {
    "Lpoly": {
      "coeffs_asc": [1, 3, 10, 21, 49]
    }
  },
  "notes": "Example case"
}
```

## Mathematical meaning

The curve is given in the form

[
y^2 + h(x)y = f(x)
]

over the finite field ( \mathbf F_q ), where ( q = p^a ).

### Field encoding

* `p` is the characteristic
* `a` is the extension degree
* if `a = 1`, the field is ( \mathbf F_p )
* if `a > 1`, the field is

[
\mathbf F_q \cong \mathbf F_p[t]/(m(t))
]

where `modulus_coeffs_asc = [c0, ..., ca]` means

[
m(t) = c_0 + c_1 t + \cdots + c_a t^a
]

### Polynomial encoding

* `h_coeffs_asc = [h0, ..., hn]` means

[
h(x) = h_0 + h_1 x + \cdots + h_n x^n
]

* `f_coeffs_asc = [f0, ..., fm]` means

[
f(x) = f_0 + f_1 x + \cdots + f_m x^m
]

### Coefficient encoding

If `a = 1`, coefficients are integers, interpreted modulo `p`.

If `a > 1`, each coefficient is an array:

```json
[c0, c1, ..., c_{a-1}]
```

representing the field element

[
c_0 + c_1 t + \cdots + c_{a-1} t^{a-1}.
]

Trailing zeros may appear and should be accepted.

## Required behavior

Your implementation should do the following:

### 1. Read the field data

Extract:

* `p`
* `a`
* optionally `modulus_coeffs_asc`

### 2. Construct the finite field

* if `a == 1`, construct ( \mathbf F_p )
* if `a > 1`, construct ( \mathbf F_p[t]/(m(t)) ) using the modulus polynomial from `modulus_coeffs_asc`

Use the variable name `t` if your CAS allows naming the generator.

### 3. Decode coefficients

Implement helper logic to convert a JSON coefficient into a field element.

* if `a == 1`, an integer `n` becomes the element `n mod p`
* if `a > 1`, an array `[c0, ..., c_{a-1}]` becomes the field element
  [
  c_0 + c_1 t + \cdots + c_{a-1} t^{a-1}
  ]

### 4. Build the polynomials

Construct the polynomial ring in `x` over the finite field, then build:

* `h(x)` from `h_coeffs_asc`
* `f(x)` from `f_coeffs_asc`

using ascending coefficient order.

### 5. Construct the hyperelliptic curve

Construct the native hyperelliptic curve corresponding to

[
y^2 + h(x)y = f(x).
]

Use the most natural hyperelliptic-curve constructor in your CAS.

### 6. Extract the expected L-polynomial

Return

```text
expected_Lpoly = case["expected"]["Lpoly"]["coeffs_asc"]
```

as a list/vector of integers, unchanged.

### 7. Return the result

Return either:

```text
(curve, expected_Lpoly)
```

or, preferably, a named tuple like:

```text
(curve = curve, expected_Lpoly = expected_Lpoly)
```

## Error handling

Handle these cases cleanly:

* missing required keys
* `a > 1` but no modulus polynomial present
* malformed coefficient arrays
* unsupported field or curve construction in the chosen CAS

It is fine to raise an error with a clear message.

## Suggested helper functions

Structure the code using small helpers, for example:

* `make_field(field_data)`
* `decode_field_element(c, F, a, t)`
* `poly_from_coeffs(coeffs, R)`
* `load_case(case)`

## Output expectations

Produce code that is:

* idiomatic for your CAS/language
* directly usable
* commented
* robust to trailing zeros
* explicit about ascending coefficient order

## Important: DO NOT SKIP

Do not recompute the zeta function.

Do not validate that the genus is correct.

Do not use the `pretty` string for parsing unless absolutely necessary.

Treat the machine-readable coefficient arrays as the source of truth.

## Example behavior

For input with

```json
"h_coeffs_asc": [0],
"f_coeffs_asc": [1,0,1,0,0,1],
"expected": {
  "Lpoly": {
    "coeffs_asc": [1,3,10,21,49]
  }
}
```

the function should return:

* the hyperelliptic curve defined by
  [
  y^2 = 1 + x^2 + x^5
  ]
  over ( \mathbf F_7 )
* the expected L-polynomial coefficients

  ```text
  [1, 3, 10, 21, 49]
  ```

## Final instruction to the LLM

Write the full implementation of `load_case` in the chosen CAS, including any helper functions needed. Include a short usage example showing how to call it on one parsed JSON object.


