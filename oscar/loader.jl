"""
loader.jl — Load v3 zeta-function test cases from JSON using Oscar.

Mirrors sage/loader.sage for the three model kinds that Oscar currently
exercises: plane_curve, projective_hypersurface, double_cover_P2. Other
kinds raise ErrorException; so does coeff_domain `number_field` and
non_middle_factors `toric_lefschetz`.

Public API:
    load_case(case::AbstractDict) -> GroupedCase
    expand_case(case::AbstractDict) -> Vector{ExpandedCase}
    load_cases(path::AbstractString) -> Vector{GroupedCase}
    load_expanded_cases(path::AbstractString) -> Vector{ExpandedCase}
"""

using Oscar
using JSON

const SCHEMA_VERSION = "3"

struct LoadedVariety
    kind::String
    dim::Int
    genus::Union{Int,Nothing}
    coeff_domain::AbstractDict
    non_middle_factors::AbstractDict
    model_data::AbstractDict
    polys::Dict{String,Any}
    oscar_object::Any
end

struct GroupedCase
    id::String
    variety::AbstractDict
    results::AbstractVector
    notes::String
end

struct ExpandedCase
    id::String
    p::ZZRingElem
    notes::String
    variety::LoadedVariety
    expected_l_factors::Dict{Int,Vector{ZZRingElem}}
end

# ----------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------

function load_case(case::AbstractDict)
    GroupedCase(
        case["id"],
        case["variety"],
        case["results"],
        case["notes"],
    )
end

function expand_case(case::AbstractDict)
    grouped = load_case(case)
    out = ExpandedCase[]
    for result in grouped.results
        p = _to_zz(result["p"])
        variety = _build_variety_over_prime(grouped.variety, p)
        l_factors = _result_to_l_factors(grouped.variety, result, p)
        push!(out, ExpandedCase(grouped.id, p, grouped.notes, variety, l_factors))
    end
    return out
end

function load_cases(path::AbstractString)
    data = _read_v3_json(path)
    return [load_case(c) for c in data["cases"]]
end

function load_expanded_cases(path::AbstractString)
    data = _read_v3_json(path)
    out = ExpandedCase[]
    for case in data["cases"]
        append!(out, expand_case(case))
    end
    return out
end

# ----------------------------------------------------------------------
# JSON / scalar helpers
# ----------------------------------------------------------------------

function _read_v3_json(path::AbstractString)
    data = open(JSON.parse, path)
    version = get(data, "schema_version", nothing)
    if version != SCHEMA_VERSION
        error("Expected schema_version $(repr(SCHEMA_VERSION)), got $(repr(version))")
    end
    return data
end

_to_zz(v::Integer) = ZZ(v)
_to_zz(v::AbstractString) = ZZ(v)
_to_zz(v::ZZRingElem) = v

_coeffs_to_zz_list(coeffs) = [_to_zz(c) for c in coeffs]

# ----------------------------------------------------------------------
# Domain / convention dispatch
# ----------------------------------------------------------------------

function _require_supported_coeff_domain(variety::AbstractDict)
    kind = variety["coeff_domain"]["kind"]
    if kind == "integer"
        return
    elseif kind == "number_field"
        error("v3 loader does not yet support coeff_domain.kind == 'number_field'")
    else
        error("Unknown coeff_domain.kind: $(repr(kind))")
    end
end

function _require_supported_non_middle_factors(variety::AbstractDict)
    kind = variety["non_middle_factors"]["kind"]
    if kind == "toric_lefschetz"
        error("v3 loader does not yet support non_middle_factors.kind == 'toric_lefschetz'")
    elseif !(kind in ("projective_lefschetz", "explicit"))
        error("Unknown non_middle_factors.kind: $(repr(kind))")
    end
end

# ----------------------------------------------------------------------
# Polynomial construction
# ----------------------------------------------------------------------

function _multivariable_poly(monomials_list, coeffs_list, R)
    gens_R = gens(R)
    nv = length(gens_R)
    out = zero(R)
    for (mono, c) in zip(monomials_list, coeffs_list)
        if length(mono) != nv
            error("monomial length $(length(mono)) does not match number of vars $nv")
        end
        term = R(_to_zz(c))
        for (j, e) in enumerate(mono)
            term *= gens_R[j]^Int(e)
        end
        out += term
    end
    return out
end

# ----------------------------------------------------------------------
# Per-kind variety construction over GF(p)
# ----------------------------------------------------------------------

function _build_variety_over_prime(variety::AbstractDict, p::ZZRingElem)
    _require_supported_coeff_domain(variety)
    _require_supported_non_middle_factors(variety)

    F = GF(Int(p))
    model = variety["model"]
    kind = model["kind"]
    polys = Dict{String,Any}()
    oscar_object = nothing

    if kind == "plane_curve"
        vars_ = [Symbol(v) for v in model["vars"]]
        R, _ = polynomial_ring(F, vars_)
        polys["F"] = _multivariable_poly(model["monomials"], model["coeffs"], R)

    elseif kind == "projective_hypersurface"
        vars_ = [Symbol(v) for v in model["vars"]]
        R, _ = polynomial_ring(F, vars_)
        polys["F"] = _multivariable_poly(model["monomials"], model["coeffs"], R)

    elseif kind == "double_cover_P2"
        vars_ = [Symbol(v) for v in model["branch_vars"]]
        R, _ = polynomial_ring(F, vars_)
        polys["branch"] = _multivariable_poly(model["branch_monomials"],
                                              model["branch_coeffs"], R)
        polys["m"] = 2

    elseif kind in ("hyperelliptic", "superelliptic", "cyclic_cover")
        error("oscar loader does not implement model.kind == $(repr(kind)); " *
              "supported kinds are plane_curve, projective_hypersurface, double_cover_P2")
    else
        error("Unknown model.kind: $(repr(kind))")
    end

    return LoadedVariety(
        kind,
        Int(variety["dim"]),
        haskey(variety, "genus") ? Int(variety["genus"]) : nothing,
        variety["coeff_domain"],
        variety["non_middle_factors"],
        model,
        polys,
        oscar_object,
    )
end

# ----------------------------------------------------------------------
# Shorthand → l_factors expansion
# ----------------------------------------------------------------------

function _lefschetz_factor_at_degree(i::Int, p::ZZRingElem)
    if i < 0
        error("degree out of range: $i")
    end
    if isodd(i)
        return [ZZ(1)]
    end
    return [ZZ(1), -p^(i ÷ 2)]
end

function _poly_mul_int_lists(a::Vector{ZZRingElem}, b::Vector{ZZRingElem})
    out = [ZZ(0) for _ in 1:(length(a) + length(b) - 1)]
    for (i, ai) in enumerate(a), (j, bj) in enumerate(b)
        out[i + j - 1] += ai * bj
    end
    return out
end

function _result_to_l_factors(variety::AbstractDict, result::AbstractDict, p::ZZRingElem)
    dim = Int(variety["dim"])
    nmf = variety["non_middle_factors"]
    nmf_kind = nmf["kind"]

    has_lfac = haskey(result, "l_factors")
    has_lpoly = haskey(result, "Lpoly")
    if has_lfac && has_lpoly
        error("Result has both 'l_factors' and 'Lpoly'; pick one")
    end

    if has_lfac
        out = Dict{Int,Vector{ZZRingElem}}(
            parse(Int, string(k)) => _coeffs_to_zz_list(v["coeffs_asc"])
            for (k, v) in result["l_factors"]
        )
        if nmf_kind == "explicit"
            expected = Set(0:(2 * dim))
            actual = Set(keys(out))
            missing_keys = setdiff(expected, actual)
            extra_keys = setdiff(actual, expected)
            if !isempty(missing_keys) || !isempty(extra_keys)
                error("Explicit l_factors must have keys 0..$(2 * dim); " *
                      "missing=$(sort(collect(missing_keys))), " *
                      "extra=$(sort(collect(extra_keys)))")
            end
        end
        return out
    end

    if !has_lpoly
        error("Result must have either 'l_factors' or 'Lpoly'")
    end

    if nmf_kind == "explicit"
        error("Lpoly shorthand is forbidden when non_middle_factors.kind == 'explicit'")
    end
    if nmf_kind != "projective_lefschetz"
        error("Shorthand expansion not implemented for non_middle_factors.kind == $(repr(nmf_kind))")
    end

    middle_factor_content = nmf["middle_factor_content"]
    middle_coeffs = _coeffs_to_zz_list(result["Lpoly"]["coeffs_asc"])

    out = Dict{Int,Vector{ZZRingElem}}()
    for i in 0:(2 * dim)
        if i == dim
            if middle_factor_content == "full"
                out[i] = copy(middle_coeffs)
            elseif middle_factor_content == "primitive"
                lefschetz = _lefschetz_factor_at_degree(dim, p)
                out[i] = _poly_mul_int_lists(lefschetz, middle_coeffs)
            else
                error("Unknown middle_factor_content: $(repr(middle_factor_content))")
            end
        else
            out[i] = _lefschetz_factor_at_degree(i, p)
        end
    end
    return out
end
