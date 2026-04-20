"""
migrate_v2_to_v3.sage — One-shot migration of cases_v2/*.json to cases/*.json.

Transformations per case:
  - rename `curve` -> `variety`
  - add `variety.dim = 1`
  - add `variety.non_middle_factors = {kind: projective_lefschetz,
                                       middle_factor_content: full}`
  - add `variety.model.kind = "hyperelliptic"`
  - drop `variety.model.x_var`, `y_var`, `t_var`

Per file:
  - add top-level `schema_version = "3"`

Usage (from repo root):
    sage scripts/migrate_v2_to_v3.sage

This script is intentionally throwaway: it will be deleted in the same
commit that removes the rest of the v2 artifacts.
"""

import json
import os


SRC_DIR = 'cases_v2'
DST_DIR = 'cases'

DEFAULT_NON_MIDDLE_FACTORS = {
    'kind': 'projective_lefschetz',
    'middle_factor_content': 'full',
}


def migrate_model(v2_model):
    """Drop x_var/y_var/t_var, add kind:'hyperelliptic'."""
    out = {'kind': 'hyperelliptic', 'pretty': v2_model['pretty']}
    out['h_coeffs_asc'] = v2_model['h_coeffs_asc']
    out['f_coeffs_asc'] = v2_model['f_coeffs_asc']
    return out


def migrate_curve(v2_curve):
    """v2 curve dict -> v3 variety dict."""
    return {
        'coeff_domain': v2_curve['coeff_domain'],
        'dim': 1,
        'genus': v2_curve['genus'],
        'non_middle_factors': dict(DEFAULT_NON_MIDDLE_FACTORS),
        'model': migrate_model(v2_curve['model']),
    }


def migrate_case(v2_case):
    return {
        'id': v2_case['id'],
        'variety': migrate_curve(v2_case['curve']),
        'results': v2_case['results'],
        'notes': v2_case['notes'],
    }


def _to_json_native(obj):
    """Coerce Sage scalars (from the preparser) into Python ints/strings."""
    if isinstance(obj, dict):
        return {k: _to_json_native(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_to_json_native(x) for x in obj]
    if isinstance(obj, (str, bool)):
        return obj
    try:
        return int(obj)
    except (TypeError, ValueError):
        return obj


def migrate_file(src_path, dst_path):
    with open(src_path, 'r') as fh:
        v2 = json.load(fh)
    v3 = {
        'schema_version': '3',
        'cases': [migrate_case(c) for c in v2['cases']],
    }
    with open(dst_path, 'w') as fh:
        json.dump(_to_json_native(v3), fh, indent=2)
        fh.write('\n')


def main():
    if not os.path.isdir(SRC_DIR):
        raise SystemExit(f"source directory {SRC_DIR!r} not found")
    os.makedirs(DST_DIR, exist_ok=True)

    src_files = sorted(
        f for f in os.listdir(SRC_DIR)
        if f.endswith('.json') and not f.startswith('.')
    )
    if not src_files:
        raise SystemExit(f"no .json files found in {SRC_DIR!r}")

    for name in src_files:
        src = os.path.join(SRC_DIR, name)
        dst = os.path.join(DST_DIR, name)
        migrate_file(src, dst)
        print(f"migrated {src} -> {dst}")

    print(f"\nMigrated {len(src_files)} file(s).")


main()
